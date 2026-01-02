import 'package:flutter/material.dart';
import '../../../core/models/widget_node.dart';
import '../../../core/theme/app_theme.dart';

class TopToolbar extends StatelessWidget {
  final ViewMode viewMode;
  final bool showWidgetTree;
  final bool showProperties;
  final bool showAgent;
  final bool inspectMode;
  final String? projectName;
  final bool isLoadingProject;
  final Function(ViewMode)? onViewModeChange;
  final Function(PanelType)? onTogglePanel;
  final VoidCallback? onToggleInspect;
  final VoidCallback? onLoadZip;
  final VoidCallback? onLoadFolder;
  final VoidCallback? onUndo;
  final VoidCallback? onRedo;
  final VoidCallback? onRun;
  final VoidCallback? onHotReload;
  final VoidCallback? onNewProject;
  final VoidCallback? onAIGenerate;
  final VoidCallback? onSettings;
  final VoidCallback? onStopApp;
  final bool canUndo;
  final bool canRedo;
  final bool isDirty;
  final bool isAppRunning;
  final bool isOpenAIConfigured;

  const TopToolbar({
    super.key,
    required this.viewMode,
    this.showWidgetTree = true,
    this.showProperties = true,
    this.showAgent = true,
    this.inspectMode = false,
    this.projectName,
    this.isLoadingProject = false,
    this.onViewModeChange,
    this.onTogglePanel,
    this.onToggleInspect,
    this.onLoadZip,
    this.onLoadFolder,
    this.onUndo,

    this.onRedo,
    this.onRun,
    this.onHotReload,
    this.onNewProject,
    this.onAIGenerate,
    this.onSettings,
    this.onStopApp,
    this.canUndo = false,
    this.canRedo = false,
    this.isDirty = false,
    this.isAppRunning = false,
    this.isOpenAIConfigured = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppTheme.customColors['background'],
        border: const Border(bottom: BorderSide(color: Color(0xFF3D3D4F))),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 900;
          final isVeryCompact = constraints.maxWidth < 700;

          return Row(
            children: [
              // Logo
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.dashboard_customize, size: 16, color: Colors.white),
              ),
              if (!isVeryCompact) ...[
                const SizedBox(width: 8),
                Text(
                  (projectName ?? 'Visual Builder') + (isDirty ? '*' : ''),
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                ),
              ],
              const SizedBox(width: 12),

              // Project loading buttons
              _buildProjectButtons(isVeryCompact),
              const SizedBox(width: 12),

              // View mode tabs
              _buildViewModeTabs(isCompact),
              const SizedBox(width: 12),

              // Undo/Redo
              _buildUndoRedoButtons(),

              const Spacer(),

              // Panel toggles - icons only when compact
              _buildPanelToggle(
                icon: Icons.account_tree,
                label: isCompact ? null : 'Tree',
                isActive: showWidgetTree,
                onTap: () => onTogglePanel?.call(PanelType.widgetTree),
              ),
              const SizedBox(width: 4),
              _buildPanelToggle(
                icon: Icons.tune,
                label: isCompact ? null : 'Props',
                isActive: showProperties,
                onTap: () => onTogglePanel?.call(PanelType.properties),
              ),
              const SizedBox(width: 4),
              _buildPanelToggle(
                icon: Icons.auto_awesome,
                label: isCompact ? null : 'Agent',
                isActive: showAgent,
                onTap: () => onTogglePanel?.call(PanelType.agent),
              ),
              const SizedBox(width: 8),
              Container(width: 1, height: 24, color: const Color(0xFF3D3D4F)),
              const SizedBox(width: 8),

              // Inspect mode
              _buildInspectButton(isCompact),
              const SizedBox(width: 8),

              // AI Generate button
              _buildActionButton(
                icon: Icons.auto_awesome,
                label: isVeryCompact ? null : 'AI Generate',
                isPrimary: false,
                onTap: onAIGenerate,
                color: isOpenAIConfigured ? AppTheme.primaryColor : Colors.white54,
              ),
              const SizedBox(width: 6),

              // Settings button
              InkWell(
                onTap: onSettings,
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  child: Icon(
                    Icons.settings,
                    size: 16,
                    color: Colors.white54,
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Run/Stop Actions
              _buildActionButton(
                icon: isAppRunning ? Icons.stop : Icons.play_arrow,
                label: isAppRunning ? 'Stop' : (isVeryCompact ? null : 'Run'),
                isPrimary: !isAppRunning,
                onTap: isAppRunning ? onStopApp : onRun,
                color: isAppRunning ? Colors.red : null,
              ),
              if (isAppRunning) ...[
                const SizedBox(width: 6),
                _buildActionButton(
                  icon: Icons.bolt,
                  label: isVeryCompact ? null : 'Hot Reload',
                  onTap: onHotReload,
                  color: Colors.amber,
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildViewModeTabs(bool isCompact) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.customColors['surface'],
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildViewModeTab(ViewMode.preview, Icons.phone_android, isCompact ? null : 'Preview'),
          _buildViewModeTab(ViewMode.code, Icons.code, isCompact ? null : 'Code'),
          _buildViewModeTab(ViewMode.split, Icons.vertical_split, isCompact ? null : 'Split'),
        ],
      ),
    );
  }

  Widget _buildViewModeTab(ViewMode mode, IconData icon, String? label) {
    final isActive = viewMode == mode;
    return InkWell(
      onTap: () => onViewModeChange?.call(mode),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: label != null ? 10 : 8, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? AppTheme.primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: isActive ? Colors.white : Colors.white54),
            if (label != null) ...[
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: isActive ? Colors.white : Colors.white54,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPanelToggle({
    required IconData icon,
    String? label,
    required bool isActive,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isActive ? AppTheme.primaryColor : Colors.white38,
            ),
            if (label != null) ...[
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: isActive ? Colors.white : Colors.white38,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInspectButton(bool isCompact) {
    return InkWell(
      onTap: onToggleInspect,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: isCompact ? 8 : 10, vertical: 6),
        decoration: BoxDecoration(
          color: inspectMode ? AppTheme.primaryColor.withValues(alpha: 0.2) : AppTheme.customColors['surface'],
          borderRadius: BorderRadius.circular(6),
          border: inspectMode ? Border.all(color: AppTheme.primaryColor) : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search,
              size: 14,
              color: inspectMode ? AppTheme.primaryColor : Colors.white54,
            ),
            if (!isCompact) ...[
              const SizedBox(width: 4),
              Text(
                'Inspect',
                style: TextStyle(
                  fontSize: 11,
                  color: inspectMode ? AppTheme.primaryColor : Colors.white70,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    String? label,
    bool isPrimary = false,
    VoidCallback? onTap,
    Color? color,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: label != null ? 10 : 8, vertical: 6),
        decoration: BoxDecoration(
          gradient: isPrimary ? AppTheme.primaryGradient : null,
          color: isPrimary ? null : AppTheme.customColors['surface'],
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color ?? Colors.white),
            if (label != null) ...[
              const SizedBox(width: 4),
              Text(
                label,
                style: const TextStyle(fontSize: 11, color: Colors.white),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildProjectButtons(bool isVeryCompact) {
    if (isLoadingProject) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppTheme.customColors['surface'],
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white54,
              ),
            ),
            SizedBox(width: 6),
            Text(
              'Loading...',
              style: TextStyle(fontSize: 11, color: Colors.white54),
            ),
          ],
        ),
      );
    }

    return PopupMenuButton<String>(
      onSelected: (value) {
        if (value == 'new') {
          onNewProject?.call();
        } else if (value == 'zip') {
          onLoadZip?.call();
        } else if (value == 'folder') {
          onLoadFolder?.call();
        }
      },
      offset: const Offset(0, 40),
      color: AppTheme.customColors['surface'],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: Color(0xFF3D3D4F)),
      ),
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'new',
          child: Row(
            children: [
              Icon(Icons.create_new_folder, size: 16, color: AppTheme.primaryColor),
              const SizedBox(width: 8),
              const Text('New Project', style: TextStyle(color: Colors.white70, fontSize: 12)),
            ],
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: 'zip',
          child: Row(
            children: [
              Icon(Icons.folder_zip_outlined, size: 16, color: AppTheme.primaryColor),
              const SizedBox(width: 8),
              const Text('Open ZIP Project', style: TextStyle(color: Colors.white70, fontSize: 12)),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'folder',
          child: Row(
            children: [
              Icon(Icons.folder_open_outlined, size: 16, color: AppTheme.primaryColor),
              const SizedBox(width: 8),
              const Text('Open Folder', style: TextStyle(color: Colors.white70, fontSize: 12)),
            ],
          ),
        ),
      ],
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: isVeryCompact ? 8 : 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppTheme.customColors['surface'],
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFF3D3D4F)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.folder_open, size: 14, color: AppTheme.primaryColor),
            if (!isVeryCompact) ...[
              const SizedBox(width: 6),
              const Text(
                'Open Project',
                style: TextStyle(fontSize: 11, color: Colors.white70),
              ),
            ],
            const SizedBox(width: 4),
            const Icon(Icons.arrow_drop_down, size: 14, color: Colors.white54),
          ],
        ),
      ),
    );

  }

  Widget _buildUndoRedoButtons() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.customColors['surface'],
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildUndoRedoButton(
            icon: Icons.undo,
            onTap: canUndo ? onUndo : null,
            tooltip: 'Undo (Cmd+Z)',
          ),
          Container(width: 1, height: 16, color: const Color(0xFF3D3D4F)),
          _buildUndoRedoButton(
            icon: Icons.redo,
            onTap: canRedo ? onRedo : null,
            tooltip: 'Redo (Cmd+Shift+Z)',
          ),
        ],
      ),
    );
  }

  Widget _buildUndoRedoButton({
    required IconData icon,
    VoidCallback? onTap,
    required String tooltip,
  }) {
    final isEnabled = onTap != null;
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(
            icon,
            size: 16,
            color: isEnabled ? Colors.white70 : Colors.white24,
          ),
        ),
      ),
    );
  }
}
