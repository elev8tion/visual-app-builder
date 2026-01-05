import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:visual_app_builder/core/services/dart_ast_parser_service.dart';

void main() {
  group('DartAstParserService', () {
    late DartAstParserService parser;

    setUp(() {
      parser = DartAstParserService.instance;
    });

    test('should correctly parse widget nesting levels', () async {
      const scratchTemplate = '''
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

      final result = await parser.parseWidgetTree(scratchTemplate, 'scratch.dart');

      expect(result, isNotNull);
      expect(result!.name, 'Root');
      expect(result.children, isNotEmpty);

      // Print the parsed tree for debugging
      void printTree(dynamic node, int depth) {
        final indent = '  ' * depth;
        debugPrint('$indent${node.name} (nesting: ${node.nestingLevel}, children: ${node.children.length})');
        for (final child in node.children) {
          printTree(child, depth + 1);
        }
      }

      debugPrint('Parsed widget tree:');
      printTree(result, 0);

      // Verify nesting levels
      // Scaffold should be at level 0 (root level in the return statement)
      final scaffold = result.children.firstWhere((n) => n.name == 'Scaffold', orElse: () => throw 'Scaffold not found');
      expect(scaffold.nestingLevel, 0);

      // AppBar should be at level 1 (inside Scaffold)
      // Text in AppBar's title should be at level 2
      // Center should be at level 1 (inside Scaffold's body)
      // Column should be at level 2 (inside Center)

      // Print all widgets for inspection
      debugPrint('\nAll widgets found:');
      void printAllWidgets(dynamic node, String prefix) {
        if (node.name != 'Root') {
          debugPrint('$prefix${node.name}: nesting=${node.nestingLevel}');
        }
        for (final child in node.children) {
          printAllWidgets(child, '$prefix  ');
        }
      }
      printAllWidgets(result, '');
    });

    test('should correctly handle siblings at same nesting level after complex widgets', () async {
      // This tests the exact scenario from the problem statement:
      // Column with children: [Text('1'), Row(children: [Text('2')]), Text('3')]
      // Text('3') should be a sibling of Row, NOT a child of Row
      const testCode = '''
import 'package:flutter/material.dart';

class TestWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('1'),
        Row(
          children: [
            Text('2'),
          ],
        ),
        Text('3'),
      ],
    );
  }
}
''';

      final result = await parser.parseWidgetTree(testCode, 'test.dart');

      expect(result, isNotNull);
      debugPrint('\n=== Testing siblings at same nesting level ===');

      // Find the Column
      final column = result!.children.firstWhere(
        (n) => n.name == 'Column',
        orElse: () => throw 'Column not found',
      );

      // Column should have 3 children: Text('1'), Row, Text('3')
      expect(column.children.length, 3, reason: 'Column should have exactly 3 children');

      // Verify the structure
      expect(column.children[0].name, 'Text', reason: 'First child should be Text');
      expect(column.children[1].name, 'Row', reason: 'Second child should be Row');
      expect(column.children[2].name, 'Text', reason: 'Third child should be Text (NOT child of Row)');

      // Verify Row has one child
      final row = column.children[1];
      expect(row.children.length, 1, reason: 'Row should have exactly 1 child');
      expect(row.children[0].name, 'Text', reason: 'Row child should be Text');

      debugPrint('✅ PASS: Text(\'3\') is correctly a sibling of Row, not a child!');
      debugPrint('Column structure:');
      debugPrint('  ├── Text (\'1\')');
      debugPrint('  ├── Row');
      debugPrint('  │   └── Text (\'2\')');
      debugPrint('  └── Text (\'3\')   ← Correctly positioned as sibling of Row');
    });
  });
}
