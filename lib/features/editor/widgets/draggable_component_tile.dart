import 'package:flutter/material.dart';
import '../../../core/models/component_definition.dart';
import '../../../core/models/drag_data.dart';

/// A draggable tile representing a component in the palette
class DraggableComponentTile extends StatefulWidget {
  final ComponentDefinition component;
  final VoidCallback? onTap;
  final VoidCallback? onDragStarted;
  final VoidCallback? onDragEnded;

  const DraggableComponentTile({
    super.key,
    required this.component,
    this.onTap,
    this.onDragStarted,
    this.onDragEnded,
  });

  @override
  State<DraggableComponentTile> createState() => _DraggableComponentTileState();
}

class _DraggableComponentTileState extends State<DraggableComponentTile> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return Draggable<DraggedComponent>(
      data: DraggedComponent(
        component: widget.component,
        startPosition: Offset.zero,
        isFromPalette: true,
        initialProperties: widget.component.getDefaultPropertyValues(),
      ),
      feedback: _DragFeedback(component: widget.component),
      childWhenDragging: Opacity(
        opacity: 0.4,
        child: _buildTile(context, isDragging: true),
      ),
      onDragStarted: () {
        widget.onDragStarted?.call();
      },
      onDragEnd: (_) {
        widget.onDragEnded?.call();
      },
      onDraggableCanceled: (_, __) {
        widget.onDragEnded?.call();
      },
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: _buildTile(context),
        ),
      ),
    );
  }

  Widget _buildTile(BuildContext context, {bool isDragging = false}) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: 68,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      decoration: BoxDecoration(
        color: _isHovered || isDragging
            ? colorScheme.primaryContainer.withValues(alpha: 0.5)
            : colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _isHovered
              ? colorScheme.primary.withValues(alpha: 0.5)
              : colorScheme.outlineVariant.withValues(alpha: 0.5),
          width: 1,
        ),
        boxShadow: _isHovered && !isDragging
            ? [
                BoxShadow(
                  color: colorScheme.shadow.withValues(alpha: 0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icon or emoji
          Text(
            widget.component.icon,
            style: const TextStyle(fontSize: 20),
          ),
          const SizedBox(height: 4),
          // Name
          Text(
            widget.component.name,
            style: theme.textTheme.labelSmall?.copyWith(
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

/// The visual feedback shown while dragging a component
class _DragFeedback extends StatelessWidget {
  final ComponentDefinition component;

  const _DragFeedback({required this.component});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(8),
      color: colorScheme.primaryContainer,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: colorScheme.primary,
            width: 2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              component.icon,
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(width: 8),
            Text(
              component.name,
              style: theme.textTheme.titleSmall?.copyWith(
                color: colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A larger preview of a component shown on hover or for tooltips
class ComponentPreview extends StatelessWidget {
  final ComponentDefinition component;

  const ComponentPreview({super.key, required this.component});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: 200,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colorScheme.outline),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Row(
            children: [
              Text(
                component.icon,
                style: const TextStyle(fontSize: 24),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      component.name,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      component.category.displayName,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.outline,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Description
          Text(
            component.description,
            style: theme.textTheme.bodySmall,
          ),

          // Properties count
          if (component.properties.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '${component.properties.length} properties',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],

          // Accepts children indicator
          if (component.acceptsChildren) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.account_tree,
                  size: 12,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 4),
                Text(
                  component.acceptsMultipleChildren
                      ? 'Accepts multiple children'
                      : 'Accepts child',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.primary,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
