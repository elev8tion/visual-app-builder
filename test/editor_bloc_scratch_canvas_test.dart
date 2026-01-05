import 'package:flutter_test/flutter_test.dart';
import 'package:visual_app_builder/bloc/editor/editor_bloc.dart';

void main() {
  group('EditorBloc Scratch Canvas', () {
    late EditorBloc bloc;

    setUp(() {
      bloc = EditorBloc();
    });

    tearDown(() {
      bloc.close();
    });

    test('InitializeScratchCanvas should create scratch canvas with widgets', () async {
      // Wait for the bloc to be ready
      await Future.delayed(const Duration(milliseconds: 500));

      // Dispatch InitializeScratchCanvas
      bloc.add(const InitializeScratchCanvas());

      // Wait for state to update
      await Future.delayed(const Duration(milliseconds: 1000));

      // Get current state
      final currentState = bloc.state;

      print('State type: ${currentState.runtimeType}');

      if (currentState is EditorLoaded) {
        print('isScratchCanvas: ${currentState.isScratchCanvas}');
        print('projectName: ${currentState.projectName}');
        print('currentFile: ${currentState.currentFile}');
        print('astWidgetTree: ${currentState.astWidgetTree}');
        print('widgetTree length: ${currentState.widgetTree.length}');

        if (currentState.astWidgetTree != null) {
          print('AST Root: ${currentState.astWidgetTree!.name}');
          print('AST Children: ${currentState.astWidgetTree!.children.length}');

          void printTree(dynamic node, int depth) {
            final indent = '  ' * depth;
            print('$indent${node.name} (children: ${node.children.length})');
            for (final child in node.children) {
              printTree(child, depth + 1);
            }
          }
          printTree(currentState.astWidgetTree!, 0);
        }

        // Verify scratch canvas is initialized
        expect(currentState.isScratchCanvas, isTrue);
        expect(currentState.projectName, 'Scratch Canvas');
        expect(currentState.currentFile, '/scratch/lib/main.dart');

        // Verify AST tree was parsed
        expect(currentState.astWidgetTree, isNotNull);
        expect(currentState.astWidgetTree!.children, isNotEmpty);
      } else {
        fail('Expected EditorLoaded state but got ${currentState.runtimeType}');
      }
    });

    test('DropComponent on empty canvas should initialize scratch canvas', () async {
      // Wait for the bloc to be ready
      await Future.delayed(const Duration(milliseconds: 500));

      // Dispatch DropComponent without a project loaded
      bloc.add(const DropComponent(
        componentId: 'text',
        targetWidgetId: 'root',
        dropPosition: 'inside',
        initialProperties: {'text': 'Hello World'},
      ));

      // Wait for state to update
      await Future.delayed(const Duration(milliseconds: 1500));

      // Get current state
      final currentState = bloc.state;

      print('\n--- After DropComponent ---');
      print('State type: ${currentState.runtimeType}');

      if (currentState is EditorLoaded) {
        print('isScratchCanvas: ${currentState.isScratchCanvas}');
        print('projectName: ${currentState.projectName}');
        print('currentFile: ${currentState.currentFile}');
        print('currentFileContent length: ${currentState.currentFileContent?.length ?? 0}');

        if (currentState.astWidgetTree != null) {
          print('AST Root: ${currentState.astWidgetTree!.name}');
          print('AST Children: ${currentState.astWidgetTree!.children.length}');
        }

        // Scratch canvas should be initialized
        expect(currentState.isScratchCanvas, isTrue);
      }
    });
  });
}
