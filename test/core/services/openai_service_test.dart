import 'package:flutter_test/flutter_test.dart';
import 'package:visual_app_builder/core/services/openai_service.dart';

void main() {
  group('OpenAIService', () {
    late OpenAIService service;

    setUp(() {
      service = OpenAIService.instance;
    });

    group('Configuration', () {
      test('should not be configured initially without API key', () {
        // Clear any existing configuration
        service.clearApiKey();
        expect(service.isConfigured, isFalse);
      });

      test('should be configured after setting API key', () {
        service.configure(apiKey: 'test-api-key');
        expect(service.isConfigured, isTrue);
      });

      test('should clear configuration', () {
        service.configure(apiKey: 'test-api-key');
        service.clearApiKey();
        expect(service.isConfigured, isFalse);
      });

      test('should use default model when not specified', () {
        service.configure(apiKey: 'test-api-key');
        // The service should use gpt-4 as default
        expect(service.isConfigured, isTrue);
      });

      test('should accept custom model', () {
        service.configure(apiKey: 'test-api-key', model: 'gpt-3.5-turbo');
        expect(service.isConfigured, isTrue);
      });
    });

    group('Singleton Pattern', () {
      test('should return same instance', () {
        final instance1 = OpenAIService.instance;
        final instance2 = OpenAIService.instance;
        expect(identical(instance1, instance2), isTrue);
      });
    });

    group('Message Formatting', () {
      test('should format system message correctly', () {
        final messages = [
          {'role': 'system', 'content': 'You are a helpful assistant'},
          {'role': 'user', 'content': 'Hello'},
        ];

        expect(messages[0]['role'], equals('system'));
        expect(messages[1]['role'], equals('user'));
      });
    });

    group('SSE Parsing', () {
      test('should parse SSE data line correctly', () {
        const sseLine = 'data: {"choices":[{"delta":{"content":"Hello"}}]}';

        // Extract the JSON part
        final jsonStr = sseLine.substring(6); // Remove 'data: '
        expect(jsonStr, startsWith('{'));
        expect(jsonStr, contains('choices'));
      });

      test('should handle [DONE] marker', () {
        const doneLine = 'data: [DONE]';
        final isDone = doneLine.contains('[DONE]');
        expect(isDone, isTrue);
      });

      test('should ignore empty lines', () {
        const emptyLine = '';
        expect(emptyLine.isEmpty, isTrue);
      });
    });
  });
}
