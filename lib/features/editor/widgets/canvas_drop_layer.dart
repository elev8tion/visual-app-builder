import 'package:flutter/material.dart';
import '../../../core/models/drag_data.dart';
import '../../../core/models/widget_node.dart';

/// Overlay layer on the preview canvas that handles drop zones and visual feedback
class CanvasDropLayer extends StatefulWidget {
  /// The preview widget to wrap
  final Widget child;

  /// The current widget tree for calculating drop zones
  final List<WidgetNode>? widgetTree;

  /// Currently selected widget ID
  final String? selectedWidgetId;

  /// Callback when a component is dropped
  final void Function(DraggedComponent component, DropTarget target)? onDrop;

  /// Callback when drag enters the canvas
  final VoidCallback? onDragEnter;

  /// Callback when drag leaves the canvas
  final VoidCallback? onDragLeave;

  /// Whether the canvas is in drop mode (drag in progress)
  final bool isDropMode;

  /// Map of widget IDs to their GlobalKeys for position tracking
  final Map<String, GlobalKey>? widgetKeys;

  const CanvasDropLayer({
    super.key,
    required this.child,
    this.widgetTree,
    this.selectedWidgetId,
    this.onDrop,
    this.onDragEnter,
    this.onDragLeave,
    this.isDropMode = false,
    this.widgetKeys,
  });

  @override
  State<CanvasDropLayer> createState() => _CanvasDropLayerState();
}

class _CanvasDropLayerState extends State<CanvasDropLayer> {
  DropTarget? _hoveredTarget;
  Offset? _dragPosition;
  bool _isDragOver = false;

  @override
  Widget build(BuildContext context) {
    return DragTarget<DraggedComponent>(
      onWillAcceptWithDetails: (details) {
        if (!_isDragOver) {
          _isDragOver = true;
          widget.onDragEnter?.call();
        }
        return true;
      },
      onLeave: (_) {
        setState(() {
          _isDragOver = false;
          _hoveredTarget = null;
          _dragPosition = null;
        });
        widget.onDragLeave?.call();
      },
      onMove: (details) {
        setState(() {
          _dragPosition = details.offset;
          _hoveredTarget = _calculateDropTarget(details.offset, details.data);
        });
      },
      onAcceptWithDetails: (details) {
        if (_hoveredTarget != null && _hoveredTarget!.isValid) {
          widget.onDrop?.call(details.data, _hoveredTarget!);
        }
        setState(() {
          _isDragOver = false;
          _hoveredTarget = null;
          _dragPosition = null;
        });
      },
      builder: (context, candidateData, rejectedData) {
        final isDragging = candidateData.isNotEmpty;

        return Stack(
          children: [
            // The actual preview
            widget.child,

            // Drop zone overlay when dragging
            if (isDragging || widget.isDropMode)
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: _DropZonePainter(
                      hoveredTarget: _hoveredTarget,
                      dragPosition: _dragPosition,
                      widgetTree: widget.widgetTree,
                    ),
                  ),
                ),
              ),

            // Drop indicator
            if (_hoveredTarget != null && _hoveredTarget!.isValid)
              Positioned(
                left: _hoveredTarget!.bounds.left,
                top: _getIndicatorTop(),
                child: _DropIndicator(
                  target: _hoveredTarget!,
                  width: _hoveredTarget!.bounds.width,
                ),
              ),

            // Empty canvas drop zone
            if (widget.widgetTree == null || widget.widgetTree!.isEmpty)
              if (isDragging)
                Positioned.fill(
                  child: _EmptyCanvasDropZone(
                    isHovered: _isDragOver,
                  ),
                ),
          ],
        );
      },
    );
  }

  double _getIndicatorTop() {
    if (_hoveredTarget == null) return 0;

    switch (_hoveredTarget!.position) {
      case DropPosition.before:
        return _hoveredTarget!.bounds.top - 2;
      case DropPosition.after:
        return _hoveredTarget!.bounds.bottom - 2;
      case DropPosition.inside:
      case DropPosition.replace:
        return _hoveredTarget!.bounds.center.dy - 10;
    }
  }

  DropTarget? _calculateDropTarget(Offset position, DraggedComponent component) {
    if (widget.widgetTree == null || widget.widgetTree!.isEmpty) {
      // Empty canvas - drop as root
      return DropTarget(
        targetWidgetId: 'root',
        targetWidgetType: 'Scaffold',
        position: DropPosition.inside,
        bounds: Rect.fromLTWH(0, 0, MediaQuery.of(context).size.width, MediaQuery.of(context).size.height),
        isValid: true,
        insertIndex: 0,
      );
    }

    // Find the selected widget or default to first widget
    final targetWidget = widget.selectedWidgetId != null
        ? _findWidget(widget.widgetTree!, widget.selectedWidgetId!)
        : widget.widgetTree!.first;

    if (targetWidget == null) {
      return null;
    }

    // Get actual bounds from GlobalKey if available
    Rect bounds;
    if (widget.widgetKeys != null && widget.widgetKeys!.containsKey(targetWidget.id)) {
      final key = widget.widgetKeys![targetWidget.id];
      bounds = _getWidgetBounds(key);
    } else {
      // Fallback to tree-based approximation when keys aren't available
      bounds = _approximateBoundsFromTree(targetWidget);
    }

    // Determine drop position based on actual bounds and drag position
    final dropPosition = _determineDropPositionFromBounds(position, bounds, targetWidget);

    return DropTarget(
      targetWidgetId: targetWidget.id,
      targetWidgetType: targetWidget.type,
      position: dropPosition,
      bounds: bounds,
      isValid: _isValidDrop(targetWidget, component),
      insertIndex: _calculateInsertIndex(targetWidget, dropPosition),
    );
  }

  /// Get actual widget bounds from GlobalKey
  Rect _getWidgetBounds(GlobalKey? key) {
    if (key?.currentContext == null) {
      return Rect.zero;
    }

    final renderBox = key!.currentContext!.findRenderObject() as RenderBox?;
    if (renderBox == null || !renderBox.hasSize) {
      return Rect.zero;
    }

    final offset = renderBox.localToGlobal(Offset.zero);
    return Rect.fromLTWH(offset.dx, offset.dy, renderBox.size.width, renderBox.size.height);
  }

  /// Approximate widget bounds based on tree structure (fallback)
  Rect _approximateBoundsFromTree(WidgetNode widget) {
    // Calculate approximate Y position based on tree depth and index
    final depth = _getWidgetDepth(widget);
    final index = _getWidgetIndex(widget);

    // Estimate position based on typical widget heights
    const double appBarHeight = 56.0;
    const double widgetHeight = 60.0;
    const double leftPadding = 16.0;
    const double indentPerDepth = 16.0;

    double top = appBarHeight + (index * widgetHeight);
    double left = leftPadding + (depth * indentPerDepth);
    double width = MediaQuery.of(context).size.width - left - 32;

    return Rect.fromLTWH(left, top, width, widgetHeight);
  }

  /// Get depth of widget in tree (for approximation)
  int _getWidgetDepth(WidgetNode target) {
    int depth = 0;
    void traverse(List<WidgetNode> nodes, int currentDepth) {
      for (final node in nodes) {
        if (node.id == target.id) {
          depth = currentDepth;
          return;
        }
        if (node.children.isNotEmpty) {
          traverse(node.children, currentDepth + 1);
        }
      }
    }
    if (widget.widgetTree != null) {
      traverse(widget.widgetTree!, 0);
    }
    return depth;
  }

  /// Get index of widget among siblings (for approximation)
  int _getWidgetIndex(WidgetNode target) {
    int index = 0;
    void traverse(List<WidgetNode> nodes) {
      for (int i = 0; i < nodes.length; i++) {
        if (nodes[i].id == target.id) {
          index = i;
          return;
        }
        if (nodes[i].children.isNotEmpty) {
          traverse(nodes[i].children);
        }
      }
    }
    if (widget.widgetTree != null) {
      traverse(widget.widgetTree!);
    }
    return index;
  }

  /// Determine drop position based on actual bounds and cursor position
  DropPosition _determineDropPositionFromBounds(Offset position, Rect bounds, WidgetNode target) {
    if (!bounds.contains(position)) {
      // Default to inside if not within bounds
      return DropPosition.inside;
    }

    // If target can have children, prefer inside
    if (_canHaveChildren(target)) {
      final relativeY = position.dy - bounds.top;
      final thirdHeight = bounds.height / 3;

      if (relativeY < thirdHeight) {
        return DropPosition.before;
      } else if (relativeY > bounds.height - thirdHeight) {
        return DropPosition.after;
      }
      return DropPosition.inside;
    }

    // For leaf widgets, only before/after
    final midY = bounds.center.dy;
    return position.dy < midY ? DropPosition.before : DropPosition.after;
  }

  /// Check if widget type can have children
  bool _canHaveChildren(WidgetNode widget) {
    const containerTypes = ['Column', 'Row', 'Container', 'Stack', 'ListView', 'Scaffold'];
    return containerTypes.contains(widget.type);
  }

  /// Check if dropping component into target is valid
  bool _isValidDrop(WidgetNode target, DraggedComponent component) {
    // Prevent dropping a widget into itself
    if (component.existingWidgetId == target.id) {
      return false;
    }

    // Check if target can accept children (only relevant for container widgets)
    // For now, we allow all valid drops as the check is primarily structural
    if (!_canHaveChildren(target)) {
      // Non-container widgets can't have children dropped inside them
      // But they can have siblings added before/after
      return true;
    }

    return true;
  }

  /// Calculate insertion index for multi-child widgets
  int _calculateInsertIndex(WidgetNode target, DropPosition position) {
    switch (position) {
      case DropPosition.before:
        return 0;
      case DropPosition.after:
        return target.children.length;
      case DropPosition.inside:
        return target.children.length;
      case DropPosition.replace:
        return 0;
    }
  }

  WidgetNode? _findWidget(List<WidgetNode> nodes, String id) {
    for (final node in nodes) {
      if (node.id == id) return node;
      if (node.children.isNotEmpty) {
        final found = _findWidget(node.children, id);
        if (found != null) return found;
      }
    }
    return null;
  }
}

/// Custom painter for drawing drop zone overlays
class _DropZonePainter extends CustomPainter {
  final DropTarget? hoveredTarget;
  final Offset? dragPosition;
  final List<WidgetNode>? widgetTree;

  _DropZonePainter({
    this.hoveredTarget,
    this.dragPosition,
    this.widgetTree,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (hoveredTarget == null) return;

    final paint = Paint()
      ..color = hoveredTarget!.isValid
          ? const Color(0xFF4CAF50).withValues(alpha: 0.2)
          : const Color(0xFFF44336).withValues(alpha: 0.2)
      ..style = PaintingStyle.fill;

    // Draw highlighted area
    canvas.drawRect(hoveredTarget!.bounds, paint);

    // Draw border
    final borderPaint = Paint()
      ..color = hoveredTarget!.isValid
          ? const Color(0xFF4CAF50)
          : const Color(0xFFF44336)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawRect(hoveredTarget!.bounds, borderPaint);
  }

  @override
  bool shouldRepaint(covariant _DropZonePainter oldDelegate) {
    return hoveredTarget != oldDelegate.hoveredTarget ||
        dragPosition != oldDelegate.dragPosition;
  }
}

/// Visual indicator showing where the drop will occur
class _DropIndicator extends StatelessWidget {
  final DropTarget target;
  final double width;

  const _DropIndicator({
    required this.target,
    required this.width,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (target.position == DropPosition.inside) {
      // Show "insert inside" indicator
      return Container(
        width: width,
        height: 20,
        decoration: BoxDecoration(
          color: colorScheme.primary.withValues(alpha: 0.2),
          border: Border.all(
            color: colorScheme.primary,
            width: 1,
            style: BorderStyle.solid,
          ),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Center(
          child: Text(
            '+ Add child',
            style: TextStyle(
              fontSize: 10,
              color: colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    }

    // Show horizontal line indicator for before/after
    return Container(
      width: width,
      height: 4,
      decoration: BoxDecoration(
        color: colorScheme.primary,
        borderRadius: BorderRadius.circular(2),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withValues(alpha: 0.4),
            blurRadius: 4,
            spreadRadius: 1,
          ),
        ],
      ),
    );
  }
}

/// Shown when the canvas is empty
class _EmptyCanvasDropZone extends StatelessWidget {
  final bool isHovered;

  const _EmptyCanvasDropZone({this.isHovered = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isHovered
            ? colorScheme.primaryContainer.withValues(alpha: 0.3)
            : colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isHovered
              ? colorScheme.primary
              : colorScheme.outline.withValues(alpha: 0.5),
          width: isHovered ? 2 : 1,
          style: BorderStyle.solid,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isHovered ? Icons.add_circle : Icons.widgets_outlined,
              size: 48,
              color: isHovered ? colorScheme.primary : colorScheme.outline,
            ),
            const SizedBox(height: 12),
            Text(
              isHovered ? 'Drop here to add' : 'Drag components here',
              style: theme.textTheme.titleMedium?.copyWith(
                color: isHovered ? colorScheme.primary : colorScheme.outline,
              ),
            ),
            if (!isHovered) ...[
              const SizedBox(height: 8),
              Text(
                'Start building your UI',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.outline,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
