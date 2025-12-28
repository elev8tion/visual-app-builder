import 'package:flutter/material.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:flutter_highlight/themes/monokai-sublime.dart';
import 'package:highlight/languages/dart.dart';
import '../../../core/theme/app_theme.dart';

class CodeEditorPanel extends StatefulWidget {
  final String? code;
  final String? fileName;
  final Function(String)? onCodeChange;

  const CodeEditorPanel({
    super.key,
    this.code,
    this.fileName,
    this.onCodeChange,
  });

  @override
  State<CodeEditorPanel> createState() => _CodeEditorPanelState();
}

class _CodeEditorPanelState extends State<CodeEditorPanel> {
  late CodeController _codeController;

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
      _codeController.text = widget.code!;
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  static const String _defaultCode = '''
import 'package:flutter/material.dart';

class MyWidget extends StatelessWidget {
  const MyWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My App'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Hello World',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {},
              child: const Text('Click Me'),
            ),
          ],
        ),
      ),
    );
  }
}
''';

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
          _buildToolButton(icon: Icons.undo, onTap: () {}),
          const SizedBox(width: 8),
          _buildToolButton(icon: Icons.redo, onTap: () {}),
          const SizedBox(width: 16),
          _buildToolButton(icon: Icons.format_align_left, onTap: () {}),
          const SizedBox(width: 8),
          _buildToolButton(icon: Icons.search, onTap: () {}),
          const SizedBox(width: 16),
          _buildActionButton(
            icon: Icons.save,
            label: 'Save',
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildToolButton({required IconData icon, VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Icon(icon, size: 18, color: Colors.white54),
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
      child: CodeTheme(
        data: CodeThemeData(styles: monokaiSublimeTheme),
        child: SingleChildScrollView(
          child: CodeField(
            controller: _codeController,
            textStyle: const TextStyle(
              fontFamily: 'JetBrains Mono',
              fontSize: 14,
            ),
            onChanged: (code) => widget.onCodeChange?.call(code),
          ),
        ),
      ),
    );
  }
}
