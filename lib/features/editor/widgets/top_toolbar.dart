import 'package:flutter/material.dart';
import '../../../core/models/widget_node.dart';
import '../../../core/theme/app_theme.dart';

class TopToolbar extends StatelessWidget {
  final ViewMode viewMode;
  final bool showWidgetTree;
  final bool showProperties;
  final bool showAgent;
  final bool inspectMode;
  final Function(ViewMode)? onViewModeChange;
  final Function(PanelType)? onTogglePanel;
  final VoidCallback? onToggleInspect;

  const TopToolbar({
    super.key,
    required this.viewMode,
    this.showWidgetTree = true,
    this.showProperties = true,
    this.showAgent = true,
    this.inspectMode = false,
    this.onViewModeChange,
    this.onTogglePanel,
    this.onToggleInspect,
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
                  'Visual Builder',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                ),
              ],
              const SizedBox(width: 16),

              // View mode tabs
              _buildViewModeTabs(isCompact),

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

              // Actions
              _buildActionButton(
                icon: Icons.play_arrow,
                label: isVeryCompact ? null : 'Run',
                isPrimary: true,
              ),
              if (!isVeryCompact) ...[
                const SizedBox(width: 6),
                _buildActionButton(
                  icon: Icons.cloud_upload_outlined,
                  label: null,
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
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: label != null ? 10 : 8, vertical: 6),
      decoration: BoxDecoration(
        gradient: isPrimary ? AppTheme.primaryGradient : null,
        color: isPrimary ? null : AppTheme.customColors['surface'],
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          if (label != null) ...[
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 11, color: Colors.white),
            ),
          ],
        ],
      ),
    );
  }
}
