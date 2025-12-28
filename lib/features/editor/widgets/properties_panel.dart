import 'package:flutter/material.dart';
import '../../../core/models/widget_node.dart';
import '../../../core/theme/app_theme.dart';

class PropertiesPanel extends StatelessWidget {
  final WidgetNode? selectedWidget;
  final Function(String, dynamic)? onPropertyChange;

  const PropertiesPanel({
    super.key,
    this.selectedWidget,
    this.onPropertyChange,
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
            child: selectedWidget == null
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
          if (selectedWidget != null) ...[
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                selectedWidget!.type,
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
        _buildSection('Widget Info', [
          _buildInfoRow('Name', selectedWidget!.name),
          _buildInfoRow('Type', selectedWidget!.type),
          _buildInfoRow('ID', selectedWidget!.id),
        ]),
        const SizedBox(height: 16),
        _buildSection('Properties', [
          ...selectedWidget!.properties.entries.map((entry) {
            return _buildPropertyField(entry.key, entry.value);
          }),
        ]),
        const SizedBox(height: 16),
        _buildSection('Layout', [
          _buildDropdownField('Alignment', 'center', ['start', 'center', 'end']),
          _buildNumberField('Padding', 16),
          _buildNumberField('Margin', 0),
        ]),
        const SizedBox(height: 16),
        _buildSection('Style', [
          _buildColorField('Background', Colors.transparent),
          _buildNumberField('Border Radius', 8),
          _buildDropdownField('Shadow', 'none', ['none', 'small', 'medium', 'large']),
        ]),
      ],
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.toUpperCase(),
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Colors.white38,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 12),
        ...children,
      ],
    );
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
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPropertyField(String name, dynamic value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name,
            style: const TextStyle(fontSize: 12, color: Colors.white54),
          ),
          const SizedBox(height: 4),
          TextFormField(
            initialValue: value?.toString() ?? '',
            style: const TextStyle(fontSize: 13, color: Colors.white),
            decoration: InputDecoration(
              isDense: true,
              filled: true,
              fillColor: const Color(0xFF2D2D3F),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
            onChanged: (newValue) => onPropertyChange?.call(name, newValue),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownField(String name, String value, List<String> options) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name,
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
              onChanged: (newValue) => onPropertyChange?.call(name, newValue),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNumberField(String name, num value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              name,
              style: const TextStyle(fontSize: 12, color: Colors.white54),
            ),
          ),
          SizedBox(
            width: 80,
            child: TextFormField(
              initialValue: value.toString(),
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
              onChanged: (newValue) => onPropertyChange?.call(name, num.tryParse(newValue)),
            ),
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
              name,
              style: const TextStyle(fontSize: 12, color: Colors.white54),
            ),
          ),
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: value,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.white24),
            ),
          ),
        ],
      ),
    );
  }
}
