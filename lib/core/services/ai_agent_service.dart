import 'dart:async';
import '../models/widget_node.dart';
import '../models/widget_selection.dart';

class EditorContext {
  final String? currentFile;
  final String? currentCode;
  final WidgetNode? selectedWidget;
  final WidgetSelection? selectedAstWidget;

  EditorContext({
    this.currentFile,
    this.currentCode,
    this.selectedWidget,
    this.selectedAstWidget,
  });
}

class AIAgentService {
  static final AIAgentService _instance = AIAgentService._internal();
  static AIAgentService get instance => _instance;

  AIAgentService._internal();

  /// Simulates sending a message to an AI agent and receiving a stream of text chunks.
  Stream<String> sendMessage(String message, {EditorContext? context}) async* {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));

    // Construct a simulated response based on context
    final responseBuffer = StringBuffer();
    responseBuffer.write('I received your message: "$message"\n\n');

    if (context != null) {
      if (context.currentFile != null) {
        responseBuffer.write('I see you are working on: ${context.currentFile}\n');
      }
      if (context.selectedWidget != null) {
        responseBuffer.write('You have selected a widget: ${context.selectedWidget!.type}\n');
      }
    }

    responseBuffer.write('\nThis is a simulated streaming response to demonstrate the architecture.');

    // Stream the response character by character or chunk by chunk
    final fullResponse = responseBuffer.toString();
    for (int i = 0; i < fullResponse.length; i += 5) {
      final end = (i + 5 < fullResponse.length) ? i + 5 : fullResponse.length;
      yield fullResponse.substring(i, end);
      await Future.delayed(const Duration(milliseconds: 50));
    }
  }
}
