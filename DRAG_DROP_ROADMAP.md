# Drag-and-Drop No-Code Builder Implementation Roadmap

## Overview

Transform Visual App Builder into a full no-code drag-and-drop builder while maintaining code-first capabilities. Users will be able to visually construct UIs by dragging components onto a canvas.

## Current Architecture Summary

### What Exists (Leverageable)
- **WidgetNode model**: Hierarchical tree representation with properties
- **BidirectionalSyncManager**: Visual ↔ code synchronization
- **CodeSyncService**: AST-based code modification (insert/delete/update)
- **PropertiesPanel**: Dynamic property editing
- **PreviewPanel**: Live device preview with inspect mode
- **WidgetTreePanel**: Hierarchical tree view with selection

### What Needs to Be Built
1. Component Library/Palette
2. Canvas drop zones and visual feedback
3. Drag gesture handlers
4. Position-aware widget insertion
5. Visual selection handles and resize grips
6. Copy/paste/duplicate operations
7. Undo/redo stack for visual operations

---

## Phase 1: Component Library Panel

### 1.1 Component Palette Widget
**File**: `lib/features/editor/widgets/component_palette_panel.dart`

```
┌─────────────────────────────────┐
│ 🔍 Search components...         │
├─────────────────────────────────┤
│ ▼ Layout                        │
│   [Container] [Column] [Row]    │
│   [Stack] [Wrap] [GridView]     │
├─────────────────────────────────┤
│ ▼ Content                       │
│   [Text] [Image] [Icon]         │
│   [RichText] [Placeholder]      │
├─────────────────────────────────┤
│ ▼ Input                         │
│   [TextField] [Button]          │
│   [Checkbox] [Switch] [Slider]  │
├─────────────────────────────────┤
│ ▼ Navigation                    │
│   [AppBar] [BottomNav] [Drawer] │
│   [TabBar] [FloatingActionBtn]  │
├─────────────────────────────────┤
│ ▼ Scrolling                     │
│   [ListView] [SingleChildScroll]│
│   [CustomScrollView]            │
└─────────────────────────────────┘
```

### 1.2 Component Definition Model
**File**: `lib/core/models/component_definition.dart`

```dart
class ComponentDefinition {
  final String id;
  final String name;
  final String category;
  final String icon;
  final String description;
  final Map<String, PropertyDefinition> defaultProperties;
  final List<String> allowedChildren; // e.g., ['any'], ['Widget'], []
  final bool acceptsChildren;
  final String codeTemplate;
  final List<String> requiredImports;
}

class PropertyDefinition {
  final String name;
  final PropertyType type;
  final dynamic defaultValue;
  final bool required;
  final List<dynamic>? options; // For enum-like properties
  final String? group; // For grouping in properties panel
}

enum PropertyType {
  string,
  number,
  boolean,
  color,
  edgeInsets,
  alignment,
  mainAxisAlignment,
  crossAxisAlignment,
  boxDecoration,
  textStyle,
  icon,
  widget, // For child slots
}
```

### 1.3 Component Registry
**File**: `lib/core/services/component_registry.dart`

```dart
class ComponentRegistry {
  static final Map<String, ComponentDefinition> _components = {};

  static void registerBuiltInComponents() {
    // Layout components
    register(ContainerComponent());
    register(ColumnComponent());
    register(RowComponent());
    register(StackComponent());
    // ... etc
  }

  static ComponentDefinition? get(String type);
  static List<ComponentDefinition> getByCategory(String category);
  static List<String> get categories;
}
```

### Files to Create
- `lib/core/models/component_definition.dart`
- `lib/core/services/component_registry.dart`
- `lib/core/data/builtin_components.dart` (component definitions)
- `lib/features/editor/widgets/component_palette_panel.dart`
- `lib/features/editor/widgets/draggable_component_tile.dart`

---

## Phase 2: Drag Gesture System

### 2.1 Drag Data Model
**File**: `lib/core/models/drag_data.dart`

```dart
class DraggedComponent {
  final ComponentDefinition component;
  final Offset startPosition;
  final Size size;
  final bool isFromPalette; // vs. moving existing widget
  final String? existingWidgetId; // If moving existing
}

class DropTarget {
  final String targetWidgetId;
  final DropPosition position;
  final Rect bounds;
  final bool isValid;
}

enum DropPosition {
  inside,      // As child
  before,      // Sibling before
  after,       // Sibling after
  replace,     // Replace target
}
```

### 2.2 Draggable Component Tile
**File**: `lib/features/editor/widgets/draggable_component_tile.dart`

```dart
class DraggableComponentTile extends StatelessWidget {
  final ComponentDefinition component;

  @override
  Widget build(BuildContext context) {
    return Draggable<DraggedComponent>(
      data: DraggedComponent(
        component: component,
        startPosition: Offset.zero,
        size: const Size(100, 50),
        isFromPalette: true,
      ),
      feedback: _buildDragFeedback(),
      childWhenDragging: Opacity(opacity: 0.5, child: _buildTile()),
      child: _buildTile(),
    );
  }
}
```

### 2.3 Canvas Drop Zone Layer
**File**: `lib/features/editor/widgets/canvas_drop_layer.dart`

Overlay on preview panel that:
- Tracks drag position
- Calculates nearest valid drop target
- Shows insertion indicators
- Handles drop events

```dart
class CanvasDropLayer extends StatefulWidget {
  final Widget child; // The preview
  final List<WidgetNode> widgetTree;
  final Function(DraggedComponent, DropTarget) onDrop;
}
```

### Files to Create
- `lib/core/models/drag_data.dart`
- `lib/features/editor/widgets/draggable_component_tile.dart`
- `lib/features/editor/widgets/canvas_drop_layer.dart`
- `lib/features/editor/widgets/drop_indicator.dart`

---

## Phase 3: Visual Drop Feedback

### 3.1 Drop Indicator Types

```
┌─────────────────────────────────┐
│  INSERT BEFORE (horizontal line)│
│  ═══════════════════════════════│
│  ┌───────────────────────────┐  │
│  │     Target Widget         │  │
│  └───────────────────────────┘  │
│  ═══════════════════════════════│
│  INSERT AFTER (horizontal line) │
└─────────────────────────────────┘

┌─────────────────────────────────┐
│  ┌───────────────────────────┐  │
│  │     Target Widget         │  │
│  │   ┌───────────────────┐   │  │
│  │   │ INSERT INSIDE     │   │  │
│  │   │ (dashed border)   │   │  │
│  │   └───────────────────┘   │  │
│  └───────────────────────────┘  │
└─────────────────────────────────┘
```

### 3.2 Widget Highlight Service
**File**: `lib/core/services/widget_highlight_service.dart`

Uses JavaScript interop to highlight elements in web preview:
- Find DOM element by widget ID
- Add highlight overlay
- Show insertion guides

### Files to Create
- `lib/features/editor/widgets/drop_indicator.dart`
- `lib/features/editor/widgets/insertion_guide.dart`
- `lib/core/services/widget_highlight_service.dart`

---

## Phase 4: Widget Manipulation Handles

### 4.1 Selection Overlay
When a widget is selected, show manipulation handles:

```
     ┌─────────────────────┐
     │  ↔ Resize handle    │
┌────┼─────────────────────┼────┐
│    │                     │    │
│ ↕  │   Selected Widget   │ ↕  │
│    │                     │    │
└────┼─────────────────────┼────┘
     │  ↔ Resize handle    │
     └─────────────────────┘

     [⬆] [⬇] [🗑] [📋]  ← Action buttons
```

### 4.2 Resize and Reposition
**File**: `lib/features/editor/widgets/widget_handles_overlay.dart`

```dart
class WidgetHandlesOverlay extends StatelessWidget {
  final WidgetSelection selection;
  final Function(Size) onResize;
  final Function(Offset) onMove;
  final VoidCallback onDelete;
  final VoidCallback onDuplicate;
}
```

### Files to Create
- `lib/features/editor/widgets/widget_handles_overlay.dart`
- `lib/features/editor/widgets/resize_handle.dart`
- `lib/features/editor/widgets/selection_actions_bar.dart`

---

## Phase 5: BLoC Integration

### 5.1 New EditorBloc Events

```dart
// Drag-drop events
class StartDrag extends EditorEvent {
  final DraggedComponent component;
}

class UpdateDragPosition extends EditorEvent {
  final Offset position;
}

class EndDrag extends EditorEvent {
  final DropTarget? target;
}

class CancelDrag extends EditorEvent {}

// Widget manipulation events
class MoveWidget extends EditorEvent {
  final String widgetId;
  final String newParentId;
  final int newIndex;
}

class DuplicateWidget extends EditorEvent {
  final String widgetId;
}

class CopyWidget extends EditorEvent {
  final String widgetId;
}

class PasteWidget extends EditorEvent {
  final String targetParentId;
  final int index;
}
```

### 5.2 EditorLoaded State Extensions

```dart
class EditorLoaded extends EditorState {
  // Existing fields...

  // New drag-drop fields
  final DraggedComponent? activeDrag;
  final DropTarget? hoveredTarget;
  final List<DropTarget> validDropTargets;

  // Clipboard
  final WidgetNode? clipboard;

  // Multi-select
  final Set<String> selectedWidgetIds;
}
```

### Files to Modify
- `lib/bloc/editor/editor_bloc.dart` - Add new events and handlers
- `lib/bloc/editor/editor_state.dart` - Extend state (if separate file)

---

## Phase 6: Code Generation for Dropped Widgets

### 6.1 Widget Code Templates
**File**: `lib/core/data/widget_templates.dart`

```dart
const containerTemplate = '''
Container(
  {{#if width}}width: {{width}},{{/if}}
  {{#if height}}height: {{height}},{{/if}}
  {{#if color}}color: {{color}},{{/if}}
  {{#if padding}}padding: {{padding}},{{/if}}
  {{#if child}}child: {{child}},{{/if}}
)''';
```

### 6.2 Template Engine
**File**: `lib/core/services/widget_template_service.dart`

```dart
class WidgetTemplateService {
  String generateCode(ComponentDefinition component, Map<String, dynamic> properties);
  String generateChildSlot(String childCode);
  String formatGeneratedCode(String code);
}
```

### Files to Create
- `lib/core/data/widget_templates.dart`
- `lib/core/services/widget_template_service.dart`

---

## Phase 7: Advanced Features

### 7.1 Component Groups / Sections
Pre-built combinations like:
- Login Form (Column + TextFields + Button)
- Card with Image (Card + Column + Image + Text)
- List Item (ListTile with leading/trailing)

### 7.2 Custom Component Creation
Allow users to select widgets and "Save as Component"

### 7.3 Responsive Breakpoints
Visual breakpoint editor with drag handles

### 7.4 Undo/Redo Stack
**File**: `lib/core/services/history_service.dart`

```dart
class HistoryService {
  final List<EditorState> _undoStack = [];
  final List<EditorState> _redoStack = [];

  void push(EditorState state);
  EditorState? undo();
  EditorState? redo();
}
```

---

## Implementation Order

### Sprint 1: Foundation
1. ✅ Create branch
2. Component Definition model
3. Component Registry with built-in widgets
4. Component Palette Panel UI

### Sprint 2: Basic Drag-Drop
5. Drag Data models
6. Draggable Component Tile
7. Canvas Drop Layer (basic)
8. BLoC events for drag-drop

### Sprint 3: Visual Feedback
9. Drop indicators
10. Insertion guides
11. Widget highlight service

### Sprint 4: Manipulation
12. Selection overlay with handles
13. Resize functionality
14. Move/reorder widgets

### Sprint 5: Code Integration
15. Widget template service
16. Update CodeSyncService for insertions
17. Proper import handling

### Sprint 6: Polish
18. Undo/Redo
19. Copy/Paste
20. Component groups

---

## File Structure After Implementation

```
lib/
├── core/
│   ├── models/
│   │   ├── component_definition.dart    [NEW]
│   │   ├── drag_data.dart               [NEW]
│   │   └── ... existing models
│   ├── services/
│   │   ├── component_registry.dart      [NEW]
│   │   ├── widget_template_service.dart [NEW]
│   │   ├── widget_highlight_service.dart[NEW]
│   │   ├── history_service.dart         [NEW]
│   │   └── ... existing services
│   └── data/
│       ├── builtin_components.dart      [NEW]
│       └── widget_templates.dart        [NEW]
│
├── features/
│   └── editor/
│       └── widgets/
│           ├── component_palette_panel.dart    [NEW]
│           ├── draggable_component_tile.dart   [NEW]
│           ├── canvas_drop_layer.dart          [NEW]
│           ├── drop_indicator.dart             [NEW]
│           ├── insertion_guide.dart            [NEW]
│           ├── widget_handles_overlay.dart     [NEW]
│           ├── resize_handle.dart              [NEW]
│           ├── selection_actions_bar.dart      [NEW]
│           └── ... existing widgets
│
└── bloc/
    └── editor/
        └── editor_bloc.dart                    [MODIFY]
```

---

## Key Dependencies to Add

```yaml
dependencies:
  # For drag-drop feedback
  flutter_animate: ^4.5.0  # Smooth animations

  # For code generation templates (optional)
  mustache_template: ^2.0.0
```

---

## Success Metrics

1. User can drag a Container from palette onto canvas
2. Visual feedback shows valid drop zones
3. Dropped widget appears in code and preview
4. User can select and resize widgets
5. Properties panel updates for selected widget
6. Undo/redo works for all operations
7. Copy/paste works across widgets

---

## Notes

- Maintain backward compatibility with code-first workflow
- All visual changes must sync to code
- Code changes must update visual representation
- Performance: debounce frequent updates
- Accessibility: keyboard navigation for component palette
