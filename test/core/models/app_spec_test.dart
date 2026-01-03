import 'package:flutter_test/flutter_test.dart';
import 'package:visual_app_builder/core/models/app_spec.dart';

void main() {
  group('AppSpec', () {
    test('should create from JSON', () {
      final json = {
        'name': 'test_app',
        'description': 'A test application',
        'screens': [
          {
            'name': 'HomeScreen',
            'description': 'Main dashboard',
            'route': '/home',
            'type': 'dashboard',
            'widgets': [],
          },
        ],
        'models': [
          {
            'name': 'User',
            'description': 'User model',
            'fields': [
              {'name': 'id', 'type': 'string', 'required': true},
              {'name': 'email', 'type': 'string', 'required': true},
            ],
          },
        ],
        'theme': {
          'primaryColor': '#6200EE',
          'secondaryColor': '#03DAC6',
        },
      };

      final appSpec = AppSpec.fromJson(json);

      expect(appSpec.name, equals('test_app'));
      expect(appSpec.description, equals('A test application'));
      expect(appSpec.screens.length, equals(1));
      expect(appSpec.models.length, equals(1));
    });

    test('should convert to JSON', () {
      final appSpec = AppSpec(
        name: 'test_app',
        description: 'Test app',
        screens: [
          ScreenSpec(
            name: 'HomeScreen',
            description: 'Home screen',
            route: '/home',
            type: ScreenType.dashboard,
          ),
        ],
        models: [],
      );

      final json = appSpec.toJson();

      expect(json['name'], equals('test_app'));
      expect(json['description'], equals('Test app'));
      expect(json['screens'], isA<List>());
    });

    test('should support copyWith', () {
      final original = AppSpec(
        name: 'original',
        description: 'Original app',
      );

      final copied = original.copyWith(name: 'copied');

      expect(copied.name, equals('copied'));
      expect(copied.description, equals('Original app'));
    });
  });

  group('ScreenSpec', () {
    test('should create from JSON', () {
      final json = {
        'name': 'LoginScreen',
        'description': 'User login screen',
        'route': '/login',
        'type': 'form',
        'widgets': [
          {
            'type': 'TextField',
            'properties': {'label': 'Email'},
          },
        ],
      };

      final screenSpec = ScreenSpec.fromJson(json);

      expect(screenSpec.name, equals('LoginScreen'));
      expect(screenSpec.type, equals(ScreenType.form));
      expect(screenSpec.widgets.length, equals(1));
    });

    test('should handle all screen types', () {
      for (final type in ScreenType.values) {
        final screen = ScreenSpec(
          name: 'TestScreen',
          description: 'Test screen',
          route: '/test',
          type: type,
        );
        expect(screen.type, equals(type));
      }
    });

    test('should convert to JSON', () {
      final screen = ScreenSpec(
        name: 'TestScreen',
        description: 'Test',
        route: '/test',
        type: ScreenType.regular,
      );

      final json = screen.toJson();

      expect(json['name'], equals('TestScreen'));
      expect(json['route'], equals('/test'));
      expect(json['type'], equals('regular'));
    });
  });

  group('ModelSpec', () {
    test('should create from JSON', () {
      final json = {
        'name': 'Product',
        'description': 'Product model',
        'fields': [
          {'name': 'id', 'type': 'string', 'required': true},
          {'name': 'name', 'type': 'string', 'required': true},
          {'name': 'price', 'type': 'double', 'required': true},
          {'name': 'description', 'type': 'string', 'required': false},
        ],
      };

      final modelSpec = ModelSpec.fromJson(json);

      expect(modelSpec.name, equals('Product'));
      expect(modelSpec.fields.length, equals(4));
      expect(modelSpec.fields[0].name, equals('id'));
      expect(modelSpec.fields[0].required, isTrue);
    });

    test('should convert to JSON', () {
      final modelSpec = ModelSpec(
        name: 'User',
        description: 'User model',
        fields: [
          FieldSpec(name: 'id', type: FieldType.string, required: true),
          FieldSpec(name: 'age', type: FieldType.int, required: false),
        ],
      );

      final json = modelSpec.toJson();

      expect(json['name'], equals('User'));
      expect(json['fields'], isA<List>());
      expect(json['fields'].length, equals(2));
    });

    test('should generate Dart class code', () {
      final modelSpec = ModelSpec(
        name: 'User',
        description: 'User model',
        fields: [
          FieldSpec(name: 'id', type: FieldType.string, required: true),
          FieldSpec(name: 'name', type: FieldType.string, required: true),
        ],
      );

      final dartCode = modelSpec.toDartClass();

      expect(dartCode, contains('class User'));
      expect(dartCode, contains('final String id'));
      expect(dartCode, contains('final String name'));
      expect(dartCode, contains('fromJson'));
      expect(dartCode, contains('toJson'));
    });
  });

  group('FieldSpec', () {
    test('should create from JSON', () {
      final json = {
        'name': 'email',
        'type': 'string',
        'required': true,
        'defaultValue': 'test@example.com',
      };

      final fieldSpec = FieldSpec.fromJson(json);

      expect(fieldSpec.name, equals('email'));
      expect(fieldSpec.type, equals(FieldType.string));
      expect(fieldSpec.required, isTrue);
      expect(fieldSpec.defaultValue, equals('test@example.com'));
    });

    test('should handle all field types', () {
      for (final type in FieldType.values) {
        final field = FieldSpec(
          name: 'testField',
          type: type,
        );
        expect(field.type, equals(type));
      }
    });

    test('should return correct Dart types', () {
      expect(FieldSpec(name: 'f', type: FieldType.string).dartType, equals('String'));
      expect(FieldSpec(name: 'f', type: FieldType.int).dartType, equals('int'));
      expect(FieldSpec(name: 'f', type: FieldType.double).dartType, equals('double'));
      expect(FieldSpec(name: 'f', type: FieldType.bool).dartType, equals('bool'));
      expect(FieldSpec(name: 'f', type: FieldType.datetime).dartType, equals('DateTime'));
      expect(FieldSpec(name: 'f', type: FieldType.list).dartType, equals('List<dynamic>'));
      expect(FieldSpec(name: 'f', type: FieldType.map).dartType, equals('Map<String, dynamic>'));
    });

    test('should make types nullable when not required', () {
      final field = FieldSpec(name: 'f', type: FieldType.string, required: false);
      expect(field.dartType, equals('String?'));
    });
  });

  group('WidgetSpec', () {
    test('should create from JSON', () {
      final json = {
        'type': 'Button',
        'name': 'submitBtn',
        'properties': {
          'text': 'Submit',
          'color': '#6200EE',
        },
        'children': [],
      };

      final widgetSpec = WidgetSpec.fromJson(json);

      expect(widgetSpec.type, equals('Button'));
      expect(widgetSpec.name, equals('submitBtn'));
      expect(widgetSpec.properties['text'], equals('Submit'));
    });

    test('should handle nested children', () {
      final json = <String, dynamic>{
        'type': 'Column',
        'children': <Map<String, dynamic>>[
          <String, dynamic>{'type': 'Text', 'properties': <String, dynamic>{}},
          <String, dynamic>{'type': 'Button', 'properties': <String, dynamic>{}},
        ],
      };

      final widgetSpec = WidgetSpec.fromJson(json);

      expect(widgetSpec.children.length, equals(2));
      expect(widgetSpec.children[0].type, equals('Text'));
    });
  });

  group('ActionSpec', () {
    test('should create navigation action', () {
      final action = ActionSpec(
        name: 'goToDetails',
        type: ActionType.navigate,
        targetScreen: 'DetailsScreen',
      );

      expect(action.type, equals(ActionType.navigate));
      expect(action.targetScreen, equals('DetailsScreen'));
    });

    test('should create API call action', () {
      final action = ActionSpec(
        name: 'fetchUsers',
        type: ActionType.apiCall,
        apiEndpoint: '/api/users',
        parameters: {'method': 'GET'},
      );

      expect(action.type, equals(ActionType.apiCall));
      expect(action.apiEndpoint, equals('/api/users'));
      expect(action.parameters['method'], equals('GET'));
    });

    test('should handle all action types', () {
      for (final type in ActionType.values) {
        final action = ActionSpec(name: 'test', type: type);
        expect(action.type, equals(type));
      }
    });
  });

  group('ThemeSpec', () {
    test('should create from JSON', () {
      final json = {
        'primaryColor': '#6200EE',
        'secondaryColor': '#03DAC6',
        'fontFamily': 'Roboto',
        'useMaterial3': true,
      };

      final themeSpec = ThemeSpec.fromJson(json);

      expect(themeSpec.primaryColor, equals('#6200EE'));
      expect(themeSpec.secondaryColor, equals('#03DAC6'));
      expect(themeSpec.fontFamily, equals('Roboto'));
      expect(themeSpec.useMaterial3, isTrue);
    });

    test('should have default values', () {
      final themeSpec = ThemeSpec();

      expect(themeSpec.primaryColor, isNotNull);
      expect(themeSpec.useMaterial3, isTrue);
      expect(themeSpec.fontFamily, equals('Roboto'));
    });
  });

  group('GenerationProgress', () {
    test('should create with required fields', () {
      final progress = GenerationProgress(
        phase: GenerationPhase.parsing,
        progress: 0.5,
        message: 'Parsing prompt...',
      );

      expect(progress.phase, equals(GenerationPhase.parsing));
      expect(progress.progress, equals(0.5));
      expect(progress.message, equals('Parsing prompt...'));
    });

    test('should handle all generation phases', () {
      for (final phase in GenerationPhase.values) {
        final progress = GenerationProgress(
          phase: phase,
          progress: 0.0,
          message: 'Test',
        );
        expect(progress.phase, equals(phase));
      }
    });

    test('should track generated files', () {
      final progress = GenerationProgress(
        phase: GenerationPhase.writingFiles,
        progress: 0.8,
        message: 'Writing files',
        generatedFile: 'lib/main.dart',
      );

      expect(progress.generatedFile, equals('lib/main.dart'));
    });

    test('should track errors', () {
      final progress = GenerationProgress(
        phase: GenerationPhase.error,
        progress: 0.0,
        message: 'Generation failed',
        error: 'API error',
      );

      expect(progress.error, equals('API error'));
    });
  });

  group('NavigationSpec', () {
    test('should create from JSON', () {
      final json = {
        'type': 'bottomNav',
        'items': [
          {'label': 'Home', 'icon': 'home', 'route': '/home'},
          {'label': 'Profile', 'icon': 'person', 'route': '/profile'},
        ],
      };

      final navSpec = NavigationSpec.fromJson(json);

      expect(navSpec.type, equals(NavigationType.bottomNav));
      expect(navSpec.items.length, equals(2));
    });

    test('should handle all navigation types', () {
      for (final type in NavigationType.values) {
        final nav = NavigationSpec(type: type, items: []);
        expect(nav.type, equals(type));
      }
    });
  });

  group('NavItemSpec', () {
    test('should create from JSON', () {
      final json = {
        'label': 'Home',
        'icon': 'home',
        'route': '/home',
      };

      final item = NavItemSpec.fromJson(json);

      expect(item.label, equals('Home'));
      expect(item.icon, equals('home'));
      expect(item.route, equals('/home'));
    });
  });

  group('ValidationRule', () {
    test('should create from JSON', () {
      final json = {
        'type': 'minLength',
        'value': 8,
        'message': 'Must be at least 8 characters',
      };

      final rule = ValidationRule.fromJson(json);

      expect(rule.type, equals(ValidationType.minLength));
      expect(rule.value, equals(8));
      expect(rule.message, equals('Must be at least 8 characters'));
    });

    test('should handle all validation types', () {
      for (final type in ValidationType.values) {
        final rule = ValidationRule(type: type, message: 'Test');
        expect(rule.type, equals(type));
      }
    });
  });
}
