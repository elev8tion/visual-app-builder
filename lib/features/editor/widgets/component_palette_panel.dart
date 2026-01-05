import 'package:flutter/material.dart';
import '../../../core/models/component_definition.dart';
import '../../../core/services/component_registry.dart';
import 'draggable_component_tile.dart';

/// Panel displaying the component palette for drag-and-drop
class ComponentPalettePanel extends StatefulWidget {
  /// Callback when a component is selected (single click)
  final ValueChanged<ComponentDefinition>? onComponentSelected;

  /// Callback when a component drag starts
  final ValueChanged<ComponentDefinition>? onDragStarted;

  /// Callback when a component drag ends
  final VoidCallback? onDragEnded;

  const ComponentPalettePanel({
    super.key,
    this.onComponentSelected,
    this.onDragStarted,
    this.onDragEnded,
  });

  @override
  State<ComponentPalettePanel> createState() => _ComponentPalettePanelState();
}

class _ComponentPalettePanelState extends State<ComponentPalettePanel> {
  final TextEditingController _searchController = TextEditingController();
  final Set<ComponentCategory> _expandedCategories = {};
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    // Expand all categories by default
    _expandedCategories.addAll(ComponentCategory.values);
    // Ensure registry is initialized
    ComponentRegistry.instance.initialize();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final registry = ComponentRegistry.instance;

    // Get filtered components
    final components = _searchQuery.isEmpty
        ? registry.all
        : registry.search(_searchQuery);

    // Group by category
    final groupedComponents = <ComponentCategory, List<ComponentDefinition>>{};
    for (final component in components) {
      groupedComponents.putIfAbsent(component.category, () => []).add(component);
    }

    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search components...',
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                  : null,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: colorScheme.outline),
              ),
              filled: true,
              fillColor: colorScheme.surfaceContainerLowest,
            ),
            style: theme.textTheme.bodySmall,
            onChanged: (value) {
              setState(() => _searchQuery = value.trim());
            },
          ),
        ),

        // Component list
        Expanded(
          child: components.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.search_off,
                        size: 48,
                        color: colorScheme.outline,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'No components found',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.outline,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  itemCount: groupedComponents.length,
                  itemBuilder: (context, index) {
                    final category = groupedComponents.keys.elementAt(index);
                    final categoryComponents = groupedComponents[category]!;
                    final isExpanded = _expandedCategories.contains(category);

                    return _CategorySection(
                      category: category,
                      components: categoryComponents,
                      isExpanded: isExpanded,
                      onToggle: () {
                        setState(() {
                          if (isExpanded) {
                            _expandedCategories.remove(category);
                          } else {
                            _expandedCategories.add(category);
                          }
                        });
                      },
                      onComponentSelected: widget.onComponentSelected,
                      onDragStarted: widget.onDragStarted,
                      onDragEnded: widget.onDragEnded,
                    );
                  },
                ),
        ),

        // Footer with component count
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: colorScheme.outlineVariant),
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.widgets, size: 14, color: colorScheme.outline),
              const SizedBox(width: 4),
              Text(
                '${components.length} components',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.outline,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// A collapsible category section
class _CategorySection extends StatelessWidget {
  final ComponentCategory category;
  final List<ComponentDefinition> components;
  final bool isExpanded;
  final VoidCallback onToggle;
  final ValueChanged<ComponentDefinition>? onComponentSelected;
  final ValueChanged<ComponentDefinition>? onDragStarted;
  final VoidCallback? onDragEnded;

  const _CategorySection({
    required this.category,
    required this.components,
    required this.isExpanded,
    required this.onToggle,
    this.onComponentSelected,
    this.onDragStarted,
    this.onDragEnded,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Category header
        InkWell(
          onTap: onToggle,
          borderRadius: BorderRadius.circular(4),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            child: Row(
              children: [
                Icon(
                  isExpanded ? Icons.expand_more : Icons.chevron_right,
                  size: 18,
                  color: colorScheme.outline,
                ),
                const SizedBox(width: 4),
                Icon(
                  category.icon,
                  size: 16,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    category.displayName,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${components.length}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Components grid
        if (isExpanded)
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Wrap(
              spacing: 4,
              runSpacing: 4,
              children: components.map((component) {
                return DraggableComponentTile(
                  component: component,
                  onTap: () => onComponentSelected?.call(component),
                  onDragStarted: () => onDragStarted?.call(component),
                  onDragEnded: () => onDragEnded?.call(),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }
}
