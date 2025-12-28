import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../core/models/widget_node.dart';
import '../../core/models/widget_selection.dart';
import '../../core/services/bidirectional_sync_manager.dart';
import '../../core/services/code_sync_service.dart';

// Events
abstract class EditorEvent extends Equatable {
  const EditorEvent();

  @override
  List<Object?> get props => [];
}

class LoadProject extends EditorEvent {
  final String projectId;
  const LoadProject(this.projectId);

  @override
  List<Object?> get props => [projectId];
}

class SelectWidget extends EditorEvent {
  final WidgetNode? widget;
  const SelectWidget(this.widget);

  @override
  List<Object?> get props => [widget];
}

class UpdateProperty extends EditorEvent {
  final String widgetId;
  final String propertyName;
  final dynamic value;
  const UpdateProperty(this.widgetId, this.propertyName, this.value);

  @override
  List<Object?> get props => [widgetId, propertyName, value];
}

class TogglePanel extends EditorEvent {
  final PanelType panel;
  const TogglePanel(this.panel);

  @override
  List<Object?> get props => [panel];
}

class ChangeViewMode extends EditorEvent {
  final ViewMode mode;
  const ChangeViewMode(this.mode);

  @override
  List<Object?> get props => [mode];
}

class SendAgentMessage extends EditorEvent {
  final String message;
  final List<String>? attachments;
  const SendAgentMessage(this.message, {this.attachments});

  @override
  List<Object?> get props => [message, attachments];
}

class ToggleInspectMode extends EditorEvent {
  const ToggleInspectMode();
}

class UpdateCode extends EditorEvent {
  final String code;
  const UpdateCode(this.code);

  @override
  List<Object?> get props => [code];
}

class LoadFile extends EditorEvent {
  final String filePath;
  final String content;
  const LoadFile(this.filePath, this.content);

  @override
  List<Object?> get props => [filePath, content];
}

class SelectWidgetByLine extends EditorEvent {
  final int lineNumber;
  const SelectWidgetByLine(this.lineNumber);

  @override
  List<Object?> get props => [lineNumber];
}

class InsertWidgetCode extends EditorEvent {
  final String widgetCode;
  final InsertPosition position;
  const InsertWidgetCode(this.widgetCode, this.position);

  @override
  List<Object?> get props => [widgetCode, position];
}

class DeleteSelectedWidget extends EditorEvent {
  const DeleteSelectedWidget();
}

class WrapSelectedWidget extends EditorEvent {
  final String wrapperWidget;
  final Map<String, dynamic>? properties;
  const WrapSelectedWidget(this.wrapperWidget, {this.properties});

  @override
  List<Object?> get props => [wrapperWidget, properties];
}

class RefreshWidgetTree extends EditorEvent {
  const RefreshWidgetTree();
}

// Internal events for sync manager updates
class _UpdateWidgetTreeInternal extends EditorEvent {
  final WidgetTreeNode? astTree;
  final List<WidgetNode> widgetNodes;
  const _UpdateWidgetTreeInternal(this.astTree, this.widgetNodes);
}

class _UpdateSelectionInternal extends EditorEvent {
  final WidgetSelection? selection;
  const _UpdateSelectionInternal(this.selection);
}

class _UpdatePropertiesInternal extends EditorEvent {
  final Map<String, dynamic> properties;
  const _UpdatePropertiesInternal(this.properties);
}

class _UpdateCodeInternal extends EditorEvent {
  final String code;
  const _UpdateCodeInternal(this.code);
}

// States
abstract class EditorState extends Equatable {
  const EditorState();

  @override
  List<Object?> get props => [];
}

class EditorInitial extends EditorState {
  const EditorInitial();
}

class EditorLoading extends EditorState {
  const EditorLoading();
}

class EditorLoaded extends EditorState {
  final List<WidgetNode> widgetTree;
  final WidgetNode? selectedWidget;
  final WidgetTreeNode? astWidgetTree;
  final WidgetSelection? selectedAstWidget;
  final Map<String, dynamic> selectedWidgetProperties;
  final ViewMode viewMode;
  final bool showWidgetTree;
  final bool showProperties;
  final bool showAgent;
  final bool inspectMode;
  final List<ChatMessage> chatMessages;
  final List<FileNode> files;
  final String? currentFile;
  final String? currentFileContent;
  final bool isDirty;

  const EditorLoaded({
    this.widgetTree = const [],
    this.selectedWidget,
    this.astWidgetTree,
    this.selectedAstWidget,
    this.selectedWidgetProperties = const {},
    this.viewMode = ViewMode.preview,
    this.showWidgetTree = true,
    this.showProperties = true,
    this.showAgent = true,
    this.inspectMode = false,
    this.chatMessages = const [],
    this.files = const [],
    this.currentFile,
    this.currentFileContent,
    this.isDirty = false,
  });

  EditorLoaded copyWith({
    List<WidgetNode>? widgetTree,
    WidgetNode? selectedWidget,
    WidgetTreeNode? astWidgetTree,
    WidgetSelection? selectedAstWidget,
    Map<String, dynamic>? selectedWidgetProperties,
    ViewMode? viewMode,
    bool? showWidgetTree,
    bool? showProperties,
    bool? showAgent,
    bool? inspectMode,
    List<ChatMessage>? chatMessages,
    List<FileNode>? files,
    String? currentFile,
    String? currentFileContent,
    bool? isDirty,
    bool clearSelectedWidget = false,
    bool clearAstWidget = false,
  }) {
    return EditorLoaded(
      widgetTree: widgetTree ?? this.widgetTree,
      selectedWidget: clearSelectedWidget ? null : (selectedWidget ?? this.selectedWidget),
      astWidgetTree: clearAstWidget ? null : (astWidgetTree ?? this.astWidgetTree),
      selectedAstWidget: clearSelectedWidget ? null : (selectedAstWidget ?? this.selectedAstWidget),
      selectedWidgetProperties: selectedWidgetProperties ?? this.selectedWidgetProperties,
      viewMode: viewMode ?? this.viewMode,
      showWidgetTree: showWidgetTree ?? this.showWidgetTree,
      showProperties: showProperties ?? this.showProperties,
      showAgent: showAgent ?? this.showAgent,
      inspectMode: inspectMode ?? this.inspectMode,
      chatMessages: chatMessages ?? this.chatMessages,
      files: files ?? this.files,
      currentFile: currentFile ?? this.currentFile,
      currentFileContent: currentFileContent ?? this.currentFileContent,
      isDirty: isDirty ?? this.isDirty,
    );
  }

  @override
  List<Object?> get props => [
        widgetTree,
        selectedWidget,
        astWidgetTree,
        selectedAstWidget,
        selectedWidgetProperties,
        viewMode,
        showWidgetTree,
        showProperties,
        showAgent,
        inspectMode,
        chatMessages,
        files,
        currentFile,
        currentFileContent,
        isDirty,
      ];
}

class EditorError extends EditorState {
  final String message;
  const EditorError(this.message);

  @override
  List<Object?> get props => [message];
}

// BLoC
class EditorBloc extends Bloc<EditorEvent, EditorState> {
  final BidirectionalSyncManager _syncManager = BidirectionalSyncManager.instance;
  StreamSubscription<WidgetTreeNode?>? _widgetTreeSubscription;
  StreamSubscription<WidgetSelection?>? _widgetSelectionSubscription;
  StreamSubscription<Map<String, dynamic>>? _propertySubscription;
  StreamSubscription<String>? _codeSubscription;

  EditorBloc() : super(const EditorInitial()) {
    on<LoadProject>(_onLoadProject);
    on<SelectWidget>(_onSelectWidget);
    on<UpdateProperty>(_onUpdateProperty);
    on<TogglePanel>(_onTogglePanel);
    on<ChangeViewMode>(_onChangeViewMode);
    on<SendAgentMessage>(_onSendAgentMessage);
    on<ToggleInspectMode>(_onToggleInspectMode);
    on<UpdateCode>(_onUpdateCode);
    on<LoadFile>(_onLoadFile);
    on<SelectWidgetByLine>(_onSelectWidgetByLine);
    on<InsertWidgetCode>(_onInsertWidgetCode);
    on<DeleteSelectedWidget>(_onDeleteSelectedWidget);
    on<WrapSelectedWidget>(_onWrapSelectedWidget);
    on<RefreshWidgetTree>(_onRefreshWidgetTree);
    on<_UpdateWidgetTreeInternal>(_onUpdateWidgetTreeInternal);
    on<_UpdateSelectionInternal>(_onUpdateSelectionInternal);
    on<_UpdatePropertiesInternal>(_onUpdatePropertiesInternal);
    on<_UpdateCodeInternal>(_onUpdateCodeInternal);

    _initSyncManagerListeners();
  }

  void _initSyncManagerListeners() {
    _widgetTreeSubscription = _syncManager.widgetTreeStream.listen((tree) {
      if (state is EditorLoaded) {
        // Convert AST tree to UI widget nodes for backward compatibility
        final widgetNodes = tree != null ? _convertAstToWidgetNodes(tree) : <WidgetNode>[];
        add(_UpdateWidgetTreeInternal(tree, widgetNodes));
      }
    });

    _widgetSelectionSubscription = _syncManager.widgetSelectionStream.listen((selection) {
      if (state is EditorLoaded) {
        add(_UpdateSelectionInternal(selection));
      }
    });

    _propertySubscription = _syncManager.propertyChangesStream.listen((properties) {
      if (state is EditorLoaded) {
        add(_UpdatePropertiesInternal(properties));
      }
    });

    _codeSubscription = _syncManager.codeChangesStream.listen((code) {
      if (state is EditorLoaded) {
        add(_UpdateCodeInternal(code));
      }
    });
  }

  /// Convert AST WidgetTreeNode to UI WidgetNode
  List<WidgetNode> _convertAstToWidgetNodes(WidgetTreeNode astNode, [String? parentId]) {
    final nodes = <WidgetNode>[];

    for (final child in astNode.children) {
      final nodeId = '${child.name}_${child.line}';
      final node = WidgetNode(
        id: nodeId,
        type: child.name,
        name: child.name,
        properties: child.properties,
        parentId: parentId,
        children: _convertAstToWidgetNodes(child, nodeId),
      );
      nodes.add(node);
    }

    return nodes;
  }

  @override
  Future<void> close() {
    _widgetTreeSubscription?.cancel();
    _widgetSelectionSubscription?.cancel();
    _propertySubscription?.cancel();
    _codeSubscription?.cancel();
    return super.close();
  }

  Future<void> _onLoadProject(
    LoadProject event,
    Emitter<EditorState> emit,
  ) async {
    emit(const EditorLoading());
    try {
      // Load sample widget tree
      final sampleTree = [
        WidgetNode(
          id: '1',
          type: 'Scaffold',
          name: 'Scaffold',
          children: [
            WidgetNode(
              id: '2',
              type: 'AppBar',
              name: 'AppBar',
              parentId: '1',
              properties: {'title': 'My App'},
            ),
            WidgetNode(
              id: '3',
              type: 'Column',
              name: 'Body',
              parentId: '1',
              children: [
                WidgetNode(
                  id: '4',
                  type: 'Text',
                  name: 'Title Text',
                  parentId: '3',
                  properties: {'text': 'Hello World', 'style': 'headlineMedium'},
                ),
                WidgetNode(
                  id: '5',
                  type: 'Button',
                  name: 'Action Button',
                  parentId: '3',
                  properties: {'text': 'Click Me', 'onPressed': null},
                ),
              ],
            ),
          ],
        ),
      ];

      final sampleFiles = [
        FileNode(
          name: 'lib',
          path: 'lib',
          isDirectory: true,
          isExpanded: true,
          children: [
            const FileNode(name: 'main.dart', path: 'lib/main.dart'),
            FileNode(
              name: 'screens',
              path: 'lib/screens',
              isDirectory: true,
              children: const [
                FileNode(name: 'home_screen.dart', path: 'lib/screens/home_screen.dart'),
              ],
            ),
          ],
        ),
      ];

      emit(EditorLoaded(
        widgetTree: sampleTree,
        files: sampleFiles,
      ));
    } catch (e) {
      emit(EditorError(e.toString()));
    }
  }

  void _onSelectWidget(SelectWidget event, Emitter<EditorState> emit) {
    if (state is EditorLoaded) {
      emit((state as EditorLoaded).copyWith(selectedWidget: event.widget));
    }
  }

  void _onUpdateProperty(UpdateProperty event, Emitter<EditorState> emit) {
    // TODO: Implement property update logic
  }

  void _onTogglePanel(TogglePanel event, Emitter<EditorState> emit) {
    if (state is EditorLoaded) {
      final currentState = state as EditorLoaded;
      switch (event.panel) {
        case PanelType.widgetTree:
          emit(currentState.copyWith(showWidgetTree: !currentState.showWidgetTree));
          break;
        case PanelType.properties:
          emit(currentState.copyWith(showProperties: !currentState.showProperties));
          break;
        case PanelType.agent:
          emit(currentState.copyWith(showAgent: !currentState.showAgent));
          break;
      }
    }
  }

  void _onChangeViewMode(ChangeViewMode event, Emitter<EditorState> emit) {
    if (state is EditorLoaded) {
      emit((state as EditorLoaded).copyWith(viewMode: event.mode));
    }
  }

  Future<void> _onSendAgentMessage(
    SendAgentMessage event,
    Emitter<EditorState> emit,
  ) async {
    if (state is EditorLoaded) {
      final currentState = state as EditorLoaded;
      final userMessage = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: event.message,
        isUser: true,
        timestamp: DateTime.now(),
        attachments: event.attachments,
      );

      emit(currentState.copyWith(
        chatMessages: [...currentState.chatMessages, userMessage],
      ));

      // Simulate AI response
      await Future.delayed(const Duration(seconds: 1));

      final aiMessage = ChatMessage(
        id: (DateTime.now().millisecondsSinceEpoch + 1).toString(),
        content: 'I understand you want to "${event.message}". Let me help you with that...',
        isUser: false,
        timestamp: DateTime.now(),
      );

      emit((state as EditorLoaded).copyWith(
        chatMessages: [...(state as EditorLoaded).chatMessages, aiMessage],
      ));
    }
  }

  void _onToggleInspectMode(ToggleInspectMode event, Emitter<EditorState> emit) {
    if (state is EditorLoaded) {
      final currentState = state as EditorLoaded;
      emit(currentState.copyWith(inspectMode: !currentState.inspectMode));
    }
  }

  // New handlers for code sync
  Future<void> _onUpdateCode(UpdateCode event, Emitter<EditorState> emit) async {
    if (state is EditorLoaded) {
      await _syncManager.updateCode(event.code);
    }
  }

  Future<void> _onLoadFile(LoadFile event, Emitter<EditorState> emit) async {
    if (state is EditorLoaded) {
      final currentState = state as EditorLoaded;
      final projectFile = ProjectFile(
        path: event.filePath,
        content: event.content,
        fileName: event.filePath.split('/').last,
      );
      await _syncManager.setCurrentFile(projectFile);
      emit(currentState.copyWith(
        currentFile: event.filePath,
        currentFileContent: event.content,
      ));
    }
  }

  Future<void> _onSelectWidgetByLine(SelectWidgetByLine event, Emitter<EditorState> emit) async {
    await _syncManager.selectWidgetAtLine(event.lineNumber);
  }

  Future<void> _onInsertWidgetCode(InsertWidgetCode event, Emitter<EditorState> emit) async {
    await _syncManager.insertWidget(event.widgetCode, event.position);
  }

  Future<void> _onDeleteSelectedWidget(DeleteSelectedWidget event, Emitter<EditorState> emit) async {
    await _syncManager.deleteWidget();
  }

  Future<void> _onWrapSelectedWidget(WrapSelectedWidget event, Emitter<EditorState> emit) async {
    await _syncManager.wrapWidget(event.wrapperWidget, event.properties);
  }

  Future<void> _onRefreshWidgetTree(RefreshWidgetTree event, Emitter<EditorState> emit) async {
    await _syncManager.refreshWidgetTree();
  }

  // Internal handlers for sync manager updates
  void _onUpdateWidgetTreeInternal(_UpdateWidgetTreeInternal event, Emitter<EditorState> emit) {
    if (state is EditorLoaded) {
      final currentState = state as EditorLoaded;
      emit(currentState.copyWith(
        astWidgetTree: event.astTree,
        widgetTree: event.widgetNodes,
      ));
    }
  }

  void _onUpdateSelectionInternal(_UpdateSelectionInternal event, Emitter<EditorState> emit) {
    if (state is EditorLoaded) {
      final currentState = state as EditorLoaded;
      emit(currentState.copyWith(
        selectedAstWidget: event.selection,
      ));
    }
  }

  void _onUpdatePropertiesInternal(_UpdatePropertiesInternal event, Emitter<EditorState> emit) {
    if (state is EditorLoaded) {
      final currentState = state as EditorLoaded;
      emit(currentState.copyWith(
        selectedWidgetProperties: event.properties,
      ));
    }
  }

  void _onUpdateCodeInternal(_UpdateCodeInternal event, Emitter<EditorState> emit) {
    if (state is EditorLoaded) {
      final currentState = state as EditorLoaded;
      emit(currentState.copyWith(
        currentFileContent: event.code,
        isDirty: true,
      ));
    }
  }
}
