import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

/// OpenAI API Service
///
/// Provides streaming chat completions using GPT-4.
/// Handles API communication, streaming responses, and code extraction.
class OpenAIService {
  static final OpenAIService _instance = OpenAIService._internal();
  static OpenAIService get instance => _instance;
  OpenAIService._internal();

  String? _apiKey;
  final String _baseUrl = 'https://api.openai.com/v1';
  String _model = 'gpt-4-turbo-preview';

  bool get isConfigured => _apiKey != null && _apiKey!.isNotEmpty;

  /// Configure the service with an API key
  void configure({required String apiKey, String? model}) {
    _apiKey = apiKey;
    if (model != null) _model = model;
  }

  /// Clear the API key
  void clearApiKey() {
    _apiKey = null;
  }

  /// Stream chat completions from OpenAI
  Stream<String> streamChatCompletion({
    required List<ChatCompletionMessage> messages,
    double temperature = 0.7,
    int maxTokens = 4096,
  }) async* {
    if (_apiKey == null) {
      yield 'Error: OpenAI API key not configured. Please set your API key in settings.';
      return;
    }

    try {
      final request = http.Request(
        'POST',
        Uri.parse('$_baseUrl/chat/completions'),
      );

      request.headers.addAll({
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_apiKey',
      });

      request.body = jsonEncode({
        'model': _model,
        'messages': messages.map((m) => m.toJson()).toList(),
        'temperature': temperature,
        'max_tokens': maxTokens,
        'stream': true,
      });

      final response = await http.Client().send(request);

      if (response.statusCode != 200) {
        final body = await response.stream.bytesToString();
        final error = jsonDecode(body);
        yield 'Error: ${error['error']?['message'] ?? 'Unknown error'}';
        return;
      }

      // Parse SSE stream
      await for (final chunk in response.stream.transform(utf8.decoder)) {
        final lines = chunk.split('\n');
        for (final line in lines) {
          if (line.startsWith('data: ')) {
            final data = line.substring(6).trim();
            if (data == '[DONE]') {
              return;
            }
            try {
              final json = jsonDecode(data);
              final content = json['choices']?[0]?['delta']?['content'];
              if (content != null) {
                yield content;
              }
            } catch (e) {
              // Skip malformed JSON chunks
            }
          }
        }
      }
    } catch (e) {
      yield 'Error communicating with OpenAI: $e';
    }
  }

  /// Non-streaming chat completion for structured responses
  Future<String> chatCompletion({
    required List<ChatCompletionMessage> messages,
    double temperature = 0.7,
    int maxTokens = 4096,
  }) async {
    if (_apiKey == null) {
      throw Exception('OpenAI API key not configured');
    }

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': _model,
          'messages': messages.map((m) => m.toJson()).toList(),
          'temperature': temperature,
          'max_tokens': maxTokens,
        }),
      );

      if (response.statusCode != 200) {
        final error = jsonDecode(response.body);
        throw Exception(error['error']?['message'] ?? 'Unknown error');
      }

      final json = jsonDecode(response.body);
      return json['choices'][0]['message']['content'] ?? '';
    } catch (e) {
      throw Exception('Error communicating with OpenAI: $e');
    }
  }

  /// Extract code blocks from AI responses
  List<CodeBlock> extractCodeBlocks(String response) {
    final blocks = <CodeBlock>[];
    final pattern = RegExp(r'```(\w+)?\s*\n([\s\S]*?)```', multiLine: true);

    for (final match in pattern.allMatches(response)) {
      final language = match.group(1) ?? 'dart';
      final code = match.group(2)?.trim() ?? '';

      // Try to extract filename from comment at start of code
      String? filename;
      final filenamePattern = RegExp(r'^//\s*(?:file:|filename:)?\s*(.+\.dart)\s*$', multiLine: true);
      final filenameMatch = filenamePattern.firstMatch(code);
      if (filenameMatch != null) {
        filename = filenameMatch.group(1)?.trim();
      }

      blocks.add(CodeBlock(
        language: language,
        code: code,
        filename: filename,
      ));
    }

    return blocks;
  }

  /// Extract JSON from AI response (for structured outputs)
  Map<String, dynamic>? extractJson(String response) {
    // Try to find JSON in code blocks first
    final jsonBlockPattern = RegExp(r'```(?:json)?\s*\n([\s\S]*?)```', multiLine: true);
    final blockMatch = jsonBlockPattern.firstMatch(response);
    if (blockMatch != null) {
      try {
        return jsonDecode(blockMatch.group(1)!.trim());
      } catch (e) {
        // Continue to try other methods
      }
    }

    // Try to find raw JSON object
    final jsonPattern = RegExp(r'\{[\s\S]*\}');
    final jsonMatch = jsonPattern.firstMatch(response);
    if (jsonMatch != null) {
      try {
        return jsonDecode(jsonMatch.group(0)!);
      } catch (e) {
        return null;
      }
    }

    return null;
  }
}

/// Chat completion message
class ChatCompletionMessage {
  final String role; // 'system', 'user', 'assistant'
  final String content;

  const ChatCompletionMessage({
    required this.role,
    required this.content,
  });

  Map<String, dynamic> toJson() => {
    'role': role,
    'content': content,
  };

  factory ChatCompletionMessage.system(String content) =>
      ChatCompletionMessage(role: 'system', content: content);

  factory ChatCompletionMessage.user(String content) =>
      ChatCompletionMessage(role: 'user', content: content);

  factory ChatCompletionMessage.assistant(String content) =>
      ChatCompletionMessage(role: 'assistant', content: content);
}

/// Extracted code block from AI response
class CodeBlock {
  final String language;
  final String code;
  final String? filename;

  const CodeBlock({
    required this.language,
    required this.code,
    this.filename,
  });

  bool get isDart => language.toLowerCase() == 'dart';
  bool get isYaml => language.toLowerCase() == 'yaml' || language.toLowerCase() == 'yml';
  bool get isJson => language.toLowerCase() == 'json';
}
