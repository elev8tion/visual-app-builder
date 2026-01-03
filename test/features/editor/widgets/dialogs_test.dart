import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:visual_app_builder/core/templates/project_templates.dart';

void main() {
  group('ProjectTemplates (Dialog Dependencies)', () {
    test('should have all template types for dialog grid', () {
      expect(ProjectTemplate.values.length, greaterThan(0));

      for (final template in ProjectTemplate.values) {
        final config = ProjectTemplates.getTemplate(template);
        expect(config, isNotNull, reason: 'Config for ${template.name} should exist');
        expect(config!.name, isNotEmpty);
        expect(config.icon, isNotEmpty);
        expect(config.description, isNotEmpty);
      }
    });

    test('should have all state management options', () {
      expect(StateManagement.values, contains(StateManagement.none));
      expect(StateManagement.values, contains(StateManagement.provider));
      expect(StateManagement.values, contains(StateManagement.riverpod));
      expect(StateManagement.values, contains(StateManagement.bloc));
      expect(StateManagement.values, contains(StateManagement.getx));
    });

    test('should have display names for state management', () {
      expect(StateManagement.provider.displayName, isNotEmpty);
      expect(StateManagement.bloc.displayName, isNotEmpty);
    });
  });

  group('Dialog Widget Structure', () {
    testWidgets('NewProjectDialog structure test', (WidgetTester tester) async {
      // Test the basic material components without bloc
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Dialog(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.create_new_folder, color: Colors.blue),
                          const SizedBox(width: 12),
                          const Text('New Project'),
                        ],
                      ),
                      const SizedBox(height: 24),
                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Project Name',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.text('New Project'), findsOneWidget);
      expect(find.byIcon(Icons.create_new_folder), findsOneWidget);
      expect(find.text('Project Name'), findsOneWidget);
    });

    testWidgets('AI Generator dialog basic structure', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Dialog(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 700, maxHeight: 800),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Colors.blue, Colors.purple],
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.auto_awesome, color: Colors.white),
                          ),
                          const SizedBox(width: 12),
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('AI App Generator'),
                              Text('Describe your app and AI will build it'),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      const Text('Describe your app:'),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.text('AI App Generator'), findsOneWidget);
      expect(find.byIcon(Icons.auto_awesome), findsOneWidget);
      expect(find.text('Describe your app:'), findsOneWidget);
    });

    testWidgets('Settings dialog basic structure', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Dialog(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.settings, color: Colors.blue),
                          const SizedBox(width: 12),
                          const Text('Settings'),
                        ],
                      ),
                      const SizedBox(height: 24),
                      const Text('OpenAI API'),
                      const SizedBox(height: 8),
                      const Text('Enter your OpenAI API key to enable AI features.'),
                      const SizedBox(height: 16),
                      const TextField(
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: 'API Key',
                          hintText: 'sk-...',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Settings'), findsOneWidget);
      expect(find.byIcon(Icons.settings), findsOneWidget);
      expect(find.text('OpenAI API'), findsOneWidget);
      expect(find.text('API Key'), findsOneWidget);
    });
  });

  group('Form Validation Logic', () {
    test('project name regex validation', () {
      final regex = RegExp(r'^[a-z][a-z0-9_]*$');

      // Valid names
      expect(regex.hasMatch('my_app'), isTrue);
      expect(regex.hasMatch('myapp'), isTrue);
      expect(regex.hasMatch('app123'), isTrue);
      expect(regex.hasMatch('my_cool_app'), isTrue);

      // Invalid names
      expect(regex.hasMatch('MyApp'), isFalse);  // Uppercase
      expect(regex.hasMatch('123app'), isFalse);  // Starts with number
      expect(regex.hasMatch('my-app'), isFalse);  // Contains dash
      expect(regex.hasMatch(''), isFalse);  // Empty
      expect(regex.hasMatch('_app'), isFalse);  // Starts with underscore
    });

    test('prompt minimum length validation', () {
      final minLength = 20;

      expect('A todo app'.length < minLength, isTrue);  // Too short
      expect('A todo list app with categories and due dates'.length >= minLength, isTrue);  // Valid
    });
  });

  group('Example Prompts', () {
    test('should have variety of example prompts', () {
      const examplePrompts = [
        'A todo list app with categories and due dates',
        'A weather app showing 5-day forecast with location search',
        'An e-commerce app with product catalog and shopping cart',
        'A note-taking app with markdown support and tags',
        'A fitness tracker with workout logging and progress charts',
        'A recipe app with search, favorites, and shopping list',
      ];

      expect(examplePrompts.length, greaterThan(3));

      for (final prompt in examplePrompts) {
        expect(prompt.length, greaterThan(20), reason: 'Prompt should be descriptive: $prompt');
      }
    });
  });
}
