/// Defines the structure and properties of a draggable UI component
library;

import 'package:flutter/material.dart';

/// Type of property for component configuration
enum PropertyType {
  string,
  number,
  integer,
  boolean,
  color,
  edgeInsets,
  alignment,
  mainAxisAlignment,
  crossAxisAlignment,
  mainAxisSize,
  boxDecoration,
  textStyle,
  icon,
  fontWeight,
  textAlign,
  boxFit,
  borderRadius,
  shadow,
  gradient,
}

/// Definition of a single property for a component
class PropertyDefinition {
  final String name;
  final String displayName;
  final PropertyType type;
  final dynamic defaultValue;
  final bool required;
  final List<dynamic>? options;
  final String? group;
  final String? description;
  final double? min;
  final double? max;

  const PropertyDefinition({
    required this.name,
    required this.displayName,
    required this.type,
    this.defaultValue,
    this.required = false,
    this.options,
    this.group,
    this.description,
    this.min,
    this.max,
  });

  /// Create a copy with modified values
  PropertyDefinition copyWith({
    String? name,
    String? displayName,
    PropertyType? type,
    dynamic defaultValue,
    bool? required,
    List<dynamic>? options,
    String? group,
    String? description,
    double? min,
    double? max,
  }) {
    return PropertyDefinition(
      name: name ?? this.name,
      displayName: displayName ?? this.displayName,
      type: type ?? this.type,
      defaultValue: defaultValue ?? this.defaultValue,
      required: required ?? this.required,
      options: options ?? this.options,
      group: group ?? this.group,
      description: description ?? this.description,
      min: min ?? this.min,
      max: max ?? this.max,
    );
  }
}

/// Category for grouping components in the palette
enum ComponentCategory {
  layout('Layout', Icons.grid_view, 'Structural widgets for arranging content'),
  content('Content', Icons.text_fields, 'Text, images, and media widgets'),
  input('Input', Icons.input, 'Form fields and interactive controls'),
  navigation('Navigation', Icons.menu, 'App bars, drawers, and navigation'),
  feedback('Feedback', Icons.notifications, 'Dialogs, snackbars, and indicators'),
  scrolling('Scrolling', Icons.view_list, 'Lists and scrollable containers'),
  decoration('Decoration', Icons.palette, 'Visual styling and effects');

  final String displayName;
  final IconData icon;
  final String description;

  const ComponentCategory(this.displayName, this.icon, this.description);
}

/// Defines a draggable UI component that can be placed on the canvas
class ComponentDefinition {
  /// Unique identifier for this component type
  final String id;

  /// Display name shown in palette
  final String name;

  /// Category for grouping
  final ComponentCategory category;

  /// Icon or emoji for visual identification
  final String icon;

  /// Brief description of the component
  final String description;

  /// Default properties when component is created
  final Map<String, PropertyDefinition> properties;

  /// Widget types this component accepts as children
  /// Empty list = no children, ['any'] = any widget
  final List<String> allowedChildren;

  /// Whether this component can have children
  final bool acceptsChildren;

  /// Whether this component accepts multiple children
  final bool acceptsMultipleChildren;

  /// Code template for generating Dart code
  final String codeTemplate;

  /// Required imports for this component
  final List<String> requiredImports;

  /// Named slots for specific child positions (e.g., 'leading', 'trailing')
  final List<String> namedSlots;

  /// Keywords for search
  final List<String> searchKeywords;

  const ComponentDefinition({
    required this.id,
    required this.name,
    required this.category,
    required this.icon,
    required this.description,
    required this.properties,
    this.allowedChildren = const [],
    this.acceptsChildren = false,
    this.acceptsMultipleChildren = false,
    required this.codeTemplate,
    this.requiredImports = const [],
    this.namedSlots = const [],
    this.searchKeywords = const [],
  });

  /// Check if this component matches a search query
  bool matchesSearch(String query) {
    final lowerQuery = query.toLowerCase();
    return name.toLowerCase().contains(lowerQuery) ||
        description.toLowerCase().contains(lowerQuery) ||
        searchKeywords.any((k) => k.toLowerCase().contains(lowerQuery));
  }

  /// Generate default property values map
  Map<String, dynamic> getDefaultPropertyValues() {
    final values = <String, dynamic>{};
    for (final entry in properties.entries) {
      if (entry.value.defaultValue != null) {
        values[entry.key] = entry.value.defaultValue;
      }
    }
    return values;
  }

  /// Get properties grouped by their group name
  Map<String, List<PropertyDefinition>> getGroupedProperties() {
    final grouped = <String, List<PropertyDefinition>>{};
    for (final prop in properties.values) {
      final group = prop.group ?? 'General';
      grouped.putIfAbsent(group, () => []).add(prop);
    }
    return grouped;
  }
}

/// Common property definitions reused across components
class CommonProperties {
  static const width = PropertyDefinition(
    name: 'width',
    displayName: 'Width',
    type: PropertyType.number,
    group: 'Size',
    description: 'Width in logical pixels',
    min: 0,
  );

  static const height = PropertyDefinition(
    name: 'height',
    displayName: 'Height',
    type: PropertyType.number,
    group: 'Size',
    description: 'Height in logical pixels',
    min: 0,
  );

  static const padding = PropertyDefinition(
    name: 'padding',
    displayName: 'Padding',
    type: PropertyType.edgeInsets,
    group: 'Spacing',
    description: 'Inner spacing',
  );

  static const margin = PropertyDefinition(
    name: 'margin',
    displayName: 'Margin',
    type: PropertyType.edgeInsets,
    group: 'Spacing',
    description: 'Outer spacing',
  );

  static const color = PropertyDefinition(
    name: 'color',
    displayName: 'Color',
    type: PropertyType.color,
    group: 'Appearance',
  );

  static const backgroundColor = PropertyDefinition(
    name: 'backgroundColor',
    displayName: 'Background Color',
    type: PropertyType.color,
    group: 'Appearance',
  );

  static const alignment = PropertyDefinition(
    name: 'alignment',
    displayName: 'Alignment',
    type: PropertyType.alignment,
    group: 'Layout',
  );

  static const mainAxisAlignment = PropertyDefinition(
    name: 'mainAxisAlignment',
    displayName: 'Main Axis Alignment',
    type: PropertyType.mainAxisAlignment,
    group: 'Layout',
    defaultValue: 'MainAxisAlignment.start',
  );

  static const crossAxisAlignment = PropertyDefinition(
    name: 'crossAxisAlignment',
    displayName: 'Cross Axis Alignment',
    type: PropertyType.crossAxisAlignment,
    group: 'Layout',
    defaultValue: 'CrossAxisAlignment.center',
  );

  static const mainAxisSize = PropertyDefinition(
    name: 'mainAxisSize',
    displayName: 'Main Axis Size',
    type: PropertyType.mainAxisSize,
    group: 'Layout',
    defaultValue: 'MainAxisSize.max',
  );

  static const borderRadius = PropertyDefinition(
    name: 'borderRadius',
    displayName: 'Border Radius',
    type: PropertyType.borderRadius,
    group: 'Appearance',
  );

  static const text = PropertyDefinition(
    name: 'text',
    displayName: 'Text',
    type: PropertyType.string,
    group: 'Content',
    defaultValue: 'Text',
  );

  static const fontSize = PropertyDefinition(
    name: 'fontSize',
    displayName: 'Font Size',
    type: PropertyType.number,
    group: 'Typography',
    defaultValue: 14.0,
    min: 8,
    max: 96,
  );

  static const fontWeight = PropertyDefinition(
    name: 'fontWeight',
    displayName: 'Font Weight',
    type: PropertyType.fontWeight,
    group: 'Typography',
  );

  static const textAlign = PropertyDefinition(
    name: 'textAlign',
    displayName: 'Text Align',
    type: PropertyType.textAlign,
    group: 'Typography',
  );
}
