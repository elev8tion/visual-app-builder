import 'dart:async';
import '../models/widget_node.dart';
import '../models/widget_selection.dart';
import 'openai_service.dart';
import 'config_service.dart';

/// Editor context passed to AI for code generation
class EditorContext {
  final String? currentFile;
  final String? currentCode;
  final WidgetNode? selectedWidget;
  final WidgetSelection? selectedAstWidget;
  final String? projectStructure;
  final List<String>? recentFiles;
  final Map<String, String>? relatedFiles;

  EditorContext({
    this.currentFile,
    this.currentCode,
    this.selectedWidget,
    this.selectedAstWidget,
    this.projectStructure,
    this.recentFiles,
    this.relatedFiles,
  });
}

/// AI Agent Service
///
/// Provides AI-powered code generation and assistance using OpenAI GPT-4.
/// Supports streaming responses and context-aware code generation.
class AIAgentService {
  static final AIAgentService _instance = AIAgentService._internal();
  static AIAgentService get instance => _instance;

  AIAgentService._internal();

  final OpenAIService _openai = OpenAIService.instance;
  final ConfigService _config = ConfigService.instance;

  /// Initialize the service (load API key from config)
  Future<void> initialize() async {
    final apiKey = await _config.getOpenAIKey();
    final model = await _config.getOpenAIModel();
    if (apiKey != null && apiKey.isNotEmpty) {
      _openai.configure(apiKey: apiKey, model: model);
    }
  }

  /// Check if OpenAI is configured
  bool get isConfigured => _openai.isConfigured;

  /// Configure with API key
  Future<void> configure(String apiKey, {String? model}) async {
    _openai.configure(apiKey: apiKey, model: model);
    await _config.setOpenAIKey(apiKey);
    if (model != null) {
      await _config.setOpenAIModel(model);
    }
  }

  /// Build system prompt for Flutter development
  String _buildSystemPrompt(EditorContext? context) {
    final buffer = StringBuffer();

    buffer.writeln('''You are an expert Flutter developer assistant integrated into a visual app builder IDE.

Your capabilities:
1. Generate high-quality Flutter/Dart code
2. Explain code and suggest improvements
3. Help debug issues
4. Create complete screens and widgets
5. Set up state management patterns

Guidelines:
- Use modern Flutter 3.x patterns and best practices
- Follow Material 3 design guidelines
- Write clean, well-commented code
- Use proper state management (Provider, Riverpod, or BLoC as appropriate)
- Handle errors gracefully
- Make code accessible and responsive

When generating code:
- Wrap code in \`\`\`dart code blocks
- Include necessary imports
- Add helpful comments explaining the code
- Consider edge cases and null safety''');

    if (context != null) {
      buffer.writeln('\n--- Current Context ---');

      if (context.currentFile != null) {
        buffer.writeln('Current file: ${context.currentFile}');
      }

      if (context.selectedAstWidget != null) {
        buffer.writeln('Selected widget: ${context.selectedAstWidget!.widgetType}');
        buffer.writeln('At line: ${context.selectedAstWidget!.lineNumber}');
      } else if (context.selectedWidget != null) {
        buffer.writeln('Selected widget: ${context.selectedWidget!.type}');
      }

      if (context.projectStructure != null) {
        buffer.writeln('\nProject structure:\n${context.projectStructure}');
      }
    }

    return buffer.toString();
  }

  /// Send a message to the AI and receive streaming response
  Stream<String> sendMessage(String message, {EditorContext? context}) async* {
    // Check if OpenAI is configured
    if (!_openai.isConfigured) {
      yield 'OpenAI is not configured. Please set your API key in Settings.\n\n';
      yield 'To get an API key:\n';
      yield '1. Go to https://platform.openai.com/api-keys\n';
      yield '2. Create a new API key\n';
      yield '3. Click the Settings icon in the toolbar\n';
      yield '4. Enter your API key and click Save\n';
      return;
    }

    final systemPrompt = _buildSystemPrompt(context);
    final messages = <ChatCompletionMessage>[
      ChatCompletionMessage.system(systemPrompt),
    ];

    // Add current code as context if available
    if (context?.currentCode != null && context!.currentCode!.isNotEmpty) {
      messages.add(ChatCompletionMessage.user(
        'Here is the current code I\'m working with:\n\n```dart\n${context.currentCode}\n```',
      ));
    }

    // Add related files as context
    if (context?.relatedFiles != null) {
      for (final entry in context!.relatedFiles!.entries) {
        messages.add(ChatCompletionMessage.user(
          'Related file (${entry.key}):\n\n```dart\n${entry.value}\n```',
        ));
      }
    }

    // Add the user's message
    messages.add(ChatCompletionMessage.user(message));

    // Stream the response
    await for (final chunk in _openai.streamChatCompletion(messages: messages)) {
      yield chunk;
    }
  }

  /// Generate code for a specific task (non-streaming)
  Future<String> generateCode({
    required String prompt,
    EditorContext? context,
    double temperature = 0.7,
  }) async {
    if (!_openai.isConfigured) {
      throw Exception('OpenAI is not configured');
    }

    final systemPrompt = _buildSystemPrompt(context);
    final messages = <ChatCompletionMessage>[
      ChatCompletionMessage.system(systemPrompt),
    ];

    if (context?.currentCode != null) {
      messages.add(ChatCompletionMessage.user(
        'Current code:\n```dart\n${context!.currentCode}\n```',
      ));
    }

    messages.add(ChatCompletionMessage.user(prompt));

    return await _openai.chatCompletion(
      messages: messages,
      temperature: temperature,
    );
  }

  /// Generate a Flutter screen from description
  Future<String> generateScreen({
    required String screenName,
    required String description,
    String stateManagement = 'provider',
    EditorContext? context,
  }) async {
    final prompt = '''Generate a complete Flutter screen widget.

Screen name: $screenName
Description: $description
State management: $stateManagement

Requirements:
1. Create a StatefulWidget or StatelessWidget as appropriate
2. Include proper state management setup
3. Add all necessary imports
4. Make the UI responsive and accessible
5. Include error handling where needed
6. Add helpful comments

Return only the Dart code.''';

    return await generateCode(prompt: prompt, context: context);
  }

  /// Generate a Flutter widget from description
  Future<String> generateWidget({
    required String widgetName,
    required String description,
    bool stateful = false,
    EditorContext? context,
  }) async {
    final prompt = '''Generate a Flutter ${stateful ? 'StatefulWidget' : 'StatelessWidget'}.

Widget name: $widgetName
Description: $description

Requirements:
1. Make it reusable with appropriate constructor parameters
2. Include proper typing and null safety
3. Add documentation comments
4. Make it visually appealing using Material 3

Return only the Dart code.''';

    return await generateCode(prompt: prompt, context: context);
  }

  /// Extract code blocks from a response
  List<CodeBlock> extractCodeBlocks(String response) {
    return _openai.extractCodeBlocks(response);
  }

  /// Extract JSON from a response
  Map<String, dynamic>? extractJson(String response) {
    return _openai.extractJson(response);
  }
}
