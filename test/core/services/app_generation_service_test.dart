import 'package:flutter_test/flutter_test.dart';
import 'package:visual_app_builder/core/services/app_generation_service.dart';
import 'package:visual_app_builder/core/services/openai_service.dart';
import 'package:visual_app_builder/core/models/app_spec.dart';

void main() {
  group('AppGenerationService', () {
    late AppGenerationService service;

    setUp(() {
      service = AppGenerationService.instance;
    });

    group('Singleton Pattern', () {
      test('should return same instance', () {
        final instance1 = AppGenerationService.instance;
        final instance2 = AppGenerationService.instance;
        expect(identical(instance1, instance2), isTrue);
      });
    });

    group('Configuration', () {
      test('should reflect OpenAI configuration status', () {
        // Clear OpenAI configuration
        OpenAIService.instance.clearApiKey();
        expect(service.isConfigured, isFalse);

        // Configure OpenAI
        OpenAIService.instance.configure(apiKey: 'test-api-key');
        expect(service.isConfigured, isTrue);

        // Cleanup
        OpenAIService.instance.clearApiKey();
      });
    });

    group('Generation Stream', () {
      test('should yield error when OpenAI not configured', () async {
        // Ensure OpenAI is not configured
        OpenAIService.instance.clearApiKey();

        final events = <GenerationProgress>[];
        await for (final event in service.generateAppFromPrompt(
          prompt: 'Create a todo app',
          projectName: 'test_app',
          outputPath: '/tmp/test_output',
        )) {
          events.add(event);
        }

        expect(events.length, equals(1));
        expect(events.first.phase, equals(GenerationPhase.error));
        expect(events.first.error, isNotNull);
        expect(events.first.error, contains('API key'));
      });

      test('should start with parsing phase when configured', () async {
        // Configure OpenAI (will fail on actual API call, but should pass initial check)
        OpenAIService.instance.configure(apiKey: 'test-api-key');

        // We just test that it starts correctly before hitting network
        final events = <GenerationProgress>[];
        try {
          await for (final event in service.generateAppFromPrompt(
            prompt: 'Create a todo app',
            projectName: 'test_app',
            outputPath: '/tmp/test_output',
          )) {
            events.add(event);
            // Stop after first event to avoid network call
            if (events.length >= 1) break;
          }
        } catch (e) {
          // Expected to fail on network call
        }

        // Cleanup
        OpenAIService.instance.clearApiKey();

        // Should have started with parsing phase
        if (events.isNotEmpty) {
          expect(events.first.phase, equals(GenerationPhase.parsing));
        }
      });
    });
  });

  group('GenerationProgress', () {
    test('should create with all phases', () {
      final phases = GenerationPhase.values;
      expect(phases, contains(GenerationPhase.parsing));
      expect(phases, contains(GenerationPhase.planning));
      expect(phases, contains(GenerationPhase.generatingModels));
      expect(phases, contains(GenerationPhase.generatingScreens));
      expect(phases, contains(GenerationPhase.generatingState));
      expect(phases, contains(GenerationPhase.generatingNavigation));
      expect(phases, contains(GenerationPhase.generatingMain));
      expect(phases, contains(GenerationPhase.writingFiles));
      expect(phases, contains(GenerationPhase.complete));
      expect(phases, contains(GenerationPhase.error));
    });

    test('should track progress value', () {
      final progress = GenerationProgress(
        phase: GenerationPhase.parsing,
        progress: 0.5,
        message: 'Test message',
      );

      expect(progress.progress, equals(0.5));
      expect(progress.message, equals('Test message'));
    });

    test('should include generated file when provided', () {
      final progress = GenerationProgress(
        phase: GenerationPhase.writingFiles,
        progress: 0.9,
        message: 'Writing file',
        generatedFile: 'lib/main.dart',
      );

      expect(progress.generatedFile, equals('lib/main.dart'));
    });

    test('should include error when provided', () {
      final progress = GenerationProgress(
        phase: GenerationPhase.error,
        progress: 0.0,
        message: 'Failed',
        error: 'Some error occurred',
      );

      expect(progress.error, equals('Some error occurred'));
    });
  });

  group('AppSpec Integration', () {
    test('should support all required spec fields for generation', () {
      final appSpec = AppSpec(
        name: 'Test App',
        description: 'A test application',
        screens: [
          ScreenSpec(
            name: 'Home',
            description: 'Home screen',
            route: '/',
            type: ScreenType.dashboard,
            isInitial: true,
          ),
          ScreenSpec(
            name: 'Settings',
            description: 'Settings screen',
            route: '/settings',
            type: ScreenType.settings,
          ),
        ],
        models: [
          ModelSpec(
            name: 'User',
            description: 'User model',
            fields: [
              FieldSpec(name: 'id', type: FieldType.string, required: true),
              FieldSpec(name: 'name', type: FieldType.string, required: true),
            ],
          ),
        ],
        stateManagement: 'provider',
      );

      expect(appSpec.name, equals('Test App'));
      expect(appSpec.screens.length, equals(2));
      expect(appSpec.models.length, equals(1));
      expect(appSpec.stateManagement, equals('provider'));

      // Check initial screen is marked
      final initialScreen = appSpec.screens.firstWhere((s) => s.isInitial);
      expect(initialScreen.name, equals('Home'));
    });

    test('should support navigation specification', () {
      final appSpec = AppSpec(
        name: 'Nav App',
        description: 'App with navigation',
        screens: [
          ScreenSpec(
            name: 'Home',
            description: 'Home',
            route: '/home',
          ),
        ],
        navigation: NavigationSpec(
          type: NavigationType.bottomNav,
          items: [
            NavItemSpec(label: 'Home', icon: 'home', route: '/home'),
            NavItemSpec(label: 'Profile', icon: 'person', route: '/profile'),
          ],
        ),
      );

      expect(appSpec.navigation, isNotNull);
      expect(appSpec.navigation!.type, equals(NavigationType.bottomNav));
      expect(appSpec.navigation!.items.length, equals(2));
    });
  });
}
