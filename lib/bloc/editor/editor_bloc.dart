import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../core/models/widget_node.dart';
import '../../core/models/widget_selection.dart';
import '../../core/models/app_spec.dart';
import '../../core/services/bidirectional_sync_manager.dart';

import '../../core/services/code_sync_service.dart';
import '../../core/services/project_manager_service.dart';
import '../../core/services/ai_agent_service.dart';
import '../../core/services/terminal_service.dart';
import '../../core/services/git_service.dart';
import '../../core/services/app_generation_service.dart';
import '../../core/services/config_service.dart';
import '../../core/templates/project_templates.dart';

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

class LoadProjectFromZip extends EditorEvent {
  const LoadProjectFromZip();
}

class LoadProjectFromDirectory extends EditorEvent {
  const LoadProjectFromDirectory();
}

class SelectProjectFile extends EditorEvent {
  final FileNode file;
  const SelectProjectFile(this.file);

  @override
  List<Object?> get props => [file];
}

class ToggleFileExpand extends EditorEvent {
  final FileNode file;
  const ToggleFileExpand(this.file);

  @override
  List<Object?> get props => [file];
}

class SaveFile extends EditorEvent {
  const SaveFile();
}

class CreateFile extends EditorEvent {
  final String fileName;
  final String parentPath;
  const CreateFile(this.fileName, this.parentPath);

  @override
  List<Object?> get props => [fileName, parentPath];
}

class CreateDirectory extends EditorEvent {
  final String dirName;
  final String parentPath;
  const CreateDirectory(this.dirName, this.parentPath);

  @override
  List<Object?> get props => [dirName, parentPath];
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

class Undo extends EditorEvent {
  const Undo();
}

class Redo extends EditorEvent {
  const Redo();
}

class _UpdateCanUndoRedoInternal extends EditorEvent {
  final bool canUndo;
  final bool canRedo;
  const _UpdateCanUndoRedoInternal(this.canUndo, this.canRedo);
}

class _UpdateAiMessageChunk extends EditorEvent {
  final String messageId;
  final String chunk;
  const _UpdateAiMessageChunk(this.messageId, this.chunk);
}

class RunProject extends EditorEvent {
  const RunProject();
}

class HotReload extends EditorEvent {
  const HotReload();
}

class _UpdateTerminalOutput extends EditorEvent {
  final String output;
  const _UpdateTerminalOutput(this.output);
}

class GitCheckStatus extends EditorEvent {
  const GitCheckStatus();
}

class GitStageFile extends EditorEvent {
  final String path;
  const GitStageFile(this.path);
}

class GitUnstageFile extends EditorEvent {
  final String path;
  const GitUnstageFile(this.path);
}

class GitCommit extends EditorEvent {
  final String message;
  const GitCommit(this.message);
}

class GitPush extends EditorEvent {
  const GitPush();
}

// New Project Creation Events
class CreateNewProject extends EditorEvent {
  final String name;
  final String outputPath;
  final ProjectTemplate template;
  final StateManagement stateManagement;
  final String? organization;
  const CreateNewProject({
    required this.name,
    required this.outputPath,
    this.template = ProjectTemplate.blank,
    this.stateManagement = StateManagement.provider,
    this.organization,
  });

  @override
  List<Object?> get props => [name, outputPath, template, stateManagement, organization];
}

class GenerateAppFromPrompt extends EditorEvent {
  final String prompt;
  final String projectName;
  final String outputPath;
  final String? organization;
  const GenerateAppFromPrompt({
    required this.prompt,
    required this.projectName,
    required this.outputPath,
    this.organization,
  });

  @override
  List<Object?> get props => [prompt, projectName, outputPath, organization];
}

class StopRunningApp extends EditorEvent {
  const StopRunningApp();
}

class ConfigureOpenAI extends EditorEvent {
  final String apiKey;
  final String? model;
  const ConfigureOpenAI({required this.apiKey, this.model});

  @override
  List<Object?> get props => [apiKey, model];
}

class ClearOpenAIConfig extends EditorEvent {
  const ClearOpenAIConfig();
}

class _AppGenerationProgress extends EditorEvent {
  final GenerationProgress progress;
  const _AppGenerationProgress(this.progress);
}

class _ProjectCreationProgress extends EditorEvent {
  final String message;
  const _ProjectCreationProgress(this.message);
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
  final String? projectName;
  final FlutterProject? project;
  final bool isLoadingProject;

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
    this.projectName,
    this.project,
    this.isLoadingProject = false,

    this.canUndo = false,
    this.canRedo = false,
    this.isAppRunning = false,
    this.terminalOutput = const [],
    this.gitStatus,
    this.isGitLoading = false,
    this.isCreatingProject = false,
    this.isGeneratingApp = false,
    this.generationLog = const [],
    this.generationProgress = 0.0,
    this.generationStatus,
    this.currentAppSpec,
    this.isOpenAIConfigured = false,
  });

  final bool canUndo;
  final bool canRedo;
  final bool isAppRunning;
  final List<String> terminalOutput;
  final GitStatus? gitStatus;
  final bool isGitLoading;

  // New properties for project creation and AI generation
  final bool isCreatingProject;
  final bool isGeneratingApp;
  final List<String> generationLog;
  final double generationProgress;
  final String? generationStatus;
  final AppSpec? currentAppSpec;
  final bool isOpenAIConfigured;

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
    String? projectName,
    FlutterProject? project,
    bool? isLoadingProject,
    bool? canUndo,
    bool? canRedo,
    bool? isAppRunning,
    List<String>? terminalOutput,
    bool clearSelectedWidget = false,
    bool clearAstWidget = false,
    GitStatus? gitStatus,
    bool? isGitLoading,
    bool? isCreatingProject,
    bool? isGeneratingApp,
    List<String>? generationLog,
    double? generationProgress,
    String? generationStatus,
    AppSpec? currentAppSpec,
    bool? isOpenAIConfigured,
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
      projectName: projectName ?? this.projectName,
      project: project ?? this.project,
      isLoadingProject: isLoadingProject ?? this.isLoadingProject,
      canUndo: canUndo ?? this.canUndo,
      canRedo: canRedo ?? this.canRedo,
      isAppRunning: isAppRunning ?? this.isAppRunning,
      terminalOutput: terminalOutput ?? this.terminalOutput,
      gitStatus: gitStatus ?? this.gitStatus,
      isGitLoading: isGitLoading ?? this.isGitLoading,
      isCreatingProject: isCreatingProject ?? this.isCreatingProject,
      isGeneratingApp: isGeneratingApp ?? this.isGeneratingApp,
      generationLog: generationLog ?? this.generationLog,
      generationProgress: generationProgress ?? this.generationProgress,
      generationStatus: generationStatus ?? this.generationStatus,
      currentAppSpec: currentAppSpec ?? this.currentAppSpec,
      isOpenAIConfigured: isOpenAIConfigured ?? this.isOpenAIConfigured,
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
        projectName,
        project,
        isLoadingProject,
        canUndo,
        canRedo,
        isAppRunning,
        terminalOutput,
        gitStatus,
        isGitLoading,
        isCreatingProject,
        isGeneratingApp,
        generationLog,
        generationProgress,
        generationStatus,
        currentAppSpec,
        isOpenAIConfigured,
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
  final ProjectManagerService _projectManager = ProjectManagerService.instance;
  final AIAgentService _aiAgentService = AIAgentService.instance;
  final TerminalService _terminalService = TerminalService.instance;
  final GitService _gitService = GitService();
  final AppGenerationService _appGenerationService = AppGenerationService.instance;
  final ConfigService _configService = ConfigService.instance;
  StreamSubscription<WidgetTreeNode?>? _widgetTreeSubscription;
  StreamSubscription<WidgetSelection?>? _widgetSelectionSubscription;
  StreamSubscription<Map<String, dynamic>>? _propertySubscription;
  StreamSubscription<String>? _codeSubscription;
  StreamSubscription<SyncEvent>? _syncEventSubscription;

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
    on<LoadProjectFromZip>(_onLoadProjectFromZip);
    on<LoadProjectFromDirectory>(_onLoadProjectFromDirectory);
    on<SelectProjectFile>(_onSelectProjectFile);
    on<ToggleFileExpand>(_onToggleFileExpand);
    on<SaveFile>(_onSaveFile);
    on<CreateFile>(_onCreateFile);
    on<CreateDirectory>(_onCreateDirectory);
    on<_UpdateWidgetTreeInternal>(_onUpdateWidgetTreeInternal);
    on<_UpdateSelectionInternal>(_onUpdateSelectionInternal);

    on<_UpdatePropertiesInternal>(_onUpdatePropertiesInternal);
    on<_UpdateCodeInternal>(_onUpdateCodeInternal);
    on<Undo>(_onUndo);
    on<Redo>(_onRedo);
    on<_UpdateCanUndoRedoInternal>(_onUpdateCanUndoRedoInternal);

    on<_UpdateAiMessageChunk>(_onUpdateAiMessageChunk);
    on<RunProject>(_onRunProject);
    on<HotReload>(_onHotReload);
    on<_UpdateTerminalOutput>(_onUpdateTerminalOutput);

    on<GitCheckStatus>(_onGitCheckStatus);
    on<GitStageFile>(_onGitStageFile);
    on<GitUnstageFile>(_onGitUnstageFile);
    on<GitCommit>(_onGitCommit);
    on<GitPush>(_onGitPush);

    // New project creation and AI generation handlers
    on<CreateNewProject>(_onCreateNewProject);
    on<GenerateAppFromPrompt>(_onGenerateAppFromPrompt);
    on<StopRunningApp>(_onStopRunningApp);
    on<ConfigureOpenAI>(_onConfigureOpenAI);
    on<ClearOpenAIConfig>(_onClearOpenAIConfig);
    on<_AppGenerationProgress>(_onAppGenerationProgress);
    on<_ProjectCreationProgress>(_onProjectCreationProgress);

    _initSyncManagerListeners();
    _initOpenAIStatus();
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

    _syncEventSubscription = _syncManager.syncEventsStream.listen((event) {
      if (state is EditorLoaded) {
        add(_UpdateCanUndoRedoInternal(
          _syncManager.canUndo,
          _syncManager.canRedo,
        ));
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
    _syncEventSubscription?.cancel();
    return super.close();
  }

  Future<void> _onLoadProject(
    LoadProject event,
    Emitter<EditorState> emit,
  ) async {
    emit(const EditorLoading());
    try {
      // Start with empty state - user will load a project via Open Project button
      emit(const EditorLoaded());
    } catch (e) {
      emit(EditorError(e.toString()));
    }
  }

  Future<void> _onSelectWidget(SelectWidget event, Emitter<EditorState> emit) async {
    if (state is EditorLoaded) {
      emit((state as EditorLoaded).copyWith(selectedWidget: event.widget));
      
      // Sync with AST selection if widget has a valid ID (format: type_line)
      if (event.widget?.id != null) {
        try {
          final parts = event.widget!.id.split('_');
          if (parts.length >= 2) {
            final line = int.parse(parts.last);
            await _syncManager.selectWidgetAtLine(line);
          }
        } catch (e) {
          debugPrint('Error syncing selection: $e');
        }
      }
    }
  }

  Future<void> _onUpdateProperty(UpdateProperty event, Emitter<EditorState> emit) async {
    if (state is EditorLoaded) {
       await _syncManager.updateProperty(event.propertyName, event.value);
    }
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

      final aiMessageId = (DateTime.now().millisecondsSinceEpoch + 1).toString();
      final aiMessage = ChatMessage(
        id: aiMessageId,
        content: '', // Start empty
        isUser: false,
        timestamp: DateTime.now(),
      );

      // Add empty AI message
      emit(currentState.copyWith(
        chatMessages: [...currentState.chatMessages, userMessage, aiMessage],
      ));

      // Create context
      final context = EditorContext(
        currentFile: currentState.currentFile,
        currentCode: currentState.currentFileContent,
        selectedWidget: currentState.selectedWidget,
        selectedAstWidget: currentState.selectedAstWidget,
      );

      // Listen to stream
      await for (final chunk in _aiAgentService.sendMessage(event.message, context: context)) {
        add(_UpdateAiMessageChunk(aiMessageId, chunk));
      }
    }
  }

  void _onUpdateAiMessageChunk(
    _UpdateAiMessageChunk event,
    Emitter<EditorState> emit,
  ) {
    if (state is EditorLoaded) {
      final currentState = state as EditorLoaded;
      final updatedMessages = currentState.chatMessages.map((msg) {
        if (msg.id == event.messageId) {
          return ChatMessage(
            id: msg.id,
            content: msg.content + event.chunk,
            isUser: msg.isUser,
            timestamp: msg.timestamp,
            attachments: msg.attachments,
          );
        }
        return msg;
      }).toList();

      emit(currentState.copyWith(chatMessages: updatedMessages));
    }
  }

  Future<void> _onRunProject(RunProject event, Emitter<EditorState> emit) async {
    if (state is EditorLoaded) {
      final currentState = state as EditorLoaded;
      emit(currentState.copyWith(
        isAppRunning: true,
        terminalOutput: ['> flutter run -d macos\n'],
      ));

      final projectPath = currentState.project?.path ?? '';
      await for (final output in _terminalService.runProject(projectPath: projectPath)) {
        add(_UpdateTerminalOutput(output));
      }
    }
  }

  Future<void> _onHotReload(HotReload event, Emitter<EditorState> emit) async {
    if (state is EditorLoaded) {
      add(_UpdateTerminalOutput('> Hot reloading...\n'));
      await _terminalService.hotReload();
      add(_UpdateTerminalOutput('Hot reload complete.\n'));
    }
  }

  void _onUpdateTerminalOutput(_UpdateTerminalOutput event, Emitter<EditorState> emit) {
    if (state is EditorLoaded) {
      final currentState = state as EditorLoaded;
      emit(currentState.copyWith(
        terminalOutput: [...currentState.terminalOutput, event.output],
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

  // Project loading handlers
  Future<void> _onLoadProjectFromZip(
    LoadProjectFromZip event,
    Emitter<EditorState> emit,
  ) async {
    if (state is EditorLoaded) {
      final currentState = state as EditorLoaded;
      emit(currentState.copyWith(isLoadingProject: true));

      try {
        final project = await _projectManager.loadProjectFromZip();
        if (project != null) {
          final fileTree = _projectManager.getProjectFileTree();

          // Auto-select main.dart if available
          String? mainContent;
          String? mainPath;
          WidgetTreeNode? astTree;
          List<WidgetNode> widgetNodes = [];

          final mainFile = project.mainFile;
          if (mainFile != null) {
            mainContent = mainFile.content;
            mainPath = mainFile.path;

            // Parse the main file for widget tree
            final projectFile = ProjectFile(
              path: mainFile.path,
              content: mainFile.content,
            );
            await _syncManager.setCurrentFile(projectFile);

            // Get the parsed widget tree directly from sync manager
            astTree = _syncManager.widgetTree;
            if (astTree != null) {
              debugPrint('ZIP: AST Tree loaded: ${astTree.name} with ${astTree.children.length} children');
              _debugPrintTree(astTree, 0);
              widgetNodes = _convertAstToWidgetNodes(astTree);
            } else {
              debugPrint('ZIP: AST Tree is null after parsing');
            }
          }

          emit(currentState.copyWith(
            isLoadingProject: false,
            project: project,
            projectName: project.name,
            files: fileTree,
            currentFile: mainPath,
            currentFileContent: mainContent,
            astWidgetTree: astTree,
            widgetTree: widgetNodes,
          ));
        } else {
          emit(currentState.copyWith(isLoadingProject: false));
        }
      } catch (e) {
        debugPrint('Error loading project from ZIP: $e');
        emit(currentState.copyWith(isLoadingProject: false));
      }
    }
  }

  Future<void> _onLoadProjectFromDirectory(
    LoadProjectFromDirectory event,
    Emitter<EditorState> emit,
  ) async {
    if (state is EditorLoaded) {
      final currentState = state as EditorLoaded;
      emit(currentState.copyWith(isLoadingProject: true));

      try {
        final project = await _projectManager.loadProjectFromDirectory();
        if (project != null) {
          final fileTree = _projectManager.getProjectFileTree();

          // Auto-select main.dart if available
          String? mainContent;
          String? mainPath;
          WidgetTreeNode? astTree;
          List<WidgetNode> widgetNodes = [];

          final mainFile = project.mainFile;
          if (mainFile != null) {
            mainContent = mainFile.content;
            mainPath = mainFile.path;

            // Parse the main file for widget tree
            final projectFile = ProjectFile(
              path: mainFile.path,
              content: mainFile.content,
            );
            await _syncManager.setCurrentFile(projectFile);

            // Get the parsed widget tree directly from sync manager
            astTree = _syncManager.widgetTree;
            if (astTree != null) {
              debugPrint('DIR: AST Tree loaded: ${astTree.name} with ${astTree.children.length} children');
              _debugPrintTree(astTree, 0);
              widgetNodes = _convertAstToWidgetNodes(astTree);
            } else {
              debugPrint('DIR: AST Tree is null after parsing');
            }
          }

          emit(currentState.copyWith(
            isLoadingProject: false,
            project: project,
            projectName: project.name,
            files: fileTree,
            currentFile: mainPath,
            currentFileContent: mainContent,
            astWidgetTree: astTree,
            widgetTree: widgetNodes,
          ));
        } else {
          emit(currentState.copyWith(isLoadingProject: false));
        }
      } catch (e) {
        debugPrint('Error loading project from directory: $e');
        emit(currentState.copyWith(isLoadingProject: false));
      }
    }
  }

  Future<void> _onSelectProjectFile(
    SelectProjectFile event,
    Emitter<EditorState> emit,
  ) async {
    if (state is EditorLoaded && !event.file.isDirectory) {
      final currentState = state as EditorLoaded;
      final content = _projectManager.getFileContent(event.file.path);

      if (content != null) {
        // Update sync manager with new file
        final projectFile = ProjectFile(
          path: event.file.path,
          content: content,
        );
        await _syncManager.setCurrentFile(projectFile);

        // Get the parsed widget tree for the selected file
        final astTree = _syncManager.widgetTree;
        List<WidgetNode> widgetNodes = [];
        if (astTree != null) {
          debugPrint('FILE: AST Tree loaded: ${astTree.name} with ${astTree.children.length} children');
          _debugPrintTree(astTree, 0);
          widgetNodes = _convertAstToWidgetNodes(astTree);
        }

        emit(currentState.copyWith(
          currentFile: event.file.path,
          currentFileContent: content,
          astWidgetTree: astTree,
          widgetTree: widgetNodes,
        ));
      }
    }
  }

  void _onToggleFileExpand(
    ToggleFileExpand event,
    Emitter<EditorState> emit,
  ) {
    if (state is EditorLoaded) {
      final currentState = state as EditorLoaded;
      final updatedFiles = _toggleFileExpand(currentState.files, event.file.path);
      emit(currentState.copyWith(files: updatedFiles));
    }
  }

  List<FileNode> _toggleFileExpand(List<FileNode> nodes, String path) {
    return nodes.map((node) {
      if (node.path == path) {
        return node.copyWith(isExpanded: !node.isExpanded);
      }
      if (node.isDirectory && node.children.isNotEmpty) {
        return node.copyWith(
          children: _toggleFileExpand(node.children, path),
        );
      }
      return node;
    }).toList();
  }

  Future<void> _onSaveFile(SaveFile event, Emitter<EditorState> emit) async {
    if (state is EditorLoaded) {
      final currentState = state as EditorLoaded;
      if (currentState.currentFile != null && currentState.currentFileContent != null) {
        try {
          await _projectManager.saveFile(
            currentState.currentFile!,
            currentState.currentFileContent!,
          );
          emit(currentState.copyWith(isDirty: false));
        } catch (e) {
          debugPrint('Error saving file: $e');
        }
      }
    }
  }

  Future<void> _onUndo(Undo event, Emitter<EditorState> emit) async {
    await _syncManager.undo();
  }

  Future<void> _onRedo(Redo event, Emitter<EditorState> emit) async {
    await _syncManager.redo();
  }

  void _onUpdateCanUndoRedoInternal(
    _UpdateCanUndoRedoInternal event,
    Emitter<EditorState> emit,
  ) {
    if (state is EditorLoaded) {
      emit((state as EditorLoaded).copyWith(
        canUndo: event.canUndo,
        canRedo: event.canRedo,
      ));
    }
  }


  Future<void> _onCreateFile(CreateFile event, Emitter<EditorState> emit) async {
    if (state is EditorLoaded) {
      final currentState = state as EditorLoaded;
      try {
        await _projectManager.createFile(event.fileName, event.parentPath);
        // Refresh file tree
        final fileTree = _projectManager.getProjectFileTree();
        emit(currentState.copyWith(files: fileTree));
      } catch (e) {
         debugPrint('Error creating file: $e');
      }
    }
  }

  Future<void> _onCreateDirectory(CreateDirectory event, Emitter<EditorState> emit) async {
    if (state is EditorLoaded) {
      final currentState = state as EditorLoaded;
      try {
        await _projectManager.createDirectory(event.dirName, event.parentPath);
        // Refresh file tree
        final fileTree = _projectManager.getProjectFileTree();
        emit(currentState.copyWith(files: fileTree));
      } catch (e) {
        debugPrint('Error creating directory: $e');
      }
    }
  }

  // Git Handlers
  Future<void> _onGitCheckStatus(GitCheckStatus event, Emitter<EditorState> emit) async {
    if (state is EditorLoaded) {
      final currentState = state as EditorLoaded;
      emit(currentState.copyWith(isGitLoading: true));
      
      try {
        // Ensure working directory is set
        final project = currentState.project;
        if (project != null) {
          // Assuming project path is the parent of passed main file or similar
          // Ideally ProjectManager stores the root path. 
          // For now, we'll try to use the project path from the project manager if available, 
          // or assume current directory if we started from there.
           
           // In a real app we'd explicitly track project root
           // For this MVP, let's look at the first file in files list for context
           if (currentState.files.isNotEmpty) {
             final rootPath = currentState.files.first.path.split('/').sublist(0, currentState.files.first.path.split('/').length - 1).join('/'); // rough estimation
             // Better: use the project path passed during load
              final projectPath = _projectManager.currentProjectPath;
              if (projectPath != null) {
                _gitService.setWorkingDirectory(projectPath);
                
                // Init if needed (though UI handles this button usually)
                final isRepo = await _gitService.isGitRepository();
                if (isRepo) {
                  final status = await _gitService.getStatus();
                  emit(currentState.copyWith(
                    gitStatus: status,
                    isGitLoading: false,
                  ));
                } else {
                   // Not a repo, maybe we should init? or just show empty
                   emit(currentState.copyWith(isGitLoading: false));
                }
              }
           }
        }
      } catch (e) {
        debugPrint('Git Check Status Error: $e');
        emit(currentState.copyWith(isGitLoading: false));
      }
    }
  }

  Future<void> _onGitStageFile(GitStageFile event, Emitter<EditorState> emit) async {
    if (state is EditorLoaded) {
      try {
        await _gitService.stageFile(event.path);
        // Refresh status
        add(const GitCheckStatus());
      } catch (e) {
        debugPrint('Git Stage Error: $e');
      }
    }
  }

  Future<void> _onGitUnstageFile(GitUnstageFile event, Emitter<EditorState> emit) async {
    if (state is EditorLoaded) {
      try {
        await _gitService.unstageFile(event.path);
        add(const GitCheckStatus());
      } catch (e) {
        debugPrint('Git Unstage Error: $e');
      }
    }
  }
  
  Future<void> _onGitCommit(GitCommit event, Emitter<EditorState> emit) async {
    if (state is EditorLoaded) {
      try {
        await _gitService.commit(event.message);
        add(const GitCheckStatus());
        add(_UpdateTerminalOutput('Git Commit: ${event.message}\n'));
      } catch (e) {
         debugPrint('Git Commit Error: $e');
         add(_UpdateTerminalOutput('Git Commit Error: $e\n'));
      }
    }
  }

  Future<void> _onGitPush(GitPush event, Emitter<EditorState> emit) async {
    if (state is EditorLoaded) {
       final currentState = state as EditorLoaded;
       emit(currentState.copyWith(isGitLoading: true));
       add(_UpdateTerminalOutput('Pushing to remote...\n'));
      try {
        await _gitService.push();
        add(const GitCheckStatus());
        add(const _UpdateTerminalOutput('Git Push Successful!\n'));
        emit(currentState.copyWith(isGitLoading: false));
      } catch (e) {
        debugPrint('Git Push Error: $e');
        add(_UpdateTerminalOutput('Git Push Error: $e\n'));
        emit(currentState.copyWith(isGitLoading: false));
      }
    }
  }

  void _debugPrintTree(WidgetTreeNode node, int depth) {
    final indent = '  ' * depth;
    debugPrint('$indent- ${node.name} (children: ${node.children.length})');
    for (final child in node.children) {
      _debugPrintTree(child, depth + 1);
    }
  }

  // Initialize OpenAI status check
  Future<void> _initOpenAIStatus() async {
    final isConfigured = await _configService.isOpenAIConfigured();
    if (state is EditorLoaded) {
      // ignore: invalid_use_of_visible_for_testing_member
      emit((state as EditorLoaded).copyWith(isOpenAIConfigured: isConfigured));
    }
  }

  // New Project Creation Handler
  Future<void> _onCreateNewProject(
    CreateNewProject event,
    Emitter<EditorState> emit,
  ) async {
    if (state is EditorLoaded) {
      final currentState = state as EditorLoaded;
      emit(currentState.copyWith(
        isCreatingProject: true,
        generationLog: ['Starting project creation...'],
        generationProgress: 0.0,
        generationStatus: 'Creating project...',
      ));

      await for (final message in _projectManager.createNewProject(
        name: event.name,
        outputPath: event.outputPath,
        template: event.template,
        stateManagement: event.stateManagement,
        organization: event.organization,
      )) {
        add(_ProjectCreationProgress(message));
      }

      // Load the created project
      if (_projectManager.currentProject != null) {
        final fileTree = _projectManager.getProjectFileTree();
        final project = _projectManager.currentProject!;

        emit((state as EditorLoaded).copyWith(
          isCreatingProject: false,
          generationProgress: 1.0,
          generationStatus: 'Complete!',
          project: project,
          projectName: project.name,
          files: fileTree,
        ));
      } else {
        emit((state as EditorLoaded).copyWith(
          isCreatingProject: false,
          generationStatus: 'Failed to create project',
        ));
      }
    }
  }

  void _onProjectCreationProgress(
    _ProjectCreationProgress event,
    Emitter<EditorState> emit,
  ) {
    if (state is EditorLoaded) {
      final currentState = state as EditorLoaded;
      emit(currentState.copyWith(
        generationLog: [...currentState.generationLog, event.message],
      ));
    }
  }

  // AI App Generation Handler
  Future<void> _onGenerateAppFromPrompt(
    GenerateAppFromPrompt event,
    Emitter<EditorState> emit,
  ) async {
    if (state is EditorLoaded) {
      final currentState = state as EditorLoaded;
      emit(currentState.copyWith(
        isGeneratingApp: true,
        generationLog: ['Starting AI app generation...'],
        generationProgress: 0.0,
        generationStatus: 'Initializing...',
      ));

      await for (final progress in _appGenerationService.generateAppFromPrompt(
        prompt: event.prompt,
        projectName: event.projectName,
        outputPath: event.outputPath,
        organization: event.organization,
      )) {
        add(_AppGenerationProgress(progress));
      }
    }
  }

  void _onAppGenerationProgress(
    _AppGenerationProgress event,
    Emitter<EditorState> emit,
  ) {
    if (state is EditorLoaded) {
      final currentState = state as EditorLoaded;
      final progress = event.progress;

      emit(currentState.copyWith(
        generationLog: [...currentState.generationLog, progress.message],
        generationProgress: progress.progress,
        generationStatus: progress.message,
        isGeneratingApp: progress.phase != GenerationPhase.complete &&
                         progress.phase != GenerationPhase.error,
      ));

      // If complete, reload the project
      if (progress.phase == GenerationPhase.complete) {
        _reloadCurrentProject();
      }
    }
  }

  Future<void> _reloadCurrentProject() async {
    if (_projectManager.currentProject != null) {
      final fileTree = _projectManager.getProjectFileTree();
      final project = _projectManager.currentProject!;

      if (state is EditorLoaded) {
        // ignore: invalid_use_of_visible_for_testing_member
        emit((state as EditorLoaded).copyWith(
          project: project,
          projectName: project.name,
          files: fileTree,
        ));
      }
    }
  }

  // Stop Running App Handler
  Future<void> _onStopRunningApp(
    StopRunningApp event,
    Emitter<EditorState> emit,
  ) async {
    if (state is EditorLoaded) {
      await _terminalService.stop();
      emit((state as EditorLoaded).copyWith(
        isAppRunning: false,
        terminalOutput: [...(state as EditorLoaded).terminalOutput, 'App stopped.\n'],
      ));
    }
  }

  // Configure OpenAI Handler
  Future<void> _onConfigureOpenAI(
    ConfigureOpenAI event,
    Emitter<EditorState> emit,
  ) async {
    await _aiAgentService.configure(event.apiKey, model: event.model);

    if (state is EditorLoaded) {
      emit((state as EditorLoaded).copyWith(isOpenAIConfigured: true));
    }
  }

  // Clear OpenAI Config Handler
  Future<void> _onClearOpenAIConfig(
    ClearOpenAIConfig event,
    Emitter<EditorState> emit,
  ) async {
    await _configService.clearOpenAIKey();

    if (state is EditorLoaded) {
      emit((state as EditorLoaded).copyWith(isOpenAIConfigured: false));
    }
  }
}
