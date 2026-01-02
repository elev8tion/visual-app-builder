import 'package:flutter/material.dart';
import 'package:device_preview_plus/device_preview_plus.dart';
import '../../../core/models/widget_node.dart';
import '../../../core/models/widget_selection.dart';
import '../../../core/services/widget_reconstructor_service.dart';
import '../../../core/theme/app_theme.dart';

class PreviewPanel extends StatefulWidget {
  final List<WidgetNode> widgetTree;
  final WidgetNode? selectedWidget;
  final bool inspectMode;
  final Function(WidgetNode)? onWidgetSelect;
  final WidgetTreeNode? astWidgetTree;

  const PreviewPanel({
    super.key,
    required this.widgetTree,
    this.selectedWidget,
    this.inspectMode = false,
    this.onWidgetSelect,
    this.astWidgetTree,
  });

  @override
  State<PreviewPanel> createState() => _PreviewPanelState();
}

class _PreviewPanelState extends State<PreviewPanel> {
  String _currentMode = 'device';
  double _zoomLevel = 1.0;  // Default to 100% - responsive scaling handles fitting
  int _currentZoomIndex = 3;  // Index of 1.0 in presets
  bool _inspectModeEnabled = false;
  final List<double> _zoomPresets = [0.25, 0.5, 0.75, 1.0, 1.25, 1.5, 2.0];

  final List<DeviceInfo> _selectedDevices = [
    Devices.ios.iPhone13,
  ];

  final WidgetReconstructorService _reconstructor = WidgetReconstructorService.instance;

  @override
  void initState() {
    super.initState();
    _inspectModeEnabled = widget.inspectMode;
  }

  @override
  void didUpdateWidget(PreviewPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.inspectMode != widget.inspectMode) {
      _inspectModeEnabled = widget.inspectMode;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      color: const Color(0xFF0F0F1A),
      child: Column(
        children: [
          _buildToolbar(theme),
          Expanded(child: _buildPreviewContent(theme)),
        ],
      ),
    );
  }

  Widget _buildToolbar(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.customColors['background'],
        border: const Border(bottom: BorderSide(color: Color(0xFF3D3D4F))),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 500;

          return Row(
            children: [
              // Mode selector
              _buildModeSelector(theme),
              if (!isCompact) ...[
                const SizedBox(width: 16),
                // Device selector
                _buildDeviceSelector(theme),
                const SizedBox(width: 16),
                // Zoom controls
                _buildZoomControls(theme),
              ],
              const Spacer(),

              // Inspect mode toggle
              _buildInspectToggle(theme),
              const SizedBox(width: 8),

              // Refresh button
              _buildToolButton(
                icon: Icons.refresh,
                label: isCompact ? null : 'Refresh',
                onTap: () => setState(() {}),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildModeSelector(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.customColors['surface'],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildModeButton('device', Icons.phone_android, 'Device', theme),
          _buildModeButton('responsive', Icons.devices, 'Multi', theme),
        ],
      ),
    );
  }

  Widget _buildModeButton(String mode, IconData icon, String label, ThemeData theme) {
    final isActive = _currentMode == mode;

    return InkWell(
      onTap: () => setState(() => _currentMode = mode),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? AppTheme.primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isActive ? Colors.white : Colors.white54,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isActive ? Colors.white : Colors.white54,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeviceSelector(ThemeData theme) {
    return InkWell(
      onTap: () => _showDeviceSelectionDialog(theme),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppTheme.customColors['surface'],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFF3D3D4F)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.smartphone, size: 14, color: Colors.white54),
            const SizedBox(width: 6),
            Text(
              _selectedDevices.isNotEmpty
                  ? _selectedDevices.first.name
                  : 'Select Device',
              style: const TextStyle(fontSize: 12, color: Colors.white70),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.arrow_drop_down, size: 16, color: Colors.white54),
          ],
        ),
      ),
    );
  }

  Widget _buildZoomControls(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.customColors['surface'],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF3D3D4F)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.remove, size: 14),
            color: Colors.white54,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
            onPressed: _currentZoomIndex > 0
                ? () => _changeZoom(_currentZoomIndex - 1)
                : null,
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              '${(_zoomLevel * 100).toInt()}%',
              style: const TextStyle(fontSize: 12, color: Colors.white70),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add, size: 14),
            color: Colors.white54,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
            onPressed: _currentZoomIndex < _zoomPresets.length - 1
                ? () => _changeZoom(_currentZoomIndex + 1)
                : null,
          ),
          const SizedBox(width: 4),
          IconButton(
            icon: const Icon(Icons.fit_screen, size: 14),
            tooltip: 'Fit to Screen (100%)',
            color: Colors.white54,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
            onPressed: () => _changeZoom(3), // Reset to 100%
          ),
        ],
      ),
    );
  }

  Widget _buildInspectToggle(ThemeData theme) {
    return _buildToolButton(
      icon: _inspectModeEnabled ? Icons.touch_app : Icons.touch_app_outlined,
      label: 'Inspect',
      isActive: _inspectModeEnabled,
      onTap: () => setState(() => _inspectModeEnabled = !_inspectModeEnabled),
    );
  }

  Widget _buildToolButton({
    required IconData icon,
    String? label,
    bool isActive = false,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: label != null ? 10 : 8, vertical: 6),
        decoration: BoxDecoration(
          color: isActive
              ? AppTheme.primaryColor.withValues(alpha: 0.2)
              : AppTheme.customColors['surface'],
          borderRadius: BorderRadius.circular(6),
          border: isActive ? Border.all(color: AppTheme.primaryColor) : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isActive ? AppTheme.primaryColor : Colors.white54,
            ),
            if (label != null) ...[
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: isActive ? AppTheme.primaryColor : Colors.white70,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewContent(ThemeData theme) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (_currentMode == 'responsive' && _selectedDevices.length > 1) {
          return _buildMultiDeviceView(theme, constraints);
        }
        return _buildSingleDeviceView(theme, constraints);
      },
    );
  }

  Widget _buildSingleDeviceView(ThemeData theme, BoxConstraints constraints) {
    if (_selectedDevices.isEmpty) {
      return _buildNoDeviceState(theme);
    }

    final device = _selectedDevices.first;

    // Available space for device preview (from flutter_device_preview pattern)
    final availableHeight = constraints.maxHeight - 48; // Space for label
    final availableWidth = constraints.maxWidth - 32; // Padding

    // Build the device frame with screen content
    final deviceFrame = RepaintBoundary(
      child: DeviceFrame(
        device: device,
        screen: _buildPreviewScreen(theme),
      ),
    );

    // Apply zoom level using Transform.scale around FittedBox (device_preview pattern)
    final scaledDevice = Transform.scale(
      scale: _zoomLevel,
      alignment: Alignment.center,
      child: SizedBox(
        width: availableWidth,
        height: availableHeight,
        child: FittedBox(
          fit: BoxFit.contain,
          child: deviceFrame,
        ),
      ),
    );

    // Wrap in InteractiveViewer for pan/zoom when zoomed > 100%
    final interactiveDevice = _zoomLevel > 1.0
        ? InteractiveViewer(
            minScale: 1.0,
            maxScale: 3.0,
            constrained: false,
            boundaryMargin: const EdgeInsets.all(100),
            child: scaledDevice,
          )
        : scaledDevice;

    return Column(
      children: [
        // Device label - compact
        Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 4),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.primaryColor.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.smartphone,
                  size: 12,
                  color: AppTheme.primaryColor,
                ),
                const SizedBox(width: 6),
                Text(
                  device.name,
                  style: TextStyle(
                    fontSize: 11,
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${device.screenSize.width.toInt()}×${device.screenSize.height.toInt()}',
                  style: TextStyle(
                    fontSize: 10,
                    color: AppTheme.primaryColor.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ),
        // Device preview - takes remaining space
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: interactiveDevice,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMultiDeviceView(ThemeData theme, BoxConstraints constraints) {
    // Available space for each device (FittedBox pattern from flutter_device_preview)
    final availableHeight = constraints.maxHeight - 60;
    final deviceWidth = (constraints.maxWidth / _selectedDevices.length) - 24;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: _selectedDevices.map((device) {
          // Device frame with FittedBox for proper scaling
          final deviceFrame = RepaintBoundary(
            child: DeviceFrame(
              device: device,
              screen: _buildPreviewScreen(theme),
            ),
          );

          return Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Device label
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppTheme.primaryColor.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    device.name,
                    style: TextStyle(
                      fontSize: 10,
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                // Device frame with FittedBox scaling
                SizedBox(
                  width: deviceWidth.clamp(150, 300),
                  height: availableHeight - 40,
                  child: FittedBox(
                    fit: BoxFit.contain,
                    child: deviceFrame,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPreviewScreen(ThemeData theme) {
    // If we have an AST widget tree, use the reconstructor
    if (widget.astWidgetTree != null) {
      // Debug: Log widget tree structure
      debugPrint('AST Widget Tree: ${widget.astWidgetTree!.name} with ${widget.astWidgetTree!.children.length} children');
      _logWidgetTree(widget.astWidgetTree!, 0);
      
      final reconstructed = _reconstructor.reconstructWidget(
        widget.astWidgetTree!,
        theme: theme.brightness == Brightness.light ? ThemeData.light() : ThemeData.dark(),
      );

      // If the root widget is already a MaterialApp, return it directly
      if (widget.astWidgetTree!.name == 'MaterialApp' || widget.astWidgetTree!.name == 'MaterialApp.router') {
        return reconstructed;
      }

      // Otherwise, wrap in a MaterialApp to provide required context (Theme, Directionality, MediaQuery)
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: theme.brightness == Brightness.light ? ThemeData.light() : ThemeData.dark(),
        home: reconstructed,
      );
    }

    // Otherwise use the old WidgetNode tree
    if (widget.widgetTree.isNotEmpty) {
      return _buildWidgetPreview(theme);
    }

    // Show empty state
    return _buildEmptyState();
  }

  Widget _buildEmptyState() {
    return Container(
      color: Colors.white,
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.folder_open, size: 48, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No project loaded',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              'Use Open Project to load a Flutter project',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWidgetPreview(ThemeData theme) {
    return Container(
      color: Colors.white,
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

    if (_inspectModeEnabled) {
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
              child: _renderWidget(
                node.children.firstWhere((c) => c.type == 'AppBar'),
              ),
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
          fontSize:
              node.properties['style'] == 'headlineMedium' ? 24 : 16,
          fontWeight: node.properties['style'] == 'headlineMedium'
              ? FontWeight.bold
              : FontWeight.normal,
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

  Widget _buildNoDeviceState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.devices_other,
            size: 64,
            color: Colors.white24,
          ),
          const SizedBox(height: 16),
          const Text(
            'No device selected',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white54,
            ),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () => _showDeviceSelectionDialog(theme),
            icon: const Icon(Icons.add),
            label: const Text('Add Device'),
          ),
        ],
      ),
    );
  }

  void _changeZoom(int index) {
    setState(() {
      _currentZoomIndex = index;
      _zoomLevel = _zoomPresets[index];
    });
  }

  void _showDeviceSelectionDialog(ThemeData theme) {
    final availableDevices = [
      {'category': 'iOS', 'devices': [
        Devices.ios.iPhone13,
        Devices.ios.iPhone13ProMax,
        Devices.ios.iPhone13Mini,
        Devices.ios.iPhoneSE,
        Devices.ios.iPadPro11Inches,
      ]},
      {'category': 'Android', 'devices': [
        Devices.android.samsungGalaxyS20,
        Devices.android.samsungGalaxyNote20,
        Devices.android.onePlus8Pro,
      ]},
    ];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppTheme.customColors['surface'],
          title: Row(
            children: [
              const Icon(Icons.devices, size: 24, color: Colors.white70),
              const SizedBox(width: 12),
              const Text(
                'Select Devices',
                style: TextStyle(color: Colors.white),
              ),
              const Spacer(),
              TextButton(
                onPressed: () {
                  setDialogState(() {
                    setState(() => _selectedDevices.clear());
                  });
                },
                child: const Text('Clear All'),
              ),
            ],
          ),
          content: SizedBox(
            width: 400,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: availableDevices.map((category) {
                  final categoryName = category['category'] as String;
                  final devices = category['devices'] as List<DeviceInfo>;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          categoryName,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ),
                      ...devices.map((device) {
                        final isSelected = _selectedDevices.contains(device);
                        return CheckboxListTile(
                          dense: true,
                          title: Text(
                            device.name,
                            style: const TextStyle(color: Colors.white70),
                          ),
                          subtitle: Text(
                            '${device.screenSize.width.toInt()}x${device.screenSize.height.toInt()}',
                            style: const TextStyle(color: Colors.white38),
                          ),
                          value: isSelected,
                          activeColor: AppTheme.primaryColor,
                          onChanged: (bool? value) {
                            setDialogState(() {
                              setState(() {
                                if (value == true) {
                                  _selectedDevices.add(device);
                                } else {
                                  _selectedDevices.remove(device);
                                }
                              });
                            });
                          },
                        );
                      }),
                      const SizedBox(height: 8),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.check, size: 18),
              label: Text('Apply (${_selectedDevices.length})'),
            ),
          ],
        ),
      ),
    );
  }

  void _logWidgetTree(WidgetTreeNode node, int depth) {
    final indent = '  ' * depth;
    print('$indent- ${node.name} (children: ${node.children.length})');
    for (final child in node.children) {
      _logWidgetTree(child, depth + 1);
    }
  }
}
