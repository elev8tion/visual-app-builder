import 'package:flutter/material.dart';
import '../../../core/services/theme_service.dart';

class ThemeColorPicker extends StatefulWidget {
  final Color? currentColor;
  final Function(Color) onColorChanged;
  final ThemeDataModel themeData;

  const ThemeColorPicker({
    super.key,
    required this.currentColor,
    required this.onColorChanged,
    required this.themeData,
  });

  @override
  State<ThemeColorPicker> createState() => _ThemeColorPickerState();
}

class _ThemeColorPickerState extends State<ThemeColorPicker> {
  bool _showCustomPicker = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Current Color Display
        Container(
          height: 40,
          decoration: BoxDecoration(
            color: widget.currentColor ?? Colors.transparent,
            border: Border.all(color: Colors.white24),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            children: [
              Expanded(
                child: Center(
                  child: Text(
                    widget.currentColor != null
                        ? '#${widget.currentColor!.value.toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}'
                        : 'No Color',
                    style: TextStyle(
                      color: widget.currentColor != null
                          ? _getContrastColor(widget.currentColor!)
                          : Colors.white54,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
              IconButton(
                icon: Icon(
                  _showCustomPicker ? Icons.palette : Icons.palette_outlined,
                  size: 16,
                  color: Colors.white70,
                ),
                onPressed: () => setState(() => _showCustomPicker = !_showCustomPicker),
                tooltip: 'Custom Color',
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 12),

        // Theme Colors
        if (widget.themeData.colors.isNotEmpty) ...[
          const Text(
            'THEME COLORS',
            style: TextStyle(fontSize: 10, color: Colors.white54, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.themeData.colors.entries.map((entry) {
              final isSelected = widget.currentColor?.value == entry.value.value;
              return GestureDetector(
                onTap: () => widget.onColorChanged(entry.value),
                child: Tooltip(
                  message: entry.key,
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: entry.value,
                      border: Border.all(
                        color: isSelected ? Colors.white : Colors.white24,
                        width: isSelected ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: isSelected
                        ? Icon(Icons.check, size: 16, color: _getContrastColor(entry.value))
                        : null,
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
        ],

        // Custom Color Picker
        if (_showCustomPicker) ...[
          const Text(
            'CUSTOM COLOR',
            style: TextStyle(fontSize: 10, color: Colors.white54, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          _buildSimpleColorPicker(),
        ],
      ],
    );
  }

  Widget _buildSimpleColorPicker() {
    // Simple preset colors for MVP
    final presetColors = [
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
      Colors.black,
      Colors.white,
    ];

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: presetColors.map((color) {
        final isSelected = widget.currentColor?.value == color.value;
        return GestureDetector(
          onTap: () => widget.onColorChanged(color),
          child: Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: color,
              border: Border.all(
                color: isSelected ? Colors.white : Colors.white24,
                width: isSelected ? 2 : 1,
              ),
              borderRadius: BorderRadius.circular(4),
            ),
            child: isSelected
                ? Icon(Icons.check, size: 12, color: _getContrastColor(color))
                : null,
          ),
        );
      }).toList(),
    );
  }

  Color _getContrastColor(Color color) {
    final luminance = color.computeLuminance();
    return luminance > 0.5 ? Colors.black : Colors.white;
  }
}
