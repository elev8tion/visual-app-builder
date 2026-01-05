/// Models for drag-and-drop operations on the canvas
library;

import 'package:flutter/material.dart';
import 'component_definition.dart';

/// Position where a widget can be dropped relative to target
enum DropPosition {
  /// As a child of the target widget
  inside('Inside', 'Add as child'),

  /// Before the target widget (sibling)
  before('Before', 'Insert before'),

  /// After the target widget (sibling)
  after('After', 'Insert after'),

  /// Replace the target widget
  replace('Replace', 'Replace widget');

  final String displayName;
  final String description;

  const DropPosition(this.displayName, this.description);
}

/// Represents a component being dragged
class DraggedComponent {
  /// The component definition being dragged
  final ComponentDefinition component;

  /// Starting position of the drag
  final Offset startPosition;

  /// Current position during drag
  final Offset currentPosition;

  /// Size of the drag feedback widget
  final Size feedbackSize;

  /// Whether this is dragged from palette (vs moving existing widget)
  final bool isFromPalette;

  /// ID of existing widget if moving (null if from palette)
  final String? existingWidgetId;

  /// Initial properties to apply
  final Map<String, dynamic> initialProperties;

  const DraggedComponent({
    required this.component,
    required this.startPosition,
    this.currentPosition = Offset.zero,
    this.feedbackSize = const Size(120, 40),
    this.isFromPalette = true,
    this.existingWidgetId,
    this.initialProperties = const {},
  });

  /// Create a copy with updated position
  DraggedComponent copyWith({
    ComponentDefinition? component,
    Offset? startPosition,
    Offset? currentPosition,
    Size? feedbackSize,
    bool? isFromPalette,
    String? existingWidgetId,
    Map<String, dynamic>? initialProperties,
  }) {
    return DraggedComponent(
      component: component ?? this.component,
      startPosition: startPosition ?? this.startPosition,
      currentPosition: currentPosition ?? this.currentPosition,
      feedbackSize: feedbackSize ?? this.feedbackSize,
      isFromPalette: isFromPalette ?? this.isFromPalette,
      existingWidgetId: existingWidgetId ?? this.existingWidgetId,
      initialProperties: initialProperties ?? this.initialProperties,
    );
  }

  @override
  String toString() => 'DraggedComponent(${component.name}, from: $startPosition)';
}

/// Represents a valid drop target on the canvas
class DropTarget {
  /// ID of the target widget
  final String targetWidgetId;

  /// Name/type of the target widget
  final String targetWidgetType;

  /// Position relative to target where drop will occur
  final DropPosition position;

  /// Bounding rectangle of the target widget
  final Rect bounds;

  /// Whether this is a valid drop location
  final bool isValid;

  /// Reason why drop is invalid (if applicable)
  final String? invalidReason;

  /// Index position for insertion (for multi-child widgets)
  final int? insertIndex;

  /// Named slot if dropping into a specific slot
  final String? slotName;

  const DropTarget({
    required this.targetWidgetId,
    required this.targetWidgetType,
    required this.position,
    required this.bounds,
    this.isValid = true,
    this.invalidReason,
    this.insertIndex,
    this.slotName,
  });

  /// Create an invalid drop target
  factory DropTarget.invalid({
    required String targetWidgetId,
    required String targetWidgetType,
    required Rect bounds,
    required String reason,
  }) {
    return DropTarget(
      targetWidgetId: targetWidgetId,
      targetWidgetType: targetWidgetType,
      position: DropPosition.inside,
      bounds: bounds,
      isValid: false,
      invalidReason: reason,
    );
  }

  /// Check if a point is within the drop zone
  bool containsPoint(Offset point) => bounds.contains(point);

  /// Get the center of the drop zone
  Offset get center => bounds.center;

  @override
  String toString() => 'DropTarget($targetWidgetId, $position, valid: $isValid)';
}

/// State of an ongoing drag operation
class DragState {
  /// Component being dragged
  final DraggedComponent? draggedComponent;

  /// Currently hovered drop target
  final DropTarget? hoveredTarget;

  /// All valid drop targets on canvas
  final List<DropTarget> validTargets;

  /// Whether a drag operation is in progress
  final bool isDragging;

  /// Current global position of the drag
  final Offset? currentPosition;

  const DragState({
    this.draggedComponent,
    this.hoveredTarget,
    this.validTargets = const [],
    this.isDragging = false,
    this.currentPosition,
  });

  /// Initial empty state
  static const empty = DragState();

  /// Create state when drag starts
  factory DragState.started(DraggedComponent component, Offset position) {
    return DragState(
      draggedComponent: component,
      isDragging: true,
      currentPosition: position,
    );
  }

  /// Update with new position and targets
  DragState copyWith({
    DraggedComponent? draggedComponent,
    DropTarget? hoveredTarget,
    List<DropTarget>? validTargets,
    bool? isDragging,
    Offset? currentPosition,
  }) {
    return DragState(
      draggedComponent: draggedComponent ?? this.draggedComponent,
      hoveredTarget: hoveredTarget,
      validTargets: validTargets ?? this.validTargets,
      isDragging: isDragging ?? this.isDragging,
      currentPosition: currentPosition ?? this.currentPosition,
    );
  }

  /// Clear state when drag ends
  DragState clear() => const DragState();

  @override
  String toString() => 'DragState(dragging: $isDragging, target: $hoveredTarget)';
}

/// Result of a completed drop operation
class DropResult {
  /// Whether the drop was successful
  final bool success;

  /// The component that was dropped
  final DraggedComponent component;

  /// The target where it was dropped
  final DropTarget target;

  /// Generated widget ID
  final String? generatedWidgetId;

  /// Error message if drop failed
  final String? error;

  const DropResult({
    required this.success,
    required this.component,
    required this.target,
    this.generatedWidgetId,
    this.error,
  });

  factory DropResult.success({
    required DraggedComponent component,
    required DropTarget target,
    required String generatedWidgetId,
  }) {
    return DropResult(
      success: true,
      component: component,
      target: target,
      generatedWidgetId: generatedWidgetId,
    );
  }

  factory DropResult.failure({
    required DraggedComponent component,
    required DropTarget target,
    required String error,
  }) {
    return DropResult(
      success: false,
      component: component,
      target: target,
      error: error,
    );
  }
}

/// Visual feedback configuration for drag operations
class DragFeedbackConfig {
  /// Opacity of the drag feedback widget
  final double opacity;

  /// Scale factor during drag
  final double scale;

  /// Elevation/shadow during drag
  final double elevation;

  /// Border color when hovering valid target
  final Color validTargetColor;

  /// Border color when hovering invalid target
  final Color invalidTargetColor;

  /// Color of insertion indicator line
  final Color insertionLineColor;

  /// Thickness of insertion indicator
  final double insertionLineThickness;

  const DragFeedbackConfig({
    this.opacity = 0.8,
    this.scale = 1.05,
    this.elevation = 8.0,
    this.validTargetColor = const Color(0xFF4CAF50),
    this.invalidTargetColor = const Color(0xFFF44336),
    this.insertionLineColor = const Color(0xFF2196F3),
    this.insertionLineThickness = 2.0,
  });

  static const defaultConfig = DragFeedbackConfig();
}
