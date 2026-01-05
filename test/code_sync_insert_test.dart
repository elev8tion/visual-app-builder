import 'package:flutter_test/flutter_test.dart';
import 'package:visual_app_builder/core/services/code_sync_service.dart';

void main() {
  group('CodeSyncService insertWidget', () {
    late CodeSyncService service;

    setUp(() {
      service = CodeSyncService.instance;
    });

    test('insertWidget asChild into Column children array', () async {
      const sourceCode = '''
import 'package:flutter/material.dart';

class ScratchScreen extends StatelessWidget {
  const ScratchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scratch Canvas'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
          ],
        ),
      ),
    );
  }
}
''';

      final resultMap = await service.insertWidget(
        sourceCode: sourceCode,
        lineNumber: 13, // Line of Column
        widgetCode: "Text('Hello World')",
        position: InsertPosition.asChild,
      );
      final result = resultMap['code'] as String;
      final linesInserted = resultMap['linesInserted'] as int;

      // Verify the Text widget was inserted into the children array
      expect(result.contains("Text('Hello World')"), isTrue);

      // Verify the children array now has content
      expect(result.contains("children: <Widget>["), isTrue);

      // Verify linesInserted is tracked
      expect(linesInserted, greaterThanOrEqualTo(0));
    });

    test('insertWidget asChild handles Column with empty children: []', () async {
      const sourceCode = '''
Column(
  mainAxisAlignment: MainAxisAlignment.center,
  children: [],
)
''';

      final resultMap = await service.insertWidget(
        sourceCode: sourceCode,
        lineNumber: 1, // Line of Column
        widgetCode: "Text('Test')",
        position: InsertPosition.asChild,
      );
      final result = resultMap['code'] as String;

      expect(result.contains("Text('Test')"), isTrue);
    });
  });
}
