import 'dart:async';
import 'dart:io';
import 'package:path/path.dart' as path;
import '../models/app_spec.dart';
import 'openai_service.dart';
import 'config_service.dart';
import 'terminal_service.dart';

/// App Generation Service
///
/// Generates complete Flutter apps from natural language prompts using AI.
/// Parses prompts into AppSpec, generates code, and creates project files.
class AppGenerationService {
  static final AppGenerationService _instance = AppGenerationService._internal();
  static AppGenerationService get instance => _instance;
  AppGenerationService._internal();

  final OpenAIService _openai = OpenAIService.instance;
  final ConfigService _config = ConfigService.instance;
  final TerminalService _terminal = TerminalService.instance;

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
    if (!_openai.isConfigured) {
      yield const GenerationProgress(
        phase: GenerationPhase.error,
        progress: 0,
        message: 'OpenAI is not configured. Please set your API key.',
        error: 'API key not configured',
      );
      return;
    }

    final projectPath = path.join(outputPath, projectName);

    // Phase 1: Parse prompt into AppSpec
    yield const GenerationProgress(
      phase: GenerationPhase.parsing,
      progress: 0.05,
      message: 'Analyzing your app description...',
    );

    AppSpec? appSpec;
    try {
      appSpec = await _parsePromptToSpec(prompt, projectName);
      yield GenerationProgress(
        phase: GenerationPhase.parsing,
        progress: 0.15,
        message: 'Found ${appSpec.screens.length} screens and ${appSpec.models.length} models',
      );
    } catch (e) {
      yield GenerationProgress(
        phase: GenerationPhase.error,
        progress: 0.15,
        message: 'Failed to analyze prompt',
        error: e.toString(),
      );
      return;
    }

    // Phase 2: Create base Flutter project
    yield const GenerationProgress(
      phase: GenerationPhase.planning,
      progress: 0.20,
      message: 'Creating Flutter project...',
    );

    final org = organization ?? await _config.getOrganization();
    await for (final output in _terminal.createProject(
      name: projectName,
      outputPath: outputPath,
      organization: org,
    )) {
      // Stream terminal output as messages
      yield GenerationProgress(
        phase: GenerationPhase.planning,
        progress: 0.25,
        message: output.trim(),
      );
    }

    // Check project created
    if (!await Directory(projectPath).exists()) {
      yield const GenerationProgress(
        phase: GenerationPhase.error,
        progress: 0.25,
        message: 'Failed to create Flutter project',
        error: 'Project directory not created',
      );
      return;
    }

    // Phase 3: Generate models
    yield const GenerationProgress(
      phase: GenerationPhase.generatingModels,
      progress: 0.30,
      message: 'Generating data models...',
    );

    for (var i = 0; i < appSpec.models.length; i++) {
      final model = appSpec.models[i];
      final progress = 0.30 + (0.10 * (i + 1) / appSpec.models.length);

      try {
        final modelCode = await _generateModelCode(model, appSpec);
        final modelPath = path.join(projectPath, 'lib', 'models', '${_toSnakeCase(model.name)}.dart');
        await _writeFile(modelPath, modelCode);

        yield GenerationProgress(
          phase: GenerationPhase.generatingModels,
          progress: progress,
          message: 'Generated ${model.name} model',
          generatedFile: modelPath,
        );
      } catch (e) {
        yield GenerationProgress(
          phase: GenerationPhase.generatingModels,
          progress: progress,
          message: 'Warning: Could not generate ${model.name}',
        );
      }
    }

    // Phase 4: Generate screens
    yield const GenerationProgress(
      phase: GenerationPhase.generatingScreens,
      progress: 0.40,
      message: 'Generating screens...',
    );

    for (var i = 0; i < appSpec.screens.length; i++) {
      final screen = appSpec.screens[i];
      final progress = 0.40 + (0.25 * (i + 1) / appSpec.screens.length);

      try {
        final screenCode = await _generateScreenCode(screen, appSpec);
        final screenPath = path.join(
          projectPath,
          'lib',
          'screens',
          '${_toSnakeCase(screen.name)}_screen.dart',
        );
        await _writeFile(screenPath, screenCode);

        yield GenerationProgress(
          phase: GenerationPhase.generatingScreens,
          progress: progress,
          message: 'Generated ${screen.name} screen',
          generatedFile: screenPath,
        );
      } catch (e) {
        yield GenerationProgress(
          phase: GenerationPhase.generatingScreens,
          progress: progress,
          message: 'Warning: Could not generate ${screen.name}',
        );
      }
    }

    // Phase 5: Generate state management
    yield const GenerationProgress(
      phase: GenerationPhase.generatingState,
      progress: 0.70,
      message: 'Setting up state management...',
    );

    try {
      final stateCode = await _generateStateManagement(appSpec);
      final statePath = path.join(projectPath, 'lib', 'providers', 'app_provider.dart');
      await _writeFile(statePath, stateCode);

      yield GenerationProgress(
        phase: GenerationPhase.generatingState,
        progress: 0.75,
        message: 'Generated state management',
        generatedFile: statePath,
      );
    } catch (e) {
      yield GenerationProgress(
        phase: GenerationPhase.generatingState,
        progress: 0.75,
        message: 'Warning: Could not generate state management',
      );
    }

    // Phase 6: Generate navigation
    yield const GenerationProgress(
      phase: GenerationPhase.generatingNavigation,
      progress: 0.80,
      message: 'Setting up navigation...',
    );

    try {
      final routerCode = await _generateRouter(appSpec);
      final routerPath = path.join(projectPath, 'lib', 'router.dart');
      await _writeFile(routerPath, routerCode);

      yield GenerationProgress(
        phase: GenerationPhase.generatingNavigation,
        progress: 0.85,
        message: 'Generated navigation router',
        generatedFile: routerPath,
      );
    } catch (e) {
      yield GenerationProgress(
        phase: GenerationPhase.generatingNavigation,
        progress: 0.85,
        message: 'Warning: Could not generate router',
      );
    }

    // Phase 7: Generate main.dart
    yield const GenerationProgress(
      phase: GenerationPhase.generatingMain,
      progress: 0.88,
      message: 'Generating main.dart...',
    );

    try {
      final mainCode = await _generateMain(appSpec);
      final mainPath = path.join(projectPath, 'lib', 'main.dart');
      await _writeFile(mainPath, mainCode);

      yield GenerationProgress(
        phase: GenerationPhase.generatingMain,
        progress: 0.90,
        message: 'Generated main.dart',
        generatedFile: mainPath,
      );
    } catch (e) {
      yield GenerationProgress(
        phase: GenerationPhase.generatingMain,
        progress: 0.90,
        message: 'Warning: Could not generate main.dart',
      );
    }

    // Phase 8: Update pubspec and run pub get
    yield const GenerationProgress(
      phase: GenerationPhase.writingFiles,
      progress: 0.92,
      message: 'Installing dependencies...',
    );

    await _updatePubspec(projectPath, appSpec);

    await for (final output in _terminal.pubGet(projectPath: projectPath)) {
      yield GenerationProgress(
        phase: GenerationPhase.writingFiles,
        progress: 0.95,
        message: output.trim(),
      );
    }

    // Complete
    yield GenerationProgress(
      phase: GenerationPhase.complete,
      progress: 1.0,
      message: 'App generated successfully at $projectPath',
    );
  }

  /// Parse a prompt into an AppSpec using AI
  Future<AppSpec> _parsePromptToSpec(String prompt, String projectName) async {
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

    final response = await _openai.chatCompletion(
      messages: messages,
      temperature: 0.3, // Lower temperature for more consistent JSON
    );

    final json = _openai.extractJson(response);
    if (json == null) {
      throw Exception('Failed to parse AI response as JSON');
    }

    return AppSpec.fromJson(json);
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

  /// Update pubspec.yaml with dependencies
  Future<void> _updatePubspec(String projectPath, AppSpec appSpec) async {
    final pubspecPath = path.join(projectPath, 'pubspec.yaml');
    final pubspecFile = File(pubspecPath);

    if (!await pubspecFile.exists()) return;

    String content = await pubspecFile.readAsString();

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
        await pubspecFile.writeAsString(content);
      }
    }
  }

  /// Write file to disk, creating directories as needed
  Future<void> _writeFile(String filePath, String content) async {
    final file = File(filePath);
    final dir = Directory(path.dirname(filePath));

    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }

    await file.writeAsString(content);
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
