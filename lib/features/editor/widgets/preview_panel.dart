import 'package:flutter/material.dart';
import '../../../core/models/widget_node.dart';
import '../../../core/theme/app_theme.dart';

class PreviewPanel extends StatefulWidget {
  final List<WidgetNode> widgetTree;
  final WidgetNode? selectedWidget;
  final bool inspectMode;
  final Function(WidgetNode)? onWidgetSelect;

  const PreviewPanel({
    super.key,
    required this.widgetTree,
    this.selectedWidget,
    this.inspectMode = false,
    this.onWidgetSelect,
  });

  @override
  State<PreviewPanel> createState() => _PreviewPanelState();
}

class _PreviewPanelState extends State<PreviewPanel> {
  String _selectedDevice = 'iPhone 14 Pro';
  double _scale = 0.75;

  final Map<String, Size> _deviceSizes = {
    'iPhone 14 Pro': const Size(393, 852),
    'iPhone SE': const Size(375, 667),
    'Pixel 7': const Size(412, 915),
    'iPad Pro': const Size(1024, 1366),
    'Desktop': const Size(1440, 900),
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF0F0F1A),
      child: Column(
        children: [
          _buildToolbar(context),
          Expanded(child: _buildPreviewArea()),
        ],
      ),
    );
  }

  Widget _buildToolbar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.customColors['background'],
        border: const Border(bottom: BorderSide(color: Color(0xFF3D3D4F))),
      ),
      child: Row(
        children: [
          // Device selector
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: AppTheme.customColors['surface'],
              borderRadius: BorderRadius.circular(6),
            ),
            child: DropdownButton<String>(
              value: _selectedDevice,
              underline: const SizedBox(),
              dropdownColor: AppTheme.customColors['surface'],
              style: const TextStyle(fontSize: 13, color: Colors.white),
              items: _deviceSizes.keys.map((device) {
                return DropdownMenuItem(value: device, child: Text(device));
              }).toList(),
              onChanged: (value) => setState(() => _selectedDevice = value!),
            ),
          ),
          const SizedBox(width: 16),
          // Zoom controls
          IconButton(
            icon: const Icon(Icons.remove, size: 18, color: Colors.white54),
            onPressed: () => setState(() => _scale = (_scale - 0.1).clamp(0.25, 1.5)),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.customColors['surface'],
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '${(_scale * 100).round()}%',
              style: const TextStyle(fontSize: 12, color: Colors.white70),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.add, size: 18, color: Colors.white54),
            onPressed: () => setState(() => _scale = (_scale + 0.1).clamp(0.25, 1.5)),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const Spacer(),
          // Inspect mode toggle
          _buildToolButton(
            icon: Icons.search,
            label: 'Inspect',
            isActive: widget.inspectMode,
            onTap: () {},
          ),
          const SizedBox(width: 8),
          _buildToolButton(
            icon: Icons.refresh,
            label: 'Refresh',
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildToolButton({
    required IconData icon,
    required String label,
    bool isActive = false,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? AppTheme.primaryColor.withValues(alpha: 0.2) : AppTheme.customColors['surface'],
          borderRadius: BorderRadius.circular(6),
          border: isActive ? Border.all(color: AppTheme.primaryColor) : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: isActive ? AppTheme.primaryColor : Colors.white54),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isActive ? AppTheme.primaryColor : Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewArea() {
    final deviceSize = _deviceSizes[_selectedDevice]!;

    return Center(
      child: SingleChildScrollView(
        child: Transform.scale(
          scale: _scale,
          child: Container(
            width: deviceSize.width,
            height: deviceSize.height,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(40),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 30,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(40),
              child: Column(
                children: [
                  // Status bar
                  _buildStatusBar(),
                  // Preview content
                  Expanded(
                    child: widget.widgetTree.isEmpty
                        ? _buildEmptyPreview()
                        : _buildWidgetPreview(),
                  ),
                  // Home indicator
                  _buildHomeIndicator(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            '9:41',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          Row(
            children: [
              Icon(Icons.signal_cellular_4_bar, size: 16, color: Colors.black),
              const SizedBox(width: 4),
              Icon(Icons.wifi, size: 16, color: Colors.black),
              const SizedBox(width: 4),
              Icon(Icons.battery_full, size: 16, color: Colors.black),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHomeIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      color: Colors.white,
      child: Center(
        child: Container(
          width: 134,
          height: 5,
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyPreview() {
    return Container(
      color: const Color(0xFFF5F5F5),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.phone_android, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'No widgets to preview',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add widgets to see them here',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWidgetPreview() {
    return Container(
      color: const Color(0xFFF5F5F5),
      child: _renderWidgetTree(widget.widgetTree),
    );
  }

  Widget _renderWidgetTree(List<WidgetNode> nodes) {
    if (nodes.isEmpty) return const SizedBox();
    return _renderWidget(nodes.first);
  }

  Widget _renderWidget(WidgetNode node) {
    final isSelected = widget.selectedWidget?.id == node.id;

    Widget child;
    switch (node.type) {
      case 'Scaffold':
        child = _renderScaffold(node);
        break;
      case 'AppBar':
        child = _renderAppBar(node);
        break;
      case 'Column':
        child = _renderColumn(node);
        break;
      case 'Row':
        child = _renderRow(node);
        break;
      case 'Text':
        child = _renderText(node);
        break;
      case 'Button':
        child = _renderButton(node);
        break;
      case 'Container':
        child = _renderContainer(node);
        break;
      default:
        child = Container(
          padding: const EdgeInsets.all(8),
          color: Colors.grey.shade200,
          child: Text(node.type),
        );
    }

    if (widget.inspectMode) {
      return GestureDetector(
        onTap: () => widget.onWidgetSelect?.call(node),
        child: Container(
          decoration: isSelected
              ? BoxDecoration(
                  border: Border.all(color: AppTheme.primaryColor, width: 2),
                )
              : null,
          child: child,
        ),
      );
    }

    return child;
  }

  Widget _renderScaffold(WidgetNode node) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: node.children.any((c) => c.type == 'AppBar')
          ? PreferredSize(
              preferredSize: const Size.fromHeight(56),
              child: _renderWidget(node.children.firstWhere((c) => c.type == 'AppBar')),
            )
          : null,
      body: node.children.any((c) => c.type != 'AppBar')
          ? _renderWidget(node.children.firstWhere((c) => c.type != 'AppBar'))
          : null,
    );
  }

  Widget _renderAppBar(WidgetNode node) {
    return AppBar(
      backgroundColor: AppTheme.primaryColor,
      title: Text(
        node.properties['title']?.toString() ?? 'App',
        style: const TextStyle(color: Colors.white),
      ),
    );
  }

  Widget _renderColumn(WidgetNode node) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: node.children.map(_renderWidget).toList(),
    );
  }

  Widget _renderRow(WidgetNode node) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: node.children.map(_renderWidget).toList(),
    );
  }

  Widget _renderText(WidgetNode node) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Text(
        node.properties['text']?.toString() ?? 'Text',
        style: TextStyle(
          fontSize: node.properties['style'] == 'headlineMedium' ? 24 : 16,
          fontWeight: node.properties['style'] == 'headlineMedium' ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _renderButton(WidgetNode node) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: ElevatedButton(
        onPressed: () {},
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
        ),
        child: Text(node.properties['text']?.toString() ?? 'Button'),
      ),
    );
  }

  Widget _renderContainer(WidgetNode node) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: node.children.isNotEmpty
          ? Column(children: node.children.map(_renderWidget).toList())
          : const SizedBox(),
    );
  }
}
