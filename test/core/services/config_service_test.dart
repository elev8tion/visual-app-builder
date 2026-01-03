import 'package:flutter_test/flutter_test.dart';
import 'package:visual_app_builder/core/services/config_service.dart';

void main() {
  group('ConfigService', () {
    late ConfigService service;

    setUp(() {
      service = ConfigService.instance;
    });

    group('Singleton Pattern', () {
      test('should return same instance', () {
        final instance1 = ConfigService.instance;
        final instance2 = ConfigService.instance;
        expect(identical(instance1, instance2), isTrue);
      });
    });

    group('OpenAI API Key', () {
      test('should return null when no key is set', () async {
        await service.clearOpenAIKey();
        final key = await service.getOpenAIKey();
        expect(key, isNull);
      });

      test('should save and retrieve API key', () async {
        const testKey = 'sk-test-key-12345';
        await service.setOpenAIKey(testKey);
        final retrievedKey = await service.getOpenAIKey();
        expect(retrievedKey, equals(testKey));
      });

      test('should clear API key', () async {
        await service.setOpenAIKey('sk-test-key');
        await service.clearOpenAIKey();
        final key = await service.getOpenAIKey();
        expect(key, isNull);
      });

      test('should check if OpenAI is configured', () async {
        await service.clearOpenAIKey();
        expect(await service.isOpenAIConfigured(), isFalse);

        await service.setOpenAIKey('sk-test-key');
        expect(await service.isOpenAIConfigured(), isTrue);
      });
    });

    group('Default Project Path', () {
      test('should return null initially', () async {
        await service.clearAll();
        final path = await service.getDefaultProjectPath();
        expect(path, isNull);
      });

      test('should save and retrieve default project path', () async {
        const testPath = '/test/projects';
        await service.setDefaultProjectPath(testPath);
        final retrievedPath = await service.getDefaultProjectPath();
        expect(retrievedPath, equals(testPath));
      });
    });

    group('Recent Projects', () {
      test('should return empty list initially', () async {
        await service.clearAll();
        final projects = await service.getRecentProjects();
        expect(projects, isEmpty);
      });

      test('should add project to recent list', () async {
        await service.clearAll();
        await service.addRecentProject('/path/to/project');
        final projects = await service.getRecentProjects();
        expect(projects, contains('/path/to/project'));
      });

      test('should not duplicate projects', () async {
        await service.clearAll();
        await service.addRecentProject('/path/to/project');
        await service.addRecentProject('/path/to/project');
        final projects = await service.getRecentProjects();
        final count = projects.where((p) => p == '/path/to/project').length;
        expect(count, equals(1));
      });

      test('should limit recent projects to 10', () async {
        await service.clearAll();
        // Add more than 10 projects
        for (int i = 0; i < 15; i++) {
          await service.addRecentProject('/path/to/project$i');
        }
        final projects = await service.getRecentProjects();
        expect(projects.length, lessThanOrEqualTo(10));
      });

      test('should put most recent project first', () async {
        await service.clearAll();
        await service.addRecentProject('/first');
        await service.addRecentProject('/second');
        final projects = await service.getRecentProjects();
        expect(projects.first, equals('/second'));
      });
    });

    group('OpenAI Model', () {
      test('should return default model when not set', () async {
        await service.clearAll();
        final model = await service.getOpenAIModel();
        expect(model, equals('gpt-4-turbo-preview'));
      });

      test('should save and retrieve custom model', () async {
        await service.setOpenAIModel('gpt-3.5-turbo');
        final model = await service.getOpenAIModel();
        expect(model, equals('gpt-3.5-turbo'));
      });
    });

    group('Editor Settings', () {
      test('should return default theme', () async {
        await service.clearAll();
        final theme = await service.getEditorTheme();
        expect(theme, equals('dark'));
      });

      test('should return default font size', () async {
        await service.clearAll();
        final fontSize = await service.getFontSize();
        expect(fontSize, equals(14.0));
      });

      test('should return default auto-save enabled', () async {
        await service.clearAll();
        final autoSave = await service.getAutoSaveEnabled();
        expect(autoSave, isTrue);
      });
    });

    group('Generation Settings', () {
      test('should return default state management', () async {
        await service.clearAll();
        final sm = await service.getPreferredStateManagement();
        expect(sm, equals('provider'));
      });

      test('should return default organization', () async {
        await service.clearAll();
        final org = await service.getOrganization();
        expect(org, equals('com.example'));
      });
    });

    group('Generic Settings', () {
      test('should set and get custom values', () async {
        await service.set('custom_key', 'custom_value');
        final value = await service.get<String>('custom_key');
        expect(value, equals('custom_value'));
      });

      test('should remove settings', () async {
        await service.set('temp_key', 'temp_value');
        await service.remove('temp_key');
        final value = await service.get<String>('temp_key');
        expect(value, isNull);
      });
    });
  });
}
