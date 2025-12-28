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

class _EditorView extends StatelessWidget {
  const _EditorView();

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
            onViewModeChange: (mode) => bloc.add(ChangeViewMode(mode)),
            onTogglePanel: (panel) => bloc.add(TogglePanel(panel)),
            onToggleInspect: () => bloc.add(const ToggleInspectMode()),
          ),

          // Main content area
          Expanded(
            child: Row(
              children: [
                // Left panel (File Explorer + Widget Tree)
                if (state.showWidgetTree)
                  SizedBox(
                    width: 260,
                    child: Column(
                      children: [
                        Expanded(
                          flex: 2,
                          child: FileExplorerPanel(
                            files: state.files,
                            currentFile: state.currentFile,
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
    );
  }

  Widget _buildCenterPanel(EditorLoaded state, EditorBloc bloc) {
    switch (state.viewMode) {
      case ViewMode.preview:
        return PreviewPanel(
          widgetTree: state.widgetTree,
          selectedWidget: state.selectedWidget,
          inspectMode: state.inspectMode,
          onWidgetSelect: (widget) => bloc.add(SelectWidget(widget)),
        );
      case ViewMode.code:
        return CodeEditorPanel(
          code: state.currentFileContent,
          fileName: state.currentFile,
        );
      case ViewMode.split:
        return Row(
          children: [
            Expanded(
              child: PreviewPanel(
                widgetTree: state.widgetTree,
                selectedWidget: state.selectedWidget,
                inspectMode: state.inspectMode,
                onWidgetSelect: (widget) => bloc.add(SelectWidget(widget)),
              ),
            ),
            const VerticalDivider(width: 1, color: Color(0xFF3D3D4F)),
            Expanded(
              child: CodeEditorPanel(
                code: state.currentFileContent,
                fileName: state.currentFile,
              ),
            ),
          ],
        );
    }
  }
}
