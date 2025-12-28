import 'package:flutter/material.dart';
import '../../../core/models/widget_node.dart';
import '../../../core/theme/app_theme.dart';

class FileExplorerPanel extends StatelessWidget {
  final List<FileNode> files;
  final String? currentFile;
  final Function(FileNode)? onFileSelect;
  final Function(FileNode)? onToggleExpand;

  const FileExplorerPanel({
    super.key,
    required this.files,
    this.currentFile,
    this.onFileSelect,
    this.onToggleExpand,
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
            child: files.isEmpty
                ? _buildEmptyState()
                : ListView(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    children: files.map((f) => _buildFileNode(f, 0)).toList(),
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
          const Icon(Icons.folder_open, size: 18, color: Colors.white70),
          const SizedBox(width: 8),
          Text(
            'Explorer',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.create_new_folder_outlined, size: 18, color: Colors.white54),
            onPressed: () {},
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.note_add_outlined, size: 18, color: Colors.white54),
            onPressed: () {},
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
          Icon(Icons.folder_off_outlined, size: 48, color: Colors.white24),
          SizedBox(height: 16),
          Text(
            'No files yet',
            style: TextStyle(color: Colors.white38),
          ),
        ],
      ),
    );
  }

  Widget _buildFileNode(FileNode node, int depth) {
    final isSelected = currentFile == node.path;
    final isDirectory = node.isDirectory;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () {
            if (isDirectory) {
              onToggleExpand?.call(node);
            } else {
              onFileSelect?.call(node);
            }
          },
          child: Container(
            padding: EdgeInsets.only(
              left: 16.0 + (depth * 16.0),
              right: 16,
              top: 6,
              bottom: 6,
            ),
            decoration: BoxDecoration(
              color: isSelected ? AppTheme.primaryColor.withValues(alpha: 0.2) : null,
            ),
            child: Row(
              children: [
                if (isDirectory)
                  Icon(
                    node.isExpanded ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_right,
                    size: 16,
                    color: Colors.white54,
                  )
                else
                  const SizedBox(width: 16),
                const SizedBox(width: 4),
                Icon(
                  _getFileIcon(node),
                  size: 16,
                  color: _getFileIconColor(node),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    node.name,
                    style: TextStyle(
                      fontSize: 13,
                      color: isSelected ? Colors.white : Colors.white70,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (isDirectory && node.isExpanded)
          ...node.children.map((child) => _buildFileNode(child, depth + 1)),
      ],
    );
  }

  IconData _getFileIcon(FileNode node) {
    if (node.isDirectory) {
      return node.isExpanded ? Icons.folder_open : Icons.folder;
    }
    if (node.name.endsWith('.dart')) return Icons.code;
    if (node.name.endsWith('.yaml') || node.name.endsWith('.yml')) return Icons.settings;
    if (node.name.endsWith('.json')) return Icons.data_object;
    if (node.name.endsWith('.md')) return Icons.description;
    return Icons.insert_drive_file;
  }

  Color _getFileIconColor(FileNode node) {
    if (node.isDirectory) return const Color(0xFFFFCA28);
    if (node.name.endsWith('.dart')) return const Color(0xFF42A5F5);
    if (node.name.endsWith('.yaml') || node.name.endsWith('.yml')) return const Color(0xFFEF5350);
    if (node.name.endsWith('.json')) return const Color(0xFFFFCA28);
    if (node.name.endsWith('.md')) return const Color(0xFF78909C);
    return Colors.white54;
  }
}
