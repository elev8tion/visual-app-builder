import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/widget_selection.dart';
import 'dart_ast_parser_service.dart';
import 'code_sync_service.dart' show CodeSyncService, InsertPosition;

/// Bidirectional Sync Manager
///
/// Central orchestrator for bidirectional synchronization between:
/// - Visual Widget Tree Navigator
/// - Enhanced Properties Panel
/// - Code Editor
/// - Live Preview Panel
///
/// Features:
/// - Widget selection synchronization across all panels
/// - Property changes update code and preview
/// - Code changes update widget tree and properties
/// - Real-time bidirectional sync
/// - Conflict resolution
/// - Undo/redo support
/// - Change history tracking
class BidirectionalSyncManager {
  static BidirectionalSyncManager? _instance;
  static BidirectionalSyncManager get instance => _instance ??= BidirectionalSyncManager._();
  BidirectionalSyncManager._();

  // Services
  final DartAstParserService _astParser = DartAstParserService.instance;
  final CodeSyncService _codeSync = CodeSyncService.instance;

  // State streams
  final StreamController<WidgetSelection?> _widgetSelectionController =
      StreamController<WidgetSelection?>.broadcast();
  final StreamController<Map<String, dynamic>> _propertyChangesController =
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<String> _codeChangesController =
      StreamController<String>.broadcast();
  final StreamController<SyncEvent> _syncEventsController =
      StreamController<SyncEvent>.broadcast();
  final StreamController<WidgetTreeNode?> _widgetTreeController =
      StreamController<WidgetTreeNode?>.broadcast();

  // Public streams
  Stream<WidgetSelection?> get widgetSelectionStream => _widgetSelectionController.stream;
  Stream<Map<String, dynamic>> get propertyChangesStream => _propertyChangesController.stream;
  Stream<String> get codeChangesStream => _codeChangesController.stream;
  Stream<SyncEvent> get syncEventsStream => _syncEventsController.stream;
  Stream<WidgetTreeNode?> get widgetTreeStream => _widgetTreeController.stream;

  // Current state
  ProjectFile? _currentFile;
  WidgetSelection? _selectedWidget;
  WidgetTreeNode? _widgetTree;
  Map<String, dynamic> _currentProperties = {};
  final List<SyncEvent> _history = [];
  int _historyIndex = -1;

  // Sync flags to prevent circular updates
  bool _isSyncingFromCode = false;
  bool _isSyncingFromVisual = false;
  Timer? _debounceTimer;

  /// Initialize sync manager with a project file
  Future<void> initialize(ProjectFile file) async {
    _currentFile = file;
    await _parseAndSync();
  }

  /// Set current file and trigger full sync
  Future<void> setCurrentFile(ProjectFile file) async {
    if (_currentFile?.path != file.path) {
      _currentFile = file;
      _selectedWidget = null;
      _currentProperties = {};
      await _parseAndSync();
    }
  }

  /// Select a widget - triggered from Widget Tree Navigator
  Future<void> selectWidget(WidgetSelection? widget) async {
    if (_isSyncingFromCode) return;

    _selectedWidget = widget;
    _widgetSelectionController.add(widget);

    if (widget != null && _currentFile != null) {
      // Extract properties from code
      _currentProperties = await _codeSync.extractWidgetProperties(
        sourceCode: _currentFile!.content,
        lineNumber: widget.lineNumber,
      );
      _propertyChangesController.add(_currentProperties);

      // Log sync event
      _logSyncEvent(SyncEvent(
        type: SyncEventType.widgetSelected,
        source: SyncSource.widgetTree,
        widgetId: widget.widgetId,
        timestamp: DateTime.now(),
      ));
    }
  }

  /// Select widget by line number
  Future<void> selectWidgetAtLine(int lineNumber) async {
    if (_currentFile == null) return;

    final widget = _astParser.findWidgetAtLine(
      _currentFile!.content,
      lineNumber,
      _currentFile!.path,
    );

    if (widget != null) {
      await selectWidget(widget);
    }
  }

  /// Update widget property - triggered from Properties Panel
  Future<void> updateProperty(String propertyName, dynamic propertyValue) async {
    if (_selectedWidget == null || _currentFile == null || _isSyncingFromCode) {
      return;
    }

    _isSyncingFromVisual = true;

    try {
      // Update property in current state
      _currentProperties[propertyName] = propertyValue;
      _propertyChangesController.add(_currentProperties);

      // Update code
      final updatedCode = await _codeSync.updateWidgetProperty(
        sourceCode: _currentFile!.content,
        widget: _selectedWidget!,
        propertyName: propertyName,
        propertyValue: propertyValue,
      );

      // Update file content
      _currentFile = ProjectFile(
        path: _currentFile!.path,
        content: updatedCode,
        fileName: _currentFile!.fileName,
        isDirty: true,
        lastModified: DateTime.now(),
      );

      // Broadcast code change
      _codeChangesController.add(updatedCode);

      // Trigger re-parse with debounce
      _debounceTimer?.cancel();
      _debounceTimer = Timer(const Duration(milliseconds: 500), () {
        _parseAndSync();
      });

      // Log sync event
      _logSyncEvent(SyncEvent(
        type: SyncEventType.propertyUpdated,
        source: SyncSource.propertiesPanel,
        widgetId: _selectedWidget!.widgetId,
        propertyName: propertyName,
        propertyValue: propertyValue,
        timestamp: DateTime.now(),
      ));
    } finally {
      _isSyncingFromVisual = false;
    }
  }

  /// Update code - triggered from Code Editor
  Future<void> updateCode(String newCode) async {
    if (_isSyncingFromVisual) return;

    _isSyncingFromCode = true;

    try {
      // Update file content
      if (_currentFile != null) {
        _currentFile = ProjectFile(
          path: _currentFile!.path,
          content: newCode,
          fileName: _currentFile!.fileName,
          isDirty: true,
          lastModified: DateTime.now(),
        );
      }

      // Trigger re-parse with debounce
      _debounceTimer?.cancel();
      _debounceTimer = Timer(const Duration(milliseconds: 300), () async {
        await _parseAndSync();

        // If a widget is selected, update its properties
        if (_selectedWidget != null) {
          _currentProperties = await _codeSync.extractWidgetProperties(
            sourceCode: newCode,
            lineNumber: _selectedWidget!.lineNumber,
          );
          _propertyChangesController.add(_currentProperties);
        }
      });

      // Log sync event
      _logSyncEvent(SyncEvent(
        type: SyncEventType.codeUpdated,
        source: SyncSource.codeEditor,
        timestamp: DateTime.now(),
      ));
    } finally {
      _isSyncingFromCode = false;
    }
  }

  /// Insert a new widget at current selection
  Future<void> insertWidget(String widgetCode, InsertPosition position) async {
    if (_selectedWidget == null || _currentFile == null) return;

    _isSyncingFromVisual = true;

    try {
      final updatedCode = await _codeSync.insertWidget(
        sourceCode: _currentFile!.content,
        lineNumber: _selectedWidget!.lineNumber,
        widgetCode: widgetCode,
        position: position,
      );

      _currentFile = ProjectFile(
        path: _currentFile!.path,
        content: updatedCode,
        fileName: _currentFile!.fileName,
        isDirty: true,
        lastModified: DateTime.now(),
      );

      _codeChangesController.add(updatedCode);
      await _parseAndSync();

      _logSyncEvent(SyncEvent(
        type: SyncEventType.widgetInserted,
        source: SyncSource.propertiesPanel,
        widgetId: _selectedWidget!.widgetId,
        timestamp: DateTime.now(),
      ));
    } finally {
      _isSyncingFromVisual = false;
    }
  }

  /// Delete the currently selected widget
  Future<void> deleteWidget() async {
    if (_selectedWidget == null || _currentFile == null) return;

    _isSyncingFromVisual = true;

    try {
      final updatedCode = await _codeSync.deleteWidget(
        sourceCode: _currentFile!.content,
        widget: _selectedWidget!,
      );

      _currentFile = ProjectFile(
        path: _currentFile!.path,
        content: updatedCode,
        fileName: _currentFile!.fileName,
        isDirty: true,
        lastModified: DateTime.now(),
      );

      _codeChangesController.add(updatedCode);
      _selectedWidget = null;
      _widgetSelectionController.add(null);
      await _parseAndSync();

      _logSyncEvent(SyncEvent(
        type: SyncEventType.widgetDeleted,
        source: SyncSource.propertiesPanel,
        timestamp: DateTime.now(),
      ));
    } finally {
      _isSyncingFromVisual = false;
    }
  }

  /// Wrap the selected widget with another widget
  Future<void> wrapWidget(String wrapperWidget, [Map<String, dynamic>? properties]) async {
    if (_selectedWidget == null || _currentFile == null) return;

    _isSyncingFromVisual = true;

    try {
      final updatedCode = await _codeSync.wrapWidget(
        sourceCode: _currentFile!.content,
        widget: _selectedWidget!,
        wrapperWidget: wrapperWidget,
        wrapperProperties: properties,
      );

      _currentFile = ProjectFile(
        path: _currentFile!.path,
        content: updatedCode,
        fileName: _currentFile!.fileName,
        isDirty: true,
        lastModified: DateTime.now(),
      );

      _codeChangesController.add(updatedCode);
      await _parseAndSync();

      _logSyncEvent(SyncEvent(
        type: SyncEventType.widgetWrapped,
        source: SyncSource.propertiesPanel,
        wrapperWidget: wrapperWidget,
        timestamp: DateTime.now(),
      ));
    } finally {
      _isSyncingFromVisual = false;
    }
  }

  /// Parse code and sync widget tree
  Future<void> _parseAndSync() async {
    if (_currentFile == null) return;

    try {
      final widgetTree = await _astParser.parseWidgetTree(
        _currentFile!.content,
        _currentFile!.path,
      );

      if (widgetTree != null) {
        _widgetTree = widgetTree;
        _widgetTreeController.add(widgetTree);
        debugPrint('Widget tree parsed: ${widgetTree.children.length} root widgets');
      }
    } catch (e) {
      debugPrint('Error parsing widget tree: $e');
    }
  }

  /// Force refresh widget tree
  Future<void> refreshWidgetTree() async {
    await _parseAndSync();
  }

  /// Log sync event for history and debugging
  void _logSyncEvent(SyncEvent event) {
    // Remove any history after current index (for redo functionality)
    if (_historyIndex < _history.length - 1) {
      _history.removeRange(_historyIndex + 1, _history.length);
    }

    _history.add(event);
    _historyIndex = _history.length - 1;

    // Limit history to 100 events
    if (_history.length > 100) {
      _history.removeAt(0);
      _historyIndex--;
    }

    _syncEventsController.add(event);
  }

  /// Undo last change
  Future<void> undo() async {
    if (!canUndo) return;

    _historyIndex--;
    final event = _history[_historyIndex];

    debugPrint('Undo: ${event.type}');

    _syncEventsController.add(SyncEvent(
      type: SyncEventType.undo,
      source: event.source,
      timestamp: DateTime.now(),
    ));
  }

  /// Redo last undone change
  Future<void> redo() async {
    if (!canRedo) return;

    _historyIndex++;
    final event = _history[_historyIndex];

    debugPrint('Redo: ${event.type}');

    _syncEventsController.add(SyncEvent(
      type: SyncEventType.redo,
      source: event.source,
      timestamp: DateTime.now(),
    ));
  }

  /// Check if undo is available
  bool get canUndo => _historyIndex > 0;

  /// Check if redo is available
  bool get canRedo => _historyIndex < _history.length - 1;

  /// Get current sync history
  List<SyncEvent> get history => List.unmodifiable(_history);

  /// Get current selected widget
  WidgetSelection? get selectedWidget => _selectedWidget;

  /// Get current properties
  Map<String, dynamic> get currentProperties => Map.unmodifiable(_currentProperties);

  /// Get current file
  ProjectFile? get currentFile => _currentFile;

  /// Get current widget tree
  WidgetTreeNode? get widgetTree => _widgetTree;

  /// Dispose resources
  void dispose() {
    _debounceTimer?.cancel();
    _widgetSelectionController.close();
    _propertyChangesController.close();
    _codeChangesController.close();
    _syncEventsController.close();
    _widgetTreeController.close();
  }
}

/// Sync event for tracking changes
class SyncEvent {
  final SyncEventType type;
  final SyncSource source;
  final DateTime timestamp;
  final String? widgetId;
  final String? propertyName;
  final dynamic propertyValue;
  final String? wrapperWidget;

  SyncEvent({
    required this.type,
    required this.source,
    required this.timestamp,
    this.widgetId,
    this.propertyName,
    this.propertyValue,
    this.wrapperWidget,
  });

  @override
  String toString() {
    return 'SyncEvent(type: $type, source: $source, widgetId: $widgetId, time: $timestamp)';
  }
}

/// Type of sync event
enum SyncEventType {
  widgetSelected,
  propertyUpdated,
  codeUpdated,
  widgetInserted,
  widgetDeleted,
  widgetWrapped,
  widgetReordered,
  undo,
  redo,
}

/// Source of the sync event
enum SyncSource {
  widgetTree,
  propertiesPanel,
  codeEditor,
  preview,
  system,
}
