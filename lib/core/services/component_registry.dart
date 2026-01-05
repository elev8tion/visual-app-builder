/// Registry service for managing available drag-and-drop components
library;

import '../models/component_definition.dart';
import '../data/builtin_components.dart';

/// Manages the registry of available components for drag-and-drop
class ComponentRegistry {
  ComponentRegistry._internal();

  static final ComponentRegistry _instance = ComponentRegistry._internal();
  static ComponentRegistry get instance => _instance;

  final Map<String, ComponentDefinition> _components = {};
  bool _initialized = false;

  /// Initialize the registry with built-in components
  void initialize() {
    if (_initialized) return;

    // Register all built-in components
    for (final component in BuiltinComponents.all) {
      _components[component.id] = component;
    }

    _initialized = true;
  }

  /// Register a custom component
  void register(ComponentDefinition component) {
    _components[component.id] = component;
  }

  /// Unregister a component
  void unregister(String id) {
    _components.remove(id);
  }

  /// Get a component by ID
  ComponentDefinition? get(String id) {
    _ensureInitialized();
    return _components[id];
  }

  /// Get all registered components
  List<ComponentDefinition> get all {
    _ensureInitialized();
    return _components.values.toList();
  }

  /// Get all component IDs
  List<String> get ids {
    _ensureInitialized();
    return _components.keys.toList();
  }

  /// Get components by category
  List<ComponentDefinition> getByCategory(ComponentCategory category) {
    _ensureInitialized();
    return _components.values
        .where((c) => c.category == category)
        .toList();
  }

  /// Get all categories that have components
  List<ComponentCategory> get categories {
    _ensureInitialized();
    final usedCategories = <ComponentCategory>{};
    for (final component in _components.values) {
      usedCategories.add(component.category);
    }
    // Return in enum order
    return ComponentCategory.values
        .where((c) => usedCategories.contains(c))
        .toList();
  }

  /// Search components by query
  List<ComponentDefinition> search(String query) {
    _ensureInitialized();
    if (query.isEmpty) return all;

    return _components.values
        .where((c) => c.matchesSearch(query))
        .toList();
  }

  /// Get components grouped by category
  Map<ComponentCategory, List<ComponentDefinition>> get groupedByCategory {
    _ensureInitialized();
    final grouped = <ComponentCategory, List<ComponentDefinition>>{};

    for (final category in categories) {
      grouped[category] = getByCategory(category);
    }

    return grouped;
  }

  /// Check if a component type can accept children
  bool canAcceptChildren(String componentId) {
    final component = get(componentId);
    return component?.acceptsChildren ?? false;
  }

  /// Check if a component can be a child of another
  bool canBeChildOf(String childId, String parentId) {
    final parent = get(parentId);
    if (parent == null || !parent.acceptsChildren) return false;

    if (parent.allowedChildren.contains('any')) return true;

    return parent.allowedChildren.contains(childId);
  }

  /// Get the code template for a component with properties applied
  String generateCode(String componentId, Map<String, dynamic> properties) {
    final component = get(componentId);
    if (component == null) return '';

    // Simple mustache-like template rendering
    var code = component.codeTemplate;

    for (final entry in properties.entries) {
      final key = entry.key;
      final value = entry.value;

      if (value != null) {
        // Replace {{key}} with value
        code = code.replaceAll('{{$key}}', value.toString());
        // Handle conditional sections {{#key}}...{{/key}}
        final conditionalPattern = RegExp('\\{\\{#$key\\}\\}([\\s\\S]*?)\\{\\{/$key\\}\\}');
        code = code.replaceAllMapped(conditionalPattern, (match) {
          return match.group(1)?.replaceAll('{{$key}}', value.toString()) ?? '';
        });
      } else {
        // Remove conditional sections for null values
        final conditionalPattern = RegExp('\\{\\{#$key\\}\\}[\\s\\S]*?\\{\\{/$key\\}\\}');
        code = code.replaceAll(conditionalPattern, '');
      }
    }

    // Clean up any remaining unresolved placeholders
    code = code.replaceAll(RegExp(r'\{\{[^}]+\}\}'), '');

    // Clean up empty lines and trailing commas
    code = code.replaceAll(RegExp(r',\s*\)'), ')');
    code = code.replaceAll(RegExp(r'\n\s*\n'), '\n');

    return code.trim();
  }

  void _ensureInitialized() {
    if (!_initialized) {
      initialize();
    }
  }

  /// Reset the registry (mainly for testing)
  void reset() {
    _components.clear();
    _initialized = false;
  }
}
