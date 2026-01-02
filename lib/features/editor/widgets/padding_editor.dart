import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PaddingEditor extends StatefulWidget {
  final EdgeInsets? currentPadding;
  final Function(EdgeInsets) onPaddingChanged;

  const PaddingEditor({
    super.key,
    required this.currentPadding,
    required this.onPaddingChanged,
  });

  @override
  State<PaddingEditor> createState() => _PaddingEditorState();
}

class _PaddingEditorState extends State<PaddingEditor> {
  late TextEditingController _topController;
  late TextEditingController _rightController;
  late TextEditingController _bottomController;
  late TextEditingController _leftController;
  bool _isLinked = true;

  @override
  void initState() {
    super.initState();
    final padding = widget.currentPadding ?? EdgeInsets.zero;
    _topController = TextEditingController(text: padding.top.toString());
    _rightController = TextEditingController(text: padding.right.toString());
    _bottomController = TextEditingController(text: padding.bottom.toString());
    _leftController = TextEditingController(text: padding.left.toString());
  }

  @override
  void dispose() {
    _topController.dispose();
    _rightController.dispose();
    _bottomController.dispose();
    _leftController.dispose();
    super.dispose();
  }

  void _updatePadding() {
    final top = double.tryParse(_topController.text) ?? 0;
    final right = double.tryParse(_rightController.text) ?? 0;
    final bottom = double.tryParse(_bottomController.text) ?? 0;
    final left = double.tryParse(_leftController.text) ?? 0;
    
    widget.onPaddingChanged(EdgeInsets.only(
      top: top,
      right: right,
      bottom: bottom,
      left: left,
    ));
  }

  void _updateLinkedValue(String value) {
    if (_isLinked) {
      _topController.text = value;
      _rightController.text = value;
      _bottomController.text = value;
      _leftController.text = value;
      _updatePadding();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Visual Box Model
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.white24),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Column(
            children: [
              // Top
              _buildEdgeInput('Top', _topController, Icons.arrow_upward),
              const SizedBox(height: 8),
              
              // Left, Center, Right
              Row(
                children: [
                  Expanded(
                    child: _buildEdgeInput('Left', _leftController, Icons.arrow_back),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white10,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Center(
                        child: IconButton(
                          icon: Icon(
                            _isLinked ? Icons.link : Icons.link_off,
                            size: 16,
                            color: _isLinked ? Colors.blue : Colors.white54,
                          ),
                          onPressed: () => setState(() => _isLinked = !_isLinked),
                          tooltip: _isLinked ? 'Unlink sides' : 'Link all sides',
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildEdgeInput('Right', _rightController, Icons.arrow_forward),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              
              // Bottom
              _buildEdgeInput('Bottom', _bottomController, Icons.arrow_downward),
            ],
          ),
        ),
        
        const SizedBox(height: 12),
        
        // Quick Presets
        const Text(
          'PRESETS',
          style: TextStyle(fontSize: 10, color: Colors.white54, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildPresetButton('0', EdgeInsets.zero),
            _buildPresetButton('8', const EdgeInsets.all(8)),
            _buildPresetButton('16', const EdgeInsets.all(16)),
            _buildPresetButton('24', const EdgeInsets.all(24)),
          ],
        ),
      ],
    );
  }

  Widget _buildEdgeInput(String label, TextEditingController controller, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 12, color: Colors.white54),
        const SizedBox(width: 4),
        Expanded(
          child: TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
            style: const TextStyle(fontSize: 12, color: Colors.white),
            decoration: InputDecoration(
              labelText: label,
              labelStyle: const TextStyle(fontSize: 10, color: Colors.white54),
              filled: true,
              fillColor: const Color(0xFF1E1E2E),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              isDense: true,
            ),
            onChanged: (value) {
              if (_isLinked) {
                _updateLinkedValue(value);
              } else {
                _updatePadding();
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPresetButton(String label, EdgeInsets padding) {
    return OutlinedButton(
      onPressed: () {
        _topController.text = padding.top.toString();
        _rightController.text = padding.right.toString();
        _bottomController.text = padding.bottom.toString();
        _leftController.text = padding.left.toString();
        _updatePadding();
      },
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        minimumSize: const Size(0, 32),
        side: const BorderSide(color: Colors.white24),
      ),
      child: Text(label, style: const TextStyle(fontSize: 12)),
    );
  }
}
