import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/editor/editor_bloc.dart';
import '../../core/models/widget_node.dart';
import '../../core/theme/app_theme.dart';
import 'widgets/widget_tree_panel.dart';
import 'widgets/properties_panel.dart';
import 'widgets/agent_chat_panel.dart';
import 'widgets/preview_panel.dart';
import 'widgets/code_editor_panel.dart';
import 'widgets/file_explorer_panel.dart';
import 'widgets/top_toolbar.dart';
import 'widgets/source_control_panel.dart';

class EditorScreen extends StatelessWidget {
  const EditorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => EditorBloc()..add(const LoadProject('default')),
      child: const _EditorView(),
    );
  }
}

class _EditorView extends StatefulWidget {
  const _EditorView();

  @override
  State<_EditorView> createState() => _EditorViewState();
}

class _EditorViewState extends State<_EditorView> {
  int _selectedLeftTabIndex = 0;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<EditorBloc, EditorState>(
      builder: (context, state) {
        if (state is EditorLoading) {
          return Scaffold(
            backgroundColor: AppTheme.customColors['background'],
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: AppTheme.primaryColor),
                  const SizedBox(height: 16),
                  const Text(
                    'Loading project...',
                    style: TextStyle(color: Colors.white54),
                  ),
                ],
              ),
            ),
          );
        }

        if (state is EditorError) {
          return Scaffold(
            backgroundColor: AppTheme.customColors['background'],
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48, color: AppTheme.customColors['error']),
                  const SizedBox(height: 16),
                  Text(
                    state.message,
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
          );
        }

        if (state is EditorLoaded) {
          return _buildEditor(context, state);
        }

        return const SizedBox();
      },
    );
  }

  Widget _buildEditor(BuildContext context, EditorLoaded state) {
    final bloc = context.read<EditorBloc>();

    return Scaffold(
      backgroundColor: AppTheme.customColors['background'],
      body: Column(
        children: [
          // Top Toolbar
          TopToolbar(
            viewMode: state.viewMode,
            showWidgetTree: state.showWidgetTree,
            showProperties: state.showProperties,
            showAgent: state.showAgent,
            inspectMode: state.inspectMode,
            projectName: state.projectName,
            isLoadingProject: state.isLoadingProject,
            onViewModeChange: (mode) => bloc.add(ChangeViewMode(mode)),
            onTogglePanel: (panel) => bloc.add(TogglePanel(panel)),
            onToggleInspect: () => bloc.add(const ToggleInspectMode()),
            onLoadZip: () => bloc.add(const LoadProjectFromZip()),

            onLoadFolder: () => bloc.add(const LoadProjectFromDirectory()),
            onRun: () => bloc.add(const RunProject()),
            onHotReload: () => bloc.add(const HotReload()),
            canUndo: state.canUndo,
            canRedo: state.canRedo,
            isDirty: state.isDirty,
            isAppRunning: state.isAppRunning,
          ),

          // Main content area
          Expanded(
            child: Row(
              children: [
                // Left panel (File Explorer + Widget Tree)
                if (state.showWidgetTree)
                      ],
                    ),
                  ),

                if (state.showWidgetTree)
                  const VerticalDivider(width: 1, color: Color(0xFF3D3D4F)),

                // Left Panel - Source Control (alternative logic required to switch tabs eventually)
                // For MVP, we'll put Source Control in the left panel if a new 'showSourceControl' state existed.
                // But the plan says "Add Source Control tab to the left panel (next to File Explorer)".
                // Let's implement a simple tab switcher in the Left Panel area.
                
                if (state.showWidgetTree) // Re-using this flag for "Left Panel Open" for now
                   SizedBox(
                    width: 300,
                    child: Column(
                      children: [
                        // Panel Tabs
                        Container(
                          height: 36,
                          color: const Color(0xFF252535),
                          child: Row(
                            children: [
                               Expanded(
                                child: InkWell(
                                  onTap: () => setState(() => _selectedLeftTabIndex = 0),
                                  child: Container(
                                    alignment: Alignment.center,
                                    color: _selectedLeftTabIndex == 0 ? const Color(0xFF3D3D4F) : Colors.transparent,
                                    child: Text('Files', style: TextStyle(
                                      color: _selectedLeftTabIndex == 0 ? Colors.white : Colors.white54, 
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    )),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: InkWell(
                                  onTap: () { 
                                    setState(() => _selectedLeftTabIndex = 1);
                                    // Refresh status when switching to Git tab
                                    bloc.add(const GitCheckStatus()); 
                                  },
                                   child: Container(
                                    alignment: Alignment.center,
                                    color: _selectedLeftTabIndex == 1 ? const Color(0xFF3D3D4F) : Colors.transparent,
                                    child: Text('Git', style: TextStyle(
                                      color: _selectedLeftTabIndex == 1 ? Colors.white : Colors.white54,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    )),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: IndexedStack(
                            index: _selectedLeftTabIndex,
                            children: [
                              Column(
                                children: [
                                  Expanded(
                                    flex: 2,
                                    child: FileExplorerPanel(
                                      files: state.files,
                                      currentFile: state.currentFile,
                                      onFileSelect: (file) => bloc.add(SelectProjectFile(file)),
                                      onToggleExpand: (file) => bloc.add(ToggleFileExpand(file)),
                                      onCreateFile: (name, parentPath) => bloc.add(CreateFile(name, parentPath)),
                                      onCreateDirectory: (name, parentPath) => bloc.add(CreateDirectory(name, parentPath)),
                                    ),
                                  ),
                                  const Divider(height: 1, color: Color(0xFF3D3D4F)),
                                  Expanded(
                                    flex: 3,
                                    child: WidgetTreePanel(
                                      widgets: state.widgetTree,
                                      selectedWidget: state.selectedWidget,
                                      onSelect: (widget) => bloc.add(SelectWidget(widget)),
                                      onRefresh: () => bloc.add(const RefreshWidgetTree()),
                                    ),
                                  ),
                                ],
                              ),
                              // Source Control Panel
                              SourceControlPanel(
                                gitStatus: state.gitStatus,
                                isLoading: state.isGitLoading,
                                onRefresh: () => bloc.add(const GitCheckStatus()),
                                onStage: (path) => bloc.add(GitStageFile(path)),
                                onUnstage: (path) => bloc.add(GitUnstageFile(path)),
                                onCommit: (msg) => bloc.add(GitCommit(msg)),
                                onPush: () => bloc.add(const GitPush()),
                                onGenerateMessage: (context) {
                                  // Trigger AI to generate message (we'll reuse the chat panel for now or add a specific event)
                                  bloc.add(SendAgentMessage('Generate a git commit message for the current staged changes.'));
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                if (state.showWidgetTree)
                  const VerticalDivider(width: 1, color: Color(0xFF3D3D4F)),

                // Center panel (Preview / Code / Split)
                Expanded(
                  child: _buildCenterPanel(state, bloc),
                ),

                // Right panels
                if (state.showProperties || state.showAgent)
                  const VerticalDivider(width: 1, color: Color(0xFF3D3D4F)),

                if (state.showProperties || state.showAgent)
                  SizedBox(
                    width: 300,
                    child: Column(
                      children: [
                        if (state.showProperties)
                          Expanded(
                            child: PropertiesPanel(
                              selectedWidget: state.selectedWidget,
                              selectedAstWidget: state.selectedAstWidget,
                              onPropertyChange: (name, value) {
                                if (state.selectedWidget != null) {
                                  bloc.add(UpdateProperty(
                                    state.selectedWidget!.id,
                                    name,
                                    value,
                                  ));
                                }
                              },
                            ),
                          ),
                        if (state.showProperties && state.showAgent)
                          const Divider(height: 1, color: Color(0xFF3D3D4F)),
                        if (state.showAgent)
                          Expanded(
                            child: AgentChatPanel(
                              messages: state.chatMessages,
                              onSendMessage: (message, {attachments}) {
                                bloc.add(SendAgentMessage(
                                  message,
                                  attachments: attachments,
                                ));
                              },
                            ),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
          // Terminal Panel
          if (state.terminalOutput.isNotEmpty || state.isAppRunning)
            Container(
              height: 200,
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Color(0xFF3D3D4F))),
                color: Color(0xFF1E1E2E), // Darker background for terminal
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Terminal Header
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    color: const Color(0xFF252535),
                    child: Row(
                      children: [
                        const Icon(Icons.terminal, size: 16, color: Colors.white70),
                        const SizedBox(width: 8),
                        const Text(
                          'Terminal',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        if (state.isAppRunning)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: Colors.green.withOpacity(0.5)),
                            ),
                            child: const Text('Running', style: TextStyle(fontSize: 10, color: Colors.green)),
                          ),
                      ],
                    ),
                  ),
                  // Terminal Output
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: state.terminalOutput.length,
                      itemBuilder: (context, index) {
                        return Text(
                          state.terminalOutput[index],
                          style: const TextStyle(
                            fontFamily: 'Courier',
                            fontSize: 12,
                            color: Colors.white70,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCenterPanel(EditorLoaded state, EditorBloc bloc) {
    switch (state.viewMode) {
      case ViewMode.preview:
        return PreviewPanel(
          widgetTree: state.widgetTree,
          selectedWidget: state.selectedWidget,
          inspectMode: state.inspectMode,
          astWidgetTree: state.astWidgetTree,
          onWidgetSelect: (widget) => bloc.add(SelectWidget(widget)),
        );
      case ViewMode.code:
        return CodeEditorPanel(
          code: state.currentFileContent,
          fileName: state.currentFile,
          onCodeChange: (code) => bloc.add(UpdateCode(code)),

          onSave: () => bloc.add(const SaveFile()),
          onUndo: () => bloc.add(const Undo()),
          onRedo: () => bloc.add(const Redo()),
          canUndo: state.canUndo,
          canRedo: state.canRedo,
        );
      case ViewMode.split:
        return Row(
          children: [
            Expanded(
              child: PreviewPanel(
                widgetTree: state.widgetTree,
                selectedWidget: state.selectedWidget,
                inspectMode: state.inspectMode,
                astWidgetTree: state.astWidgetTree,
                onWidgetSelect: (widget) => bloc.add(SelectWidget(widget)),
              ),
            ),
            const VerticalDivider(width: 1, color: Color(0xFF3D3D4F)),
            Expanded(
              child: CodeEditorPanel(
                code: state.currentFileContent,
                fileName: state.currentFile,
                onCodeChange: (code) => bloc.add(UpdateCode(code)),

                onSave: () => bloc.add(const SaveFile()),
                onUndo: () => bloc.add(const Undo()),
                onRedo: () => bloc.add(const Redo()),
                canUndo: state.canUndo,
                canRedo: state.canRedo,
              ),
            ),
          ],
        );
    }
  }
}
