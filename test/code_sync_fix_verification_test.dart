import 'package:flutter_test/flutter_test.dart';
import 'package:visual_app_builder/core/services/code_sync_service.dart';

/// Verification tests for the bracket counting fix
/// Tests the exact scenarios mentioned in the fix request
void main() {
  group('CodeSyncService bracket counting FIX verification', () {
    late CodeSyncService service;

    setUp(() {
      service = CodeSyncService.instance;
    });

    test('SCENARIO 1: String literals with brackets - Text(\'List with ")" item\')', () async {
      const sourceCode = '''
Column(
  children: [
    Text('List with ")" item'),
  ],
)
''';

      final resultMap = await service.insertWidget(
        sourceCode: sourceCode,
        lineNumber: 1,
        widgetCode: "Text('New')",
        position: InsertPosition.asChild,
      );
      final result = resultMap['code'] as String;

      expect(result.contains("Text('New')"), isTrue,
        reason: 'Should insert new widget correctly');
      expect(result.contains("Text('List with \")\" item')"), isTrue,
        reason: 'Should preserve existing string with bracket');
    });

    test('SCENARIO 2: Comments with brackets - // Container( commented out', () async {
      const sourceCode = '''
Column(
  children: [
    // Container( commented out
    Text('Active'),
  ],
)
''';

      final resultMap = await service.insertWidget(
        sourceCode: sourceCode,
        lineNumber: 1,
        widgetCode: "Text('New')",
        position: InsertPosition.asChild,
      );
      final result = resultMap['code'] as String;

      expect(result.contains("Text('New')"), isTrue,
        reason: 'Should insert new widget correctly');
      expect(result.contains("// Container( commented out"), isTrue,
        reason: 'Should preserve comment with bracket');
    });

    test('SCENARIO 3: Escape sequences - Text(\'Hello\\\'s world\')', () async {
      const sourceCode = '''
Column(
  children: [
    Text('It\\'s a test'),
  ],
)
''';

      final resultMap = await service.insertWidget(
        sourceCode: sourceCode,
        lineNumber: 1,
        widgetCode: "Text('New')",
        position: InsertPosition.asChild,
      );
      final result = resultMap['code'] as String;

      expect(result.contains("Text('New')"), isTrue,
        reason: 'Should handle escape sequences correctly');
    });

    test('SCENARIO 4: Complex nested code from fix request', () async {
      const sourceCode = '''
Column(
  children: [
    Text("Hello (world)"),  // Has bracket in string
    // Container( commented out
    Row(children: []),
  ],
)
''';

      final resultMap = await service.insertWidget(
        sourceCode: sourceCode,
        lineNumber: 1,
        widgetCode: "Text('New widget')",
        position: InsertPosition.asChild,
      );
      final result = resultMap['code'] as String;

      print('Complex scenario result:');
      final lines = result.split('\n');
      for (int i = 0; i < lines.length; i++) {
        print('${i + 1}: ${lines[i]}');
      }

      // All original content should be preserved
      expect(result.contains('Text("Hello (world)")'), isTrue,
        reason: 'Should preserve string with brackets');
      expect(result.contains("// Container( commented out"), isTrue,
        reason: 'Should preserve comment with brackets');
      expect(result.contains("Row(children: [])"), isTrue,
        reason: 'Should preserve nested widget');
      expect(result.contains("Text('New widget')"), isTrue,
        reason: 'Should insert new widget correctly');
    });

    test('SCENARIO 5: Block comments with nested brackets /* ... ( ... ) ... */', () async {
      const sourceCode = '''
Column(
  children: [
    /* This is a (multi-line) comment
       with [brackets] inside */
    Text('Active'),
  ],
)
''';

      final resultMap = await service.insertWidget(
        sourceCode: sourceCode,
        lineNumber: 1,
        widgetCode: "Text('New')",
        position: InsertPosition.asChild,
      );
      final result = resultMap['code'] as String;

      expect(result.contains("Text('New')"), isTrue,
        reason: 'Should handle block comments with brackets');
      expect(result.contains("/* This is a (multi-line) comment"), isTrue,
        reason: 'Should preserve block comment');
    });

    test('SCENARIO 6: Mixed quotes with escaped characters', () async {
      const sourceCode = '''
Column(
  children: [
    Text("String with \\"escaped\\" quotes (test)"),
  ],
)
''';

      final resultMap = await service.insertWidget(
        sourceCode: sourceCode,
        lineNumber: 1,
        widgetCode: "Text('New')",
        position: InsertPosition.asChild,
      );
      final result = resultMap['code'] as String;

      expect(result.contains("Text('New')"), isTrue,
        reason: 'Should handle escaped quotes in strings');
    });

    test('SCENARIO 7: Regex-like patterns with brackets in strings', () async {
      const sourceCode = '''
Column(
  children: [
    Text('RegExp pattern: [a-z]+'),
    Text('Another pattern: (\\\\d+)'),
  ],
)
''';

      final resultMap = await service.insertWidget(
        sourceCode: sourceCode,
        lineNumber: 1,
        widgetCode: "Text('New')",
        position: InsertPosition.asChild,
      );
      final result = resultMap['code'] as String;

      expect(result.contains("Text('New')"), isTrue,
        reason: 'Should handle regex-like patterns with brackets');
      expect(result.contains("Text('RegExp pattern: [a-z]+')"), isTrue,
        reason: 'Should preserve regex pattern in string');
    });
  });
}
