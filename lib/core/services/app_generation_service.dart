import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:visual_app_builder_shared/visual_app_builder_shared.dart' as shared;
import '../models/app_spec.dart';
import 'openai_service.dart';
import 'service_locator.dart';

/// App Generation Service
///
/// Generates complete Flutter apps from natural language prompts using AI.
/// Parses prompts into AppSpec, generates code, and creates project files.
///
/// This service is web-compatible - it uses the ServiceLocator to get platform-aware
/// services for file operations and terminal commands.
class AppGenerationService {
  static final AppGenerationService _instance = AppGenerationService._internal();
  static AppGenerationService get instance => _instance;
  AppGenerationService._internal();

  final OpenAIService _openai = OpenAIService.instance;

  // Get services from ServiceLocator for platform-aware operations
  shared.ITerminalService get _terminal => ServiceLocator.instance.terminalService;
  shared.IProjectManagerService get _projectManager => ServiceLocator.instance.projectManager;
  shared.IConfigService get _config => ServiceLocator.instance.configService;

  /// Check if the service is configured
  bool get isConfigured => _openai.isConfigured;

  /// Generate an app from a natural language prompt
  ///
  /// Returns a stream of GenerationProgress events
  Stream<GenerationProgress> generateAppFromPrompt({
    required String prompt,
    required String projectName,
    required String outputPath,
    String? organization,
  }) async* {
    debugPrint('');
    debugPrint('╔══════════════════════════════════════════════════════════════╗');
    debugPrint('║           APP GENERATION SERVICE STARTED                     ║');
    debugPrint('╚══════════════════════════════════════════════════════════════╝');
    debugPrint('Prompt: $prompt');
    debugPrint('Project Name: $projectName');
    debugPrint('Output Path: $outputPath');
    debugPrint('Organization: $organization');
    debugPrint('');

    if (!_openai.isConfigured) {
      debugPrint('❌ ERROR: OpenAI not configured');
      yield const GenerationProgress(
        phase: GenerationPhase.error,
        progress: 0,
        message: 'OpenAI is not configured. Please set your API key.',
        error: 'API key not configured',
      );
      return;
    }

    debugPrint('✓ OpenAI is configured');
    final projectPath = _joinPath(outputPath, projectName);
    debugPrint('Target project path: $projectPath');

    // Phase 1: Parse prompt into AppSpec
    debugPrint('');
    debugPrint('📝 PHASE 1: Parsing prompt into AppSpec...');
    yield const GenerationProgress(
      phase: GenerationPhase.parsing,
      progress: 0.05,
      message: 'Analyzing your app description...',
    );

    AppSpec? appSpec;
    try {
      debugPrint('   Calling _parsePromptToSpec...');
      appSpec = await _parsePromptToSpec(prompt, projectName);
      debugPrint('   ✓ AppSpec parsed successfully!');
      debugPrint('   - App name: ${appSpec.name}');
      debugPrint('   - Screens: ${appSpec.screens.length}');
      debugPrint('   - Models: ${appSpec.models.length}');
      for (final screen in appSpec.screens) {
        debugPrint('     Screen: ${screen.name} (${screen.route})');
      }
      for (final model in appSpec.models) {
        debugPrint('     Model: ${model.name} (${model.fields.length} fields)');
      }
      yield GenerationProgress(
        phase: GenerationPhase.parsing,
        progress: 0.15,
        message: 'Found ${appSpec.screens.length} screens and ${appSpec.models.length} models',
      );
    } catch (e, stackTrace) {
      debugPrint('   ❌ ERROR parsing prompt: $e');
      debugPrint('   Stack trace: $stackTrace');
      yield GenerationProgress(
        phase: GenerationPhase.error,
        progress: 0.15,
        message: 'Failed to analyze prompt',
        error: e.toString(),
      );
      return;
    }

    // Phase 2: Create base Flutter project
    debugPrint('');
    debugPrint('🏗️ PHASE 2: Creating Flutter project...');
    yield const GenerationProgress(
      phase: GenerationPhase.planning,
      progress: 0.20,
      message: 'Creating Flutter project...',
    );

    final org = organization ?? await _config.getOrganization() ?? 'com.example';
    debugPrint('   Organization: $org');
    debugPrint('   Running: flutter create $projectName');
    debugPrint('   Working directory: $outputPath');

    // Use the terminal service from ServiceLocator (works on both web and desktop)
    await for (final output in _terminal.createProject(
      name: projectName,
      outputPath: outputPath,
      organization: org,
    )) {
      debugPrint('   Terminal: ${output.trim()}');
      // Stream terminal output as messages
      yield GenerationProgress(
        phase: GenerationPhase.planning,
        progress: 0.25,
        message: output.trim(),
      );
    }

    // Check project created by trying to list files
    debugPrint('   Checking if project directory exists at: $projectPath');
    bool projectExists = false;
    try {
      // Try to read the pubspec.yaml to verify project was created
      final pubspecPath = _joinPath(projectPath, 'pubspec.yaml');
      final content = await _projectManager.readFile(pubspecPath);
      projectExists = content != null && content.isNotEmpty;
    } catch (e) {
      projectExists = false;
    }
    debugPrint('   Project directory exists: $projectExists');

    if (!projectExists) {
      debugPrint('   ❌ ERROR: Project directory was not created!');
      yield const GenerationProgress(
        phase: GenerationPhase.error,
        progress: 0.25,
        message: 'Failed to create Flutter project',
        error: 'Project directory not created',
      );
      return;
    }
    debugPrint('   ✓ Project directory created successfully');

    // Phase 3: Generate models
    debugPrint('');
    debugPrint('📦 PHASE 3: Generating data models...');
    debugPrint('   Total models to generate: ${appSpec.models.length}');
    yield const GenerationProgress(
      phase: GenerationPhase.generatingModels,
      progress: 0.30,
      message: 'Generating data models...',
    );

    for (var i = 0; i < appSpec.models.length; i++) {
      final model = appSpec.models[i];
      final progress = 0.30 + (0.10 * (i + 1) / appSpec.models.length);
      debugPrint('   Generating model ${i + 1}/${appSpec.models.length}: ${model.name}');

      try {
        final modelCode = await _generateModelCode(model, appSpec);
        final modelPath = _joinPath(projectPath, 'lib', 'models', '${_toSnakeCase(model.name)}.dart');
        debugPrint('   Writing to: $modelPath');
        await _writeFile(modelPath, modelCode);
        debugPrint('   ✓ Model ${model.name} written successfully');

        yield GenerationProgress(
          phase: GenerationPhase.generatingModels,
          progress: progress,
          message: 'Generated ${model.name} model',
          generatedFile: modelPath,
        );
      } catch (e, stackTrace) {
        debugPrint('   ❌ Error generating ${model.name}: $e');
        debugPrint('   Stack: $stackTrace');
        yield GenerationProgress(
          phase: GenerationPhase.generatingModels,
          progress: progress,
          message: 'Warning: Could not generate ${model.name}',
        );
      }
    }

    // Phase 4: Generate screens
    debugPrint('');
    debugPrint('📱 PHASE 4: Generating screens...');
    debugPrint('   Total screens to generate: ${appSpec.screens.length}');
    yield const GenerationProgress(
      phase: GenerationPhase.generatingScreens,
      progress: 0.40,
      message: 'Generating screens...',
    );

    for (var i = 0; i < appSpec.screens.length; i++) {
      final screen = appSpec.screens[i];
      final progress = 0.40 + (0.25 * (i + 1) / appSpec.screens.length);
      debugPrint('   Generating screen ${i + 1}/${appSpec.screens.length}: ${screen.name}');

      try {
        final screenCode = await _generateScreenCode(screen, appSpec);
        final screenPath = _joinPath(
          projectPath,
          'lib',
          'screens',
          '${_toSnakeCase(screen.name)}_screen.dart',
        );
        debugPrint('   Writing to: $screenPath');
        await _writeFile(screenPath, screenCode);
        debugPrint('   ✓ Screen ${screen.name} written successfully');

        yield GenerationProgress(
          phase: GenerationPhase.generatingScreens,
          progress: progress,
          message: 'Generated ${screen.name} screen',
          generatedFile: screenPath,
        );
      } catch (e, stackTrace) {
        debugPrint('   ❌ Error generating ${screen.name}: $e');
        debugPrint('   Stack: $stackTrace');
        yield GenerationProgress(
          phase: GenerationPhase.generatingScreens,
          progress: progress,
          message: 'Warning: Could not generate ${screen.name}',
        );
      }
    }

    // Phase 5: Generate state management
    debugPrint('');
    debugPrint('🔄 PHASE 5: Generating state management...');
    yield const GenerationProgress(
      phase: GenerationPhase.generatingState,
      progress: 0.70,
      message: 'Setting up state management...',
    );

    try {
      final stateCode = await _generateStateManagement(appSpec);
      final statePath = _joinPath(projectPath, 'lib', 'providers', 'app_provider.dart');
      debugPrint('   Writing to: $statePath');
      await _writeFile(statePath, stateCode);
      debugPrint('   ✓ State management written successfully');

      yield GenerationProgress(
        phase: GenerationPhase.generatingState,
        progress: 0.75,
        message: 'Generated state management',
        generatedFile: statePath,
      );
    } catch (e, stackTrace) {
      debugPrint('   ❌ Error generating state management: $e');
      debugPrint('   Stack: $stackTrace');
      yield GenerationProgress(
        phase: GenerationPhase.generatingState,
        progress: 0.75,
        message: 'Warning: Could not generate state management',
      );
    }

    // Phase 6: Generate navigation
    debugPrint('');
    debugPrint('🧭 PHASE 6: Generating navigation...');
    yield const GenerationProgress(
      phase: GenerationPhase.generatingNavigation,
      progress: 0.80,
      message: 'Setting up navigation...',
    );

    try {
      final routerCode = await _generateRouter(appSpec);
      final routerPath = _joinPath(projectPath, 'lib', 'router.dart');
      debugPrint('   Writing to: $routerPath');
      await _writeFile(routerPath, routerCode);
      debugPrint('   ✓ Router written successfully');

      yield GenerationProgress(
        phase: GenerationPhase.generatingNavigation,
        progress: 0.85,
        message: 'Generated navigation router',
        generatedFile: routerPath,
      );
    } catch (e, stackTrace) {
      debugPrint('   ❌ Error generating navigation: $e');
      debugPrint('   Stack: $stackTrace');
      yield GenerationProgress(
        phase: GenerationPhase.generatingNavigation,
        progress: 0.85,
        message: 'Warning: Could not generate router',
      );
    }

    // Phase 7: Generate main.dart
    debugPrint('');
    debugPrint('🏠 PHASE 7: Generating main.dart...');
    yield const GenerationProgress(
      phase: GenerationPhase.generatingMain,
      progress: 0.88,
      message: 'Generating main.dart...',
    );

    try {
      final mainCode = await _generateMain(appSpec);
      final mainPath = _joinPath(projectPath, 'lib', 'main.dart');
      debugPrint('   Writing to: $mainPath');
      await _writeFile(mainPath, mainCode);
      debugPrint('   ✓ main.dart written successfully');

      yield GenerationProgress(
        phase: GenerationPhase.generatingMain,
        progress: 0.90,
        message: 'Generated main.dart',
        generatedFile: mainPath,
      );
    } catch (e, stackTrace) {
      debugPrint('   ❌ Error generating main.dart: $e');
      debugPrint('   Stack: $stackTrace');
      yield GenerationProgress(
        phase: GenerationPhase.generatingMain,
        progress: 0.90,
        message: 'Warning: Could not generate main.dart',
      );
    }

    // Phase 8: Update pubspec and run pub get
    debugPrint('');
    debugPrint('📦 PHASE 8: Installing dependencies...');
    yield const GenerationProgress(
      phase: GenerationPhase.writingFiles,
      progress: 0.92,
      message: 'Installing dependencies...',
    );

    debugPrint('   Updating pubspec.yaml...');
    await _updatePubspec(projectPath, appSpec);
    debugPrint('   Running flutter pub get...');

    await for (final output in _terminal.pubGet(projectPath: projectPath)) {
      debugPrint('   Terminal: ${output.trim()}');
      yield GenerationProgress(
        phase: GenerationPhase.writingFiles,
        progress: 0.95,
        message: output.trim(),
      );
    }

    // Complete
    debugPrint('');
    debugPrint('╔══════════════════════════════════════════════════════════════╗');
    debugPrint('║           APP GENERATION COMPLETE!                           ║');
    debugPrint('╚══════════════════════════════════════════════════════════════╝');
    debugPrint('Project path: $projectPath');
    debugPrint('');

    yield GenerationProgress(
      phase: GenerationPhase.complete,
      progress: 1.0,
      message: 'App generated successfully at $projectPath',
    );
  }

  /// Parse a prompt into an AppSpec using AI
  Future<AppSpec> _parsePromptToSpec(String prompt, String projectName) async {
    debugPrint('   _parsePromptToSpec: Starting...');
    final systemPrompt = '''You are a Flutter app architect. Analyze the following app description and output a JSON specification.

Output ONLY valid JSON with this structure:
{
  "name": "AppName",
  "description": "Brief description",
  "screens": [
    {
      "name": "ScreenName",
      "description": "What this screen does",
      "route": "/route",
      "type": "regular|list|detail|form|dashboard|settings|profile|auth",
      "isInitial": true/false
    }
  ],
  "models": [
    {
      "name": "ModelName",
      "description": "What this model represents",
      "fields": [
        {
          "name": "fieldName",
          "type": "string|int|double|bool|datetime|list|map|reference",
          "required": true/false
        }
      ]
    }
  ],
  "features": ["feature1", "feature2"],
  "stateManagement": "provider",
  "navigation": {
    "type": "stack|bottomNav|drawer|tabs",
    "items": [
      {"label": "Label", "icon": "iconName", "route": "/route"}
    ]
  }
}

Be thorough - extract ALL screens and models needed for the described app.''';

    final messages = [
      ChatCompletionMessage.system(systemPrompt),
      ChatCompletionMessage.user('App description: $prompt\nProject name: $projectName'),
    ];

    debugPrint('   _parsePromptToSpec: Calling OpenAI API...');
    final response = await _openai.chatCompletion(
      messages: messages,
      temperature: 0.3, // Lower temperature for more consistent JSON
    );
    debugPrint('   _parsePromptToSpec: Got OpenAI response (${response.length} chars)');
    debugPrint('   _parsePromptToSpec: Response preview: ${response.substring(0, response.length > 200 ? 200 : response.length)}...');

    debugPrint('   _parsePromptToSpec: Extracting JSON...');
    final json = _openai.extractJson(response);
    if (json == null) {
      debugPrint('   _parsePromptToSpec: ❌ Failed to extract JSON from response');
      debugPrint('   Full response was: $response');
      throw Exception('Failed to parse AI response as JSON');
    }
    debugPrint('   _parsePromptToSpec: ✓ JSON extracted successfully');
    debugPrint('   _parsePromptToSpec: JSON keys: ${json.keys.toList()}');

    debugPrint('   _parsePromptToSpec: Creating AppSpec from JSON...');
    final appSpec = AppSpec.fromJson(json);
    debugPrint('   _parsePromptToSpec: ✓ AppSpec created successfully');
    return appSpec;
  }

  /// Generate model code using AI
  Future<String> _generateModelCode(ModelSpec model, AppSpec appSpec) async {
    // First try to generate using the model's built-in method
    final basicCode = model.toDartClass();

    // Enhance with AI if needed
    final systemPrompt = '''You are a Flutter/Dart expert. Enhance the following model class with:
1. Proper documentation
2. copyWith method
3. toString, == operator, and hashCode
4. Any helper methods that would be useful

Output ONLY the Dart code, no explanations.''';

    final messages = [
      ChatCompletionMessage.system(systemPrompt),
      ChatCompletionMessage.user('Base model:\n\n```dart\n$basicCode\n```'),
    ];

    final response = await _openai.chatCompletion(
      messages: messages,
      temperature: 0.5,
    );

    final blocks = _openai.extractCodeBlocks(response);
    return blocks.isNotEmpty ? blocks.first.code : basicCode;
  }

  /// Generate screen code using AI
  Future<String> _generateScreenCode(ScreenSpec screen, AppSpec appSpec) async {
    final modelNames = appSpec.models.map((m) => m.name).join(', ');
    final stateManagement = appSpec.stateManagement;

    final systemPrompt = '''You are a Flutter UI expert. Generate a complete screen widget.

Requirements:
1. Use Flutter 3.x with Material 3 design
2. State management: $stateManagement
3. Available models: $modelNames
4. Screen type: ${screen.type.name}
5. Make the UI clean, professional, and responsive
6. Include proper imports
7. Add helpful comments

Output ONLY the Dart code, no explanations.''';

    final messages = [
      ChatCompletionMessage.system(systemPrompt),
      ChatCompletionMessage.user('''Generate a Flutter screen:
Name: ${screen.name}
Description: ${screen.description}
Route: ${screen.route}
Type: ${screen.type.name}'''),
    ];

    final response = await _openai.chatCompletion(
      messages: messages,
      temperature: 0.7,
    );

    final blocks = _openai.extractCodeBlocks(response);
    return blocks.isNotEmpty ? blocks.first.code : _generateBasicScreen(screen);
  }

  /// Generate state management code
  Future<String> _generateStateManagement(AppSpec appSpec) async {
    final modelImports = appSpec.models
        .map((m) => "import '../models/${_toSnakeCase(m.name)}.dart';")
        .join('\n');

    final systemPrompt = '''You are a Flutter state management expert. Generate Provider-based state management.

Requirements:
1. Create a ChangeNotifier provider class
2. Include state for all the app's data
3. Add methods for CRUD operations
4. Handle loading and error states
5. Include proper imports

Output ONLY the Dart code, no explanations.''';

    final modelList = appSpec.models.map((m) => '- ${m.name}: ${m.description}').join('\n');

    final messages = [
      ChatCompletionMessage.system(systemPrompt),
      ChatCompletionMessage.user('''Generate Provider state management for:
App: ${appSpec.name}
Models:
$modelList'''),
    ];

    final response = await _openai.chatCompletion(
      messages: messages,
      temperature: 0.5,
    );

    final blocks = _openai.extractCodeBlocks(response);
    if (blocks.isNotEmpty) {
      return blocks.first.code;
    }

    // Fallback basic provider
    return '''import 'package:flutter/foundation.dart';
$modelImports

class AppProvider extends ChangeNotifier {
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void setError(String? error) {
    _error = error;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
''';
  }

  /// Generate router code
  Future<String> _generateRouter(AppSpec appSpec) async {
    final screenImports = appSpec.screens
        .map((s) => "import 'screens/${_toSnakeCase(s.name)}_screen.dart';")
        .join('\n');

    final routes = appSpec.screens.map((s) {
      final className = _toPascalCase(s.name);
      return "    '${s.route}': (context) => const ${className}Screen(),";
    }).join('\n');

    final initialRoute = appSpec.screens.firstWhere(
      (s) => s.isInitial,
      orElse: () => appSpec.screens.isNotEmpty ? appSpec.screens.first : const ScreenSpec(name: 'Home', description: '', route: '/'),
    ).route;

    return '''import 'package:flutter/material.dart';
$screenImports

class AppRouter {
  static const String initialRoute = '$initialRoute';

  static Map<String, WidgetBuilder> get routes => {
$routes
  };

  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    final builder = routes[settings.name];
    if (builder != null) {
      return MaterialPageRoute(builder: builder, settings: settings);
    }
    return null;
  }
}
''';
  }

  /// Generate main.dart
  Future<String> _generateMain(AppSpec appSpec) async {
    final appName = _toPascalCase(appSpec.name);

    return '''import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'router.dart';
import 'providers/app_provider.dart';

void main() {
  runApp(const ${appName}App());
}

class ${appName}App extends StatelessWidget {
  const ${appName}App({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppProvider()),
      ],
      child: MaterialApp(
        title: '${appSpec.name}',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blue,
            brightness: Brightness.light,
          ),
          useMaterial3: true,
        ),
        darkTheme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blue,
            brightness: Brightness.dark,
          ),
          useMaterial3: true,
        ),
        themeMode: ThemeMode.system,
        initialRoute: AppRouter.initialRoute,
        routes: AppRouter.routes,
        onGenerateRoute: AppRouter.onGenerateRoute,
      ),
    );
  }
}
''';
  }

  /// Update pubspec.yaml with dependencies (web-compatible)
  Future<void> _updatePubspec(String projectPath, AppSpec appSpec) async {
    final pubspecPath = _joinPath(projectPath, 'pubspec.yaml');

    // Read current pubspec content using project manager
    String? content;
    try {
      content = await _projectManager.readFile(pubspecPath);
    } catch (e) {
      debugPrint('   Could not read pubspec.yaml: $e');
      return;
    }

    if (content == null || content.isEmpty) return;

    final dependencies = <String, String>{
      'provider': '^6.1.1',
    };

    // Add state management specific dependencies
    switch (appSpec.stateManagement) {
      case 'riverpod':
        dependencies['flutter_riverpod'] = '^2.4.9';
        break;
      case 'bloc':
        dependencies['flutter_bloc'] = '^8.1.3';
        break;
    }

    // Find dependencies section and add new deps
    final depsPattern = RegExp(r'dependencies:\s*\n', multiLine: true);
    final match = depsPattern.firstMatch(content);

    if (match != null) {
      final insertPosition = match.end;
      final depsToAdd = StringBuffer();

      for (final entry in dependencies.entries) {
        if (!content.contains('${entry.key}:')) {
          depsToAdd.writeln('  ${entry.key}: ${entry.value}');
        }
      }

      if (depsToAdd.isNotEmpty) {
        content = content.substring(0, insertPosition) +
            depsToAdd.toString() +
            content.substring(insertPosition);
        await _projectManager.writeFile(pubspecPath, content);
      }
    }
  }

  /// Write file using the project manager (web-compatible)
  ///
  /// Note: The backend server handles directory creation automatically
  Future<void> _writeFile(String filePath, String content) async {
    await _projectManager.writeFile(filePath, content);
  }

  /// Join path segments (web-compatible, works with both forward and back slashes)
  String _joinPath(String base, [String? p1, String? p2, String? p3, String? p4]) {
    final parts = <String>[base];
    if (p1 != null) parts.add(p1);
    if (p2 != null) parts.add(p2);
    if (p3 != null) parts.add(p3);
    if (p4 != null) parts.add(p4);
    // Normalize to forward slashes and join
    return parts.map((p) => p.replaceAll('\\', '/')).join('/');
  }

  /// Generate a basic screen fallback
  String _generateBasicScreen(ScreenSpec screen) {
    final className = _toPascalCase(screen.name);

    return '''import 'package:flutter/material.dart';

class ${className}Screen extends StatelessWidget {
  const ${className}Screen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('${screen.name}'),
      ),
      body: Center(
        child: Text(
          '${screen.description}',
          style: Theme.of(context).textTheme.headlineSmall,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
''';
  }

  /// Convert string to PascalCase
  String _toPascalCase(String s) {
    return s.split(RegExp(r'[_\s]+')).map((w) {
      if (w.isEmpty) return w;
      return w[0].toUpperCase() + w.substring(1).toLowerCase();
    }).join();
  }

  /// Convert string to snake_case
  String _toSnakeCase(String s) {
    return s
        .replaceAllMapped(
          RegExp(r'([A-Z])'),
          (m) => '_${m.group(1)!.toLowerCase()}',
        )
        .replaceAll(RegExp(r'^_'), '')
        .replaceAll(RegExp(r'\s+'), '_')
        .toLowerCase();
  }
}
