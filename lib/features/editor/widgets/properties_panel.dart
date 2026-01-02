import 'package:flutter/material.dart';
import '../../../core/models/widget_node.dart';
import '../../../core/models/widget_selection.dart';
import '../../../core/theme/app_theme.dart';

class PropertiesPanel extends StatefulWidget {
  final WidgetNode? selectedWidget;
  final WidgetSelection? selectedAstWidget;
  final Map<String, dynamic> additionalProperties;
  final Function(String, dynamic)? onPropertyChange;

  const PropertiesPanel({
    super.key,
    this.selectedWidget,
    this.selectedAstWidget,
    this.additionalProperties = const {},
    this.onPropertyChange,
  });

  @override
  State<PropertiesPanel> createState() => _PropertiesPanelState();
}

class _PropertiesPanelState extends State<PropertiesPanel> {
  final Map<String, TextEditingController> _controllers = {};
  String? _expandedSection;

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  String? get _widgetType {
    return widget.selectedAstWidget?.widgetType ?? widget.selectedWidget?.type;
  }

  String? get _widgetName {
    return widget.selectedWidget?.name ?? widget.selectedAstWidget?.widgetType;
  }

  Map<String, dynamic> get _properties {
    return {
      ...widget.selectedWidget?.properties ?? {},
      ...widget.selectedAstWidget?.properties ?? {},
      ...widget.additionalProperties,
    };
  }

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
            child: _widgetType == null
                ? _buildEmptyState()
                : _buildPropertiesForm(context),
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
          const Icon(Icons.tune, size: 18, color: Colors.white70),
          const SizedBox(width: 8),
          Text(
            'Properties',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
          ),
          if (_widgetType != null) ...[
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                _widgetType!,
                style: TextStyle(
                  fontSize: 11,
                  color: AppTheme.primaryColor,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.touch_app_outlined, size: 48, color: Colors.white24),
          SizedBox(height: 16),
          Text(
            'Select a widget',
            style: TextStyle(color: Colors.white38),
          ),
          SizedBox(height: 8),
          Text(
            'Properties will appear here',
            style: TextStyle(color: Colors.white24, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildPropertiesForm(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Widget Info Section
        _buildCollapsibleSection(
          'Widget Info',
          'info',
          [
            if (_widgetName != null) _buildInfoRow('Name', _widgetName!),
            _buildInfoRow('Type', _widgetType!),
            if (widget.selectedWidget?.id != null)
              _buildInfoRow('ID', widget.selectedWidget!.id),
            if (widget.selectedAstWidget?.lineNumber != null)
              _buildInfoRow('Line', widget.selectedAstWidget!.lineNumber.toString()),
          ],
        ),

        // Widget-specific properties
        if (_properties.isNotEmpty) ...[
          const SizedBox(height: 12),
          _buildCollapsibleSection(
            'Properties',
            'properties',
            _properties.entries.map((entry) {
              return _buildSmartPropertyField(entry.key, entry.value);
            }).toList(),
          ),
        ],

        // Layout section for layout widgets
        if (_isLayoutWidget()) ...[
          const SizedBox(height: 12),
          _buildCollapsibleSection(
            'Layout',
            'layout',
            _buildLayoutProperties(),
          ),
        ],

        // Style section
        const SizedBox(height: 12),
        _buildCollapsibleSection(
          'Style',
          'style',
          _buildStyleProperties(),
        ),

        // Actions section
        const SizedBox(height: 16),
        _buildActionsSection(),
      ],
    );
  }

  Widget _buildCollapsibleSection(String title, String key, List<Widget> children) {
    final isExpanded = _expandedSection == null || _expandedSection == key;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () {
            setState(() {
              _expandedSection = _expandedSection == key ? null : key;
            });
          },
          child: Row(
            children: [
              Icon(
                isExpanded ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_right,
                size: 16,
                color: Colors.white38,
              ),
              const SizedBox(width: 4),
              Text(
                title.toUpperCase(),
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.white38,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ),
        if (isExpanded) ...[
          const SizedBox(height: 12),
          ...children,
        ],
      ],
    );
  }

  bool _isLayoutWidget() {
    final layoutTypes = ['Column', 'Row', 'Stack', 'Wrap', 'Flex', 'ListView', 'GridView'];
    return layoutTypes.contains(_widgetType);
  }

  List<Widget> _buildLayoutProperties() {
    return [
      _buildDropdownField(
        'mainAxisAlignment',
        _properties['mainAxisAlignment'] ?? 'start',
        ['start', 'center', 'end', 'spaceBetween', 'spaceAround', 'spaceEvenly'],
      ),
      _buildDropdownField(
        'crossAxisAlignment',
        _properties['crossAxisAlignment'] ?? 'center',
        ['start', 'center', 'end', 'stretch', 'baseline'],
      ),
      _buildDropdownField(
        'mainAxisSize',
        _properties['mainAxisSize'] ?? 'max',
        ['max', 'min'],
      ),
    ];
  }

  List<Widget> _buildStyleProperties() {
    return [
      _buildColorField('backgroundColor', _parseColor(_properties['color'])),
      _buildNumberField('borderRadius', _properties['borderRadius'] as num? ?? 0),
      _buildEdgeInsetsField('padding', _properties['padding']),
      _buildEdgeInsetsField('margin', _properties['margin']),
    ];
  }

  Widget _buildSmartPropertyField(String name, dynamic value) {
    // Determine field type based on property name and value
    if (name.toLowerCase().contains('color')) {
      return _buildColorField(name, _parseColor(value));
    }

    if (name.toLowerCase().contains('size') ||
        name.toLowerCase().contains('width') ||
        name.toLowerCase().contains('height') ||
        name.toLowerCase().contains('radius') ||
        name.toLowerCase().contains('padding') ||
        name.toLowerCase().contains('margin')) {
      return _buildNumberField(name, value as num? ?? 0);
    }

    if (name.toLowerCase().contains('alignment')) {
      return _buildDropdownField(
        name,
        value?.toString() ?? 'center',
        ['topLeft', 'topCenter', 'topRight', 'centerLeft', 'center', 'centerRight', 'bottomLeft', 'bottomCenter', 'bottomRight'],
      );
    }

    if (value is bool) {
      return _buildBooleanField(name, value);
    }

    if (value is num) {
      return _buildNumberField(name, value);
    }

    // Default to text field
    return _buildTextField(name, value?.toString() ?? '');
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 60,
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, color: Colors.white54),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 12, color: Colors.white),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(String name, String value) {
    _controllers[name] ??= TextEditingController(text: value);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _formatPropertyName(name),
            style: const TextStyle(fontSize: 12, color: Colors.white54),
          ),
          const SizedBox(height: 4),
          TextFormField(
            controller: _controllers[name],
            style: const TextStyle(fontSize: 13, color: Colors.white),
            decoration: InputDecoration(
              isDense: true,
              filled: true,
              fillColor: const Color(0xFF2D2D3F),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: BorderSide(color: AppTheme.primaryColor, width: 1),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
            onChanged: (newValue) => widget.onPropertyChange?.call(name, newValue),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownField(String name, String value, List<String> options) {
    // Ensure value is in options
    if (!options.contains(value)) {
      value = options.first;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _formatPropertyName(name),
            style: const TextStyle(fontSize: 12, color: Colors.white54),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF2D2D3F),
              borderRadius: BorderRadius.circular(6),
            ),
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              underline: const SizedBox(),
              dropdownColor: const Color(0xFF2D2D3F),
              style: const TextStyle(fontSize: 13, color: Colors.white),
              items: options.map((opt) {
                return DropdownMenuItem(value: opt, child: Text(opt));
              }).toList(),
              onChanged: (newValue) => widget.onPropertyChange?.call(name, newValue),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNumberField(String name, num value) {
    final key = '${name}_num';
    _controllers[key] ??= TextEditingController(text: value.toString());

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              _formatPropertyName(name),
              style: const TextStyle(fontSize: 12, color: Colors.white54),
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildSmallButton(Icons.remove, () {
                final currentValue = num.tryParse(_controllers[key]!.text) ?? 0;
                _controllers[key]!.text = (currentValue - 1).toString();
                widget.onPropertyChange?.call(name, currentValue - 1);
              }),
              const SizedBox(width: 4),
              SizedBox(
                width: 60,
                child: TextFormField(
                  controller: _controllers[key],
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 13, color: Colors.white),
                  decoration: InputDecoration(
                    isDense: true,
                    filled: true,
                    fillColor: const Color(0xFF2D2D3F),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  ),
                  onChanged: (newValue) => widget.onPropertyChange?.call(name, num.tryParse(newValue)),
                ),
              ),
              const SizedBox(width: 4),
              _buildSmallButton(Icons.add, () {
                final currentValue = num.tryParse(_controllers[key]!.text) ?? 0;
                _controllers[key]!.text = (currentValue + 1).toString();
                widget.onPropertyChange?.call(name, currentValue + 1);
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSmallButton(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: const Color(0xFF2D2D3F),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Icon(icon, size: 14, color: Colors.white54),
      ),
    );
  }

  Widget _buildBooleanField(String name, bool value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              _formatPropertyName(name),
              style: const TextStyle(fontSize: 12, color: Colors.white54),
            ),
          ),
          Switch(
            value: value,
            activeTrackColor: AppTheme.primaryColor.withValues(alpha: 0.5),
            activeThumbColor: AppTheme.primaryColor,
            onChanged: (newValue) => widget.onPropertyChange?.call(name, newValue),
          ),
        ],
      ),
    );
  }

  Widget _buildColorField(String name, Color value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              _formatPropertyName(name),
              style: const TextStyle(fontSize: 12, color: Colors.white54),
            ),
          ),
          InkWell(
            onTap: () => _showColorPicker(name, value),
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: value,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.white24),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEdgeInsetsField(String name, dynamic value) {
    double all = 0;
    if (value is num) {
      all = value.toDouble();
    } else if (value is Map) {
      all = (value['all'] ?? value['left'] ?? 0).toDouble();
    }

    return _buildNumberField(name, all);
  }

  Widget _buildActionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'ACTIONS',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Colors.white38,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                icon: Icons.wrap_text,
                label: 'Wrap',
                onTap: () {},
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildActionButton(
                icon: Icons.content_copy,
                label: 'Copy',
                onTap: () {},
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                icon: Icons.delete_outline,
                label: 'Delete',
                isDestructive: true,
                onTap: () {},
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isDestructive
              ? Colors.red.withValues(alpha: 0.1)
              : const Color(0xFF2D2D3F),
          borderRadius: BorderRadius.circular(6),
          border: isDestructive
              ? Border.all(color: Colors.red.withValues(alpha: 0.3))
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 14,
              color: isDestructive ? Colors.red : Colors.white54,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isDestructive ? Colors.red : Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showColorPicker(String name, Color currentColor) {
    final colors = [
      Colors.transparent,
      Colors.white,
      Colors.black,
      Colors.red,
      Colors.pink,
      Colors.purple,
      Colors.deepPurple,
      Colors.indigo,
      Colors.blue,
      Colors.lightBlue,
      Colors.cyan,
      Colors.teal,
      Colors.green,
      Colors.lightGreen,
      Colors.lime,
      Colors.yellow,
      Colors.amber,
      Colors.orange,
      Colors.deepOrange,
      Colors.brown,
      Colors.grey,
      Colors.blueGrey,
    ];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.customColors['surface'],
        title: Text(
          'Select Color',
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
        content: SizedBox(
          width: 280,
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: colors.map((color) {
              final isSelected = color == currentColor;
              return InkWell(
                onTap: () {
                  widget.onPropertyChange?.call(name, color);
                  Navigator.of(context).pop();
                },
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isSelected ? AppTheme.primaryColor : Colors.white24,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: color == Colors.transparent
                      ? const Icon(Icons.block, size: 20, color: Colors.white38)
                      : null,
                ),
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Color _parseColor(dynamic value) {
    if (value == null) return Colors.transparent;
    if (value is Color) return value;
    if (value is String) {
      if (value.startsWith('#')) {
        try {
          return Color(int.parse(value.substring(1), radix: 16) + 0xFF000000);
        } catch (e) {
          return Colors.transparent;
        }
      }
    }
    return Colors.transparent;
  }

  String _formatPropertyName(String name) {
    // Convert camelCase to Title Case
    return name
        .replaceAllMapped(
          RegExp(r'([A-Z])'),
          (match) => ' ${match.group(0)}',
        )
        .trim()
        .split(' ')
        .map((word) => word.isNotEmpty
            ? '${word[0].toUpperCase()}${word.substring(1)}'
            : word)
        .join(' ');
  }
}
