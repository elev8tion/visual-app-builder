import 'package:flutter_test/flutter_test.dart';
import 'package:visual_app_builder/core/templates/project_templates.dart';

void main() {
  group('ProjectTemplates', () {
    group('Template Retrieval', () {
      test('should return template config for all template types', () {
        for (final template in ProjectTemplate.values) {
          final config = ProjectTemplates.getTemplate(template);
          expect(config, isNotNull, reason: 'Template config for ${template.name} should not be null');
        }
      });

      test('should have required fields for each template', () {
        for (final template in ProjectTemplate.values) {
          final config = ProjectTemplates.getTemplate(template);
          expect(config!.name, isNotEmpty);
          expect(config.description, isNotEmpty);
          expect(config.icon, isNotEmpty);
        }
      });
    });

    group('Blank Template', () {
      test('should have minimal configuration', () {
        final config = ProjectTemplates.getTemplate(ProjectTemplate.blank);
        expect(config, isNotNull);
        expect(config!.name, equals('Blank'));
      });
    });

    group('Counter Template', () {
      test('should have counter-specific files', () {
        final config = ProjectTemplates.getTemplate(ProjectTemplate.counter);
        expect(config, isNotNull);
        expect(config!.name, equals('Counter'));
        expect(config.fileTemplates, isNotEmpty);
      });
    });

    group('Todo Template', () {
      test('should have todo-specific configuration', () {
        final config = ProjectTemplates.getTemplate(ProjectTemplate.todo);
        expect(config, isNotNull);
        expect(config!.name, equals('Todo List'));
        expect(config.fileTemplates, isNotEmpty);
      });
    });

    group('Ecommerce Template', () {
      test('should have ecommerce-specific screens', () {
        final config = ProjectTemplates.getTemplate(ProjectTemplate.ecommerce);
        expect(config, isNotNull);
        expect(config!.name, equals('E-Commerce'));
      });
    });

    group('Social Template', () {
      test('should have social-specific features', () {
        final config = ProjectTemplates.getTemplate(ProjectTemplate.social);
        expect(config, isNotNull);
        expect(config!.name, equals('Social Feed'));
      });
    });

    group('Dashboard Template', () {
      test('should have dashboard-specific widgets', () {
        final config = ProjectTemplates.getTemplate(ProjectTemplate.dashboard);
        expect(config, isNotNull);
        expect(config!.name, equals('Dashboard'));
      });
    });
  });

  group('StateManagement', () {
    test('should have all expected state management options', () {
      expect(StateManagement.values, contains(StateManagement.none));
      expect(StateManagement.values, contains(StateManagement.provider));
      expect(StateManagement.values, contains(StateManagement.riverpod));
      expect(StateManagement.values, contains(StateManagement.bloc));
      expect(StateManagement.values, contains(StateManagement.getx));
    });
  });

  group('ProjectTemplate', () {
    test('should have all expected template types', () {
      expect(ProjectTemplate.values, contains(ProjectTemplate.blank));
      expect(ProjectTemplate.values, contains(ProjectTemplate.counter));
      expect(ProjectTemplate.values, contains(ProjectTemplate.todo));
      expect(ProjectTemplate.values, contains(ProjectTemplate.ecommerce));
      expect(ProjectTemplate.values, contains(ProjectTemplate.social));
      expect(ProjectTemplate.values, contains(ProjectTemplate.dashboard));
    });
  });

  group('ProjectTemplateConfig', () {
    test('should create with required fields', () {
      final config = ProjectTemplateConfig(
        template: ProjectTemplate.blank,
        name: 'Test Template',
        description: 'A test template',
        icon: '🧪',
        features: ['Feature 1', 'Feature 2'],
        dependencies: ['test_dep: ^1.0.0'],
        fileTemplates: {'lib/main.dart': 'void main() {}'},
        defaultStateManagement: StateManagement.none,
      );

      expect(config.name, equals('Test Template'));
      expect(config.description, equals('A test template'));
      expect(config.icon, equals('🧪'));
      expect(config.features, contains('Feature 1'));
      expect(config.dependencies, contains('test_dep: ^1.0.0'));
      expect(config.fileTemplates.containsKey('lib/main.dart'), isTrue);
      expect(config.defaultStateManagement, equals(StateManagement.none));
    });
  });

  group('StateManagementExtension', () {
    test('should have display names', () {
      expect(StateManagement.none.displayName, equals('None'));
      expect(StateManagement.provider.displayName, equals('Provider'));
      expect(StateManagement.riverpod.displayName, equals('Riverpod'));
      expect(StateManagement.bloc.displayName, equals('BLoC'));
      expect(StateManagement.getx.displayName, equals('GetX'));
    });

    test('should have dependencies', () {
      expect(StateManagement.none.dependencies, isEmpty);
      expect(StateManagement.provider.dependencies, isNotEmpty);
      expect(StateManagement.riverpod.dependencies.length, equals(2));
      expect(StateManagement.bloc.dependencies.length, equals(2));
      expect(StateManagement.getx.dependencies, isNotEmpty);
    });
  });
}
