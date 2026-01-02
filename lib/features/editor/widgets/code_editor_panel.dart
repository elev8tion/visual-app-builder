import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:flutter_highlight/themes/monokai-sublime.dart';
import 'package:highlight/languages/dart.dart';
import '../../../core/theme/app_theme.dart';

class CodeEditorPanel extends StatefulWidget {
  final String? code;
  final String? fileName;
  final Function(String)? onCodeChange;
  final VoidCallback? onSave;
  final VoidCallback? onUndo;
  final VoidCallback? onRedo;
  final bool canUndo;
  final bool canRedo;

  const CodeEditorPanel({
    super.key,
    this.code,
    this.fileName,
    this.onCodeChange,
    this.onSave,
    this.onUndo,
    this.onRedo,
    this.canUndo = false,
    this.canRedo = false,
  });

  @override
  State<CodeEditorPanel> createState() => _CodeEditorPanelState();
}

class _CodeEditorPanelState extends State<CodeEditorPanel> {
  late CodeController _codeController;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _codeController = CodeController(
      text: widget.code ?? _defaultCode,
      language: dart,
    );
  }

  @override
  void didUpdateWidget(CodeEditorPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.code != oldWidget.code && widget.code != null) {
      // Only update if the new code is significantly different to avoid cursor jumps
      // or check if we are currently editing (might need a flag)
      // For now, straightforward update, but checking equality
      if (_codeController.text != widget.code) {
         _codeController.text = widget.code!;
      }
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _codeController.dispose();
    super.dispose();
  }

  static const String _defaultCode = '// Open a project to view code';

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.customColors['background'],
      child: Column(
        children: [
          _buildToolbar(context),
          const Divider(height: 1, color: Color(0xFF3D3D4F)),
          Expanded(child: _buildEditor()),
        ],
      ),
    );
  }

  Widget _buildToolbar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          const Icon(Icons.code, size: 18, color: Colors.white70),
          const SizedBox(width: 8),
          Text(
            widget.fileName ?? 'main.dart',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: Colors.orange,
              shape: BoxShape.circle,
            ),
          ),
          const Spacer(),
          _buildToolButton(
            icon: Icons.undo,
            onTap: widget.canUndo ? widget.onUndo : null,
          ),
          const SizedBox(width: 8),
          _buildToolButton(
            icon: Icons.redo,
            onTap: widget.canRedo ? widget.onRedo : null,
          ),
          const SizedBox(width: 16),
          _buildToolButton(icon: Icons.format_align_left, onTap: () {}),
          const SizedBox(width: 8),
          _buildToolButton(icon: Icons.search, onTap: () {}),
          const SizedBox(width: 16),
          _buildActionButton(
            icon: Icons.save,
            label: 'Save',
            onTap: widget.onSave,
          ),
        ],
      ),
    );
  }

  Widget _buildToolButton({required IconData icon, VoidCallback? onTap}) {
    final isEnabled = onTap != null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Icon(icon, size: 18, color: isEnabled ? Colors.white54 : Colors.white24),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppTheme.primaryColor,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: Colors.white),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(fontSize: 12, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditor() {
    return Container(
      color: const Color(0xFF1E1E1E),
      child: CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.keyS, meta: true): () {
            widget.onSave?.call();
          },
          // Also support Ctrl+S for Windows/Linux
          const SingleActivator(LogicalKeyboardKey.keyS, control: true): () {
            widget.onSave?.call();
          },
        },
        child: Focus(
          autofocus: true,
          child: CodeTheme(
            data: CodeThemeData(styles: monokaiSublimeTheme),
            child: SingleChildScrollView(
              child: CodeField(
                controller: _codeController,
                textStyle: const TextStyle(
                  fontFamily: 'JetBrains Mono',
                  fontSize: 14,
                ),
                onChanged: (code) {
                  if (_debounce?.isActive ?? false) _debounce!.cancel();
                  _debounce = Timer(const Duration(milliseconds: 600), () {
                    widget.onCodeChange?.call(code);
                  });
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
