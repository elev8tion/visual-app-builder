// App Specification Models
//
// Models for AI-powered app generation. These represent the structure
// of an app as parsed from natural language prompts.

/// Complete app specification
class AppSpec {
  final String name;
  final String description;
  final List<ScreenSpec> screens;
  final List<ModelSpec> models;
  final List<String> features;
  final String stateManagement;
  final ThemeSpec? theme;
  final NavigationSpec? navigation;

  const AppSpec({
    required this.name,
    required this.description,
    this.screens = const [],
    this.models = const [],
    this.features = const [],
    this.stateManagement = 'provider',
    this.theme,
    this.navigation,
  });

  factory AppSpec.fromJson(Map<String, dynamic> json) {
    return AppSpec(
      name: json['name'] as String? ?? 'MyApp',
      description: json['description'] as String? ?? '',
      screens: (json['screens'] as List<dynamic>?)
              ?.map((s) => ScreenSpec.fromJson(s as Map<String, dynamic>))
              .toList() ??
          [],
      models: (json['models'] as List<dynamic>?)
              ?.map((m) => ModelSpec.fromJson(m as Map<String, dynamic>))
              .toList() ??
          [],
      features: (json['features'] as List<dynamic>?)?.cast<String>() ?? [],
      stateManagement: json['stateManagement'] as String? ?? 'provider',
      theme: json['theme'] != null
          ? ThemeSpec.fromJson(json['theme'] as Map<String, dynamic>)
          : null,
      navigation: json['navigation'] != null
          ? NavigationSpec.fromJson(json['navigation'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'description': description,
        'screens': screens.map((s) => s.toJson()).toList(),
        'models': models.map((m) => m.toJson()).toList(),
        'features': features,
        'stateManagement': stateManagement,
        if (theme != null) 'theme': theme!.toJson(),
        if (navigation != null) 'navigation': navigation!.toJson(),
      };

  AppSpec copyWith({
    String? name,
    String? description,
    List<ScreenSpec>? screens,
    List<ModelSpec>? models,
    List<String>? features,
    String? stateManagement,
    ThemeSpec? theme,
    NavigationSpec? navigation,
  }) {
    return AppSpec(
      name: name ?? this.name,
      description: description ?? this.description,
      screens: screens ?? this.screens,
      models: models ?? this.models,
      features: features ?? this.features,
      stateManagement: stateManagement ?? this.stateManagement,
      theme: theme ?? this.theme,
      navigation: navigation ?? this.navigation,
    );
  }
}

/// Screen specification
class ScreenSpec {
  final String name;
  final String description;
  final String route;
  final ScreenType type;
  final List<WidgetSpec> widgets;
  final List<ActionSpec> actions;
  final bool isInitial;

  const ScreenSpec({
    required this.name,
    required this.description,
    required this.route,
    this.type = ScreenType.regular,
    this.widgets = const [],
    this.actions = const [],
    this.isInitial = false,
  });

  factory ScreenSpec.fromJson(Map<String, dynamic> json) {
    return ScreenSpec(
      name: json['name'] as String? ?? 'Screen',
      description: json['description'] as String? ?? '',
      route: json['route'] as String? ?? '/',
      type: ScreenType.values.firstWhere(
        (t) => t.name == json['type'],
        orElse: () => ScreenType.regular,
      ),
      widgets: (json['widgets'] as List<dynamic>?)
              ?.map((w) => WidgetSpec.fromJson(w as Map<String, dynamic>))
              .toList() ??
          [],
      actions: (json['actions'] as List<dynamic>?)
              ?.map((a) => ActionSpec.fromJson(a as Map<String, dynamic>))
              .toList() ??
          [],
      isInitial: json['isInitial'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'description': description,
        'route': route,
        'type': type.name,
        'widgets': widgets.map((w) => w.toJson()).toList(),
        'actions': actions.map((a) => a.toJson()).toList(),
        'isInitial': isInitial,
      };
}

/// Screen types
enum ScreenType {
  regular,
  list,
  detail,
  form,
  dashboard,
  settings,
  profile,
  auth,
}

/// Widget specification for UI elements
class WidgetSpec {
  final String type;
  final String? name;
  final Map<String, dynamic> properties;
  final List<WidgetSpec> children;

  const WidgetSpec({
    required this.type,
    this.name,
    this.properties = const {},
    this.children = const [],
  });

  factory WidgetSpec.fromJson(Map<String, dynamic> json) {
    return WidgetSpec(
      type: json['type'] as String? ?? 'Container',
      name: json['name'] as String?,
      properties: (json['properties'] as Map<String, dynamic>?) ?? {},
      children: (json['children'] as List<dynamic>?)
              ?.map((c) => WidgetSpec.fromJson(c as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() => {
        'type': type,
        if (name != null) 'name': name,
        'properties': properties,
        'children': children.map((c) => c.toJson()).toList(),
      };
}

/// Action specification for interactions
class ActionSpec {
  final String name;
  final ActionType type;
  final String? targetScreen;
  final String? apiEndpoint;
  final Map<String, dynamic> parameters;

  const ActionSpec({
    required this.name,
    required this.type,
    this.targetScreen,
    this.apiEndpoint,
    this.parameters = const {},
  });

  factory ActionSpec.fromJson(Map<String, dynamic> json) {
    return ActionSpec(
      name: json['name'] as String? ?? 'action',
      type: ActionType.values.firstWhere(
        (t) => t.name == json['type'],
        orElse: () => ActionType.navigate,
      ),
      targetScreen: json['targetScreen'] as String?,
      apiEndpoint: json['apiEndpoint'] as String?,
      parameters: (json['parameters'] as Map<String, dynamic>?) ?? {},
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'type': type.name,
        if (targetScreen != null) 'targetScreen': targetScreen,
        if (apiEndpoint != null) 'apiEndpoint': apiEndpoint,
        'parameters': parameters,
      };
}

/// Action types
enum ActionType {
  navigate,
  submit,
  apiCall,
  stateUpdate,
  dialog,
  snackbar,
}

/// Data model specification
class ModelSpec {
  final String name;
  final String description;
  final List<FieldSpec> fields;
  final List<String> relationships;

  const ModelSpec({
    required this.name,
    required this.description,
    this.fields = const [],
    this.relationships = const [],
  });

  factory ModelSpec.fromJson(Map<String, dynamic> json) {
    return ModelSpec(
      name: json['name'] as String? ?? 'Model',
      description: json['description'] as String? ?? '',
      fields: (json['fields'] as List<dynamic>?)
              ?.map((f) => FieldSpec.fromJson(f as Map<String, dynamic>))
              .toList() ??
          [],
      relationships:
          (json['relationships'] as List<dynamic>?)?.cast<String>() ?? [],
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'description': description,
        'fields': fields.map((f) => f.toJson()).toList(),
        'relationships': relationships,
      };

  /// Generate Dart class code for this model
  String toDartClass() {
    final buffer = StringBuffer();
    final className = _toPascalCase(name);

    buffer.writeln('/// $description');
    buffer.writeln('class $className {');

    // Fields
    for (final field in fields) {
      final dartType = field.dartType;
      final fieldName = _toCamelCase(field.name);
      buffer.writeln('  final $dartType $fieldName;');
    }

    buffer.writeln();

    // Constructor
    buffer.writeln('  const $className({');
    for (final field in fields) {
      final fieldName = _toCamelCase(field.name);
      final required = field.required ? 'required ' : '';
      buffer.writeln('    ${required}this.$fieldName,');
    }
    buffer.writeln('  });');

    buffer.writeln();

    // fromJson factory
    buffer.writeln('  factory $className.fromJson(Map<String, dynamic> json) {');
    buffer.writeln('    return $className(');
    for (final field in fields) {
      final fieldName = _toCamelCase(field.name);
      final jsonKey = field.name;
      final dartType = field.dartType;
      final defaultValue = field.defaultValue ?? _getDefaultForType(dartType);
      buffer.writeln("      $fieldName: json['$jsonKey'] as $dartType? ?? $defaultValue,");
    }
    buffer.writeln('    );');
    buffer.writeln('  }');

    buffer.writeln();

    // toJson method
    buffer.writeln('  Map<String, dynamic> toJson() => {');
    for (final field in fields) {
      final fieldName = _toCamelCase(field.name);
      final jsonKey = field.name;
      buffer.writeln("    '$jsonKey': $fieldName,");
    }
    buffer.writeln('  };');

    buffer.writeln('}');

    return buffer.toString();
  }

  String _toPascalCase(String s) {
    return s.split(RegExp(r'[_\s]+')).map((w) {
      if (w.isEmpty) return w;
      return w[0].toUpperCase() + w.substring(1).toLowerCase();
    }).join();
  }

  String _toCamelCase(String s) {
    final pascal = _toPascalCase(s);
    if (pascal.isEmpty) return pascal;
    return pascal[0].toLowerCase() + pascal.substring(1);
  }

  String _getDefaultForType(String type) {
    if (type == 'String') return "''";
    if (type == 'int') return '0';
    if (type == 'double') return '0.0';
    if (type == 'bool') return 'false';
    if (type.startsWith('List')) return '[]';
    if (type.startsWith('Map')) return '{}';
    return "''";
  }
}

/// Field specification for model fields
class FieldSpec {
  final String name;
  final FieldType type;
  final bool required;
  final dynamic defaultValue;
  final String? description;
  final List<ValidationRule> validations;

  const FieldSpec({
    required this.name,
    required this.type,
    this.required = true,
    this.defaultValue,
    this.description,
    this.validations = const [],
  });

  factory FieldSpec.fromJson(Map<String, dynamic> json) {
    return FieldSpec(
      name: json['name'] as String? ?? 'field',
      type: FieldType.values.firstWhere(
        (t) => t.name == json['type'],
        orElse: () => FieldType.string,
      ),
      required: json['required'] as bool? ?? true,
      defaultValue: json['defaultValue'],
      description: json['description'] as String?,
      validations: (json['validations'] as List<dynamic>?)
              ?.map((v) => ValidationRule.fromJson(v as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'type': type.name,
        'required': required,
        if (defaultValue != null) 'defaultValue': defaultValue,
        if (description != null) 'description': description,
        'validations': validations.map((v) => v.toJson()).toList(),
      };

  /// Get Dart type string for this field
  String get dartType {
    final nullable = required ? '' : '?';
    switch (type) {
      case FieldType.string:
        return 'String$nullable';
      case FieldType.int:
        return 'int$nullable';
      case FieldType.double:
        return 'double$nullable';
      case FieldType.bool:
        return 'bool$nullable';
      case FieldType.datetime:
        return 'DateTime$nullable';
      case FieldType.list:
        return 'List<dynamic>$nullable';
      case FieldType.map:
        return 'Map<String, dynamic>$nullable';
      case FieldType.reference:
        return 'String$nullable'; // Store as ID
    }
  }
}

/// Field types
enum FieldType {
  string,
  int,
  double,
  bool,
  datetime,
  list,
  map,
  reference,
}

/// Validation rule for fields
class ValidationRule {
  final ValidationType type;
  final dynamic value;
  final String message;

  const ValidationRule({
    required this.type,
    this.value,
    required this.message,
  });

  factory ValidationRule.fromJson(Map<String, dynamic> json) {
    return ValidationRule(
      type: ValidationType.values.firstWhere(
        (t) => t.name == json['type'],
        orElse: () => ValidationType.required,
      ),
      value: json['value'],
      message: json['message'] as String? ?? 'Invalid value',
    );
  }

  Map<String, dynamic> toJson() => {
        'type': type.name,
        if (value != null) 'value': value,
        'message': message,
      };
}

/// Validation types
enum ValidationType {
  required,
  minLength,
  maxLength,
  min,
  max,
  email,
  url,
  regex,
  custom,
}

/// Theme specification
class ThemeSpec {
  final String primaryColor;
  final String secondaryColor;
  final String backgroundColor;
  final String textColor;
  final bool useMaterial3;
  final String fontFamily;

  const ThemeSpec({
    this.primaryColor = '#2196F3',
    this.secondaryColor = '#FF9800',
    this.backgroundColor = '#FFFFFF',
    this.textColor = '#000000',
    this.useMaterial3 = true,
    this.fontFamily = 'Roboto',
  });

  factory ThemeSpec.fromJson(Map<String, dynamic> json) {
    return ThemeSpec(
      primaryColor: json['primaryColor'] as String? ?? '#2196F3',
      secondaryColor: json['secondaryColor'] as String? ?? '#FF9800',
      backgroundColor: json['backgroundColor'] as String? ?? '#FFFFFF',
      textColor: json['textColor'] as String? ?? '#000000',
      useMaterial3: json['useMaterial3'] as bool? ?? true,
      fontFamily: json['fontFamily'] as String? ?? 'Roboto',
    );
  }

  Map<String, dynamic> toJson() => {
        'primaryColor': primaryColor,
        'secondaryColor': secondaryColor,
        'backgroundColor': backgroundColor,
        'textColor': textColor,
        'useMaterial3': useMaterial3,
        'fontFamily': fontFamily,
      };
}

/// Navigation specification
class NavigationSpec {
  final NavigationType type;
  final List<NavItemSpec> items;

  const NavigationSpec({
    this.type = NavigationType.stack,
    this.items = const [],
  });

  factory NavigationSpec.fromJson(Map<String, dynamic> json) {
    return NavigationSpec(
      type: NavigationType.values.firstWhere(
        (t) => t.name == json['type'],
        orElse: () => NavigationType.stack,
      ),
      items: (json['items'] as List<dynamic>?)
              ?.map((i) => NavItemSpec.fromJson(i as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() => {
        'type': type.name,
        'items': items.map((i) => i.toJson()).toList(),
      };
}

/// Navigation types
enum NavigationType {
  stack,
  bottomNav,
  drawer,
  tabs,
}

/// Navigation item specification
class NavItemSpec {
  final String label;
  final String icon;
  final String route;

  const NavItemSpec({
    required this.label,
    required this.icon,
    required this.route,
  });

  factory NavItemSpec.fromJson(Map<String, dynamic> json) {
    return NavItemSpec(
      label: json['label'] as String? ?? 'Tab',
      icon: json['icon'] as String? ?? 'home',
      route: json['route'] as String? ?? '/',
    );
  }

  Map<String, dynamic> toJson() => {
        'label': label,
        'icon': icon,
        'route': route,
      };
}

/// Generation progress event
class GenerationProgress {
  final GenerationPhase phase;
  final double progress;
  final String message;
  final String? generatedFile;
  final String? error;

  const GenerationProgress({
    required this.phase,
    required this.progress,
    required this.message,
    this.generatedFile,
    this.error,
  });
}

/// Generation phases
enum GenerationPhase {
  parsing,
  planning,
  generatingModels,
  generatingScreens,
  generatingNavigation,
  generatingState,
  generatingMain,
  writingFiles,
  complete,
  error,
}
