import 'package:flutter/material.dart';
import '../../../core/models/widget_node.dart';
import '../../../core/theme/app_theme.dart';

class WidgetTreePanel extends StatelessWidget {
  final List<WidgetNode> widgets;
  final WidgetNode? selectedWidget;
  final Function(WidgetNode)? onSelect;
  final VoidCallback? onRefresh;

  const WidgetTreePanel({
    super.key,
    required this.widgets,
    this.selectedWidget,
    this.onSelect,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.customColors['background'],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context),
          const Divider(height: 1, color: Color(0xFF3D3D4F)),
          Expanded(
            child: widgets.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: widgets.length,
                    itemBuilder: (context, index) {
                      return _buildTreeNode(widgets[index], 0);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          const Icon(Icons.account_tree, size: 18, color: Colors.white70),
          const SizedBox(width: 8),
          Text(
            'Widget Tree',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.refresh, size: 18, color: Colors.white54),
            onPressed: onRefresh,
            tooltip: 'Refresh widget tree',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.widgets_outlined, size: 48, color: Colors.white24),
          SizedBox(height: 16),
          Text(
            'No widgets yet',
            style: TextStyle(color: Colors.white38),
          ),
        ],
      ),
    );
  }

  Widget _buildTreeNode(WidgetNode node, int depth) {
    final isSelected = selectedWidget?.id == node.id;
    final hasChildren = node.children.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => onSelect?.call(node),
          child: Container(
            padding: EdgeInsets.only(
              left: 16.0 + (depth * 16.0),
              right: 16,
              top: 8,
              bottom: 8,
            ),
            decoration: BoxDecoration(
              color: isSelected ? AppTheme.primaryColor.withValues(alpha: 0.2) : null,
              border: isSelected
                  ? Border(
                      left: BorderSide(
                        color: AppTheme.primaryColor,
                        width: 2,
                      ),
                    )
                  : null,
            ),
            child: Row(
              children: [
                if (hasChildren)
                  Icon(
                    node.isExpanded
                        ? Icons.keyboard_arrow_down
                        : Icons.keyboard_arrow_right,
                    size: 16,
                    color: Colors.white54,
                  )
                else
                  const SizedBox(width: 16),
                const SizedBox(width: 4),
                Icon(
                  node.icon,
                  size: 16,
                  color: isSelected ? AppTheme.primaryColor : Colors.white54,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    node.name,
                    style: TextStyle(
                      fontSize: 13,
                      color: isSelected ? Colors.white : Colors.white70,
                      fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  node.type,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white38,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (hasChildren && node.isExpanded)
          ...node.children.map((child) => _buildTreeNode(child, depth + 1)),
      ],
    );
  }
}
