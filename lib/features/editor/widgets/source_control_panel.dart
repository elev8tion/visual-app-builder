
import 'package:flutter/material.dart';
import '../../../../core/services/git_service.dart';
import '../../../../core/theme/app_theme.dart';

class SourceControlPanel extends StatefulWidget {
  final GitStatus? gitStatus;
  final bool isLoading;
  final Function(String) onStage;
  final Function(String) onUnstage;
  final Function(String) onCommit;
  final VoidCallback onPush;
  final VoidCallback onRefresh;
  final Function(String) onGenerateMessage;

  const SourceControlPanel({
    super.key,
    required this.gitStatus,
    this.isLoading = false,
    required this.onStage,
    required this.onUnstage,
    required this.onCommit,
    required this.onPush,
    required this.onRefresh,
    required this.onGenerateMessage,
  });

  @override
  State<SourceControlPanel> createState() => _SourceControlPanelState();
}

class _SourceControlPanelState extends State<SourceControlPanel> {
  final _messageController = TextEditingController();
  bool _isGeneratingMessage = false;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.gitStatus == null) {
      if (widget.isLoading) {
        return const Center(child: CircularProgressIndicator());
      }
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('No Git Repository Found', style: TextStyle(color: Colors.white54)),
            const SizedBox(height: 16),
             ElevatedButton(
              onPressed: widget.onRefresh,
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor),
              child: const Text('Initialize / Refresh'),
            ),
          ],
        ),
      );
    }

    final stagedFiles = widget.gitStatus!.files.where((f) => f.isStaged).toList();
    final changesFiles = widget.gitStatus!.files.where((f) => !f.isStaged).toList();

    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(12),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: Color(0xFF3D3D4F))),
          ),
          child: Row(
            children: [
              const Text('Source Control', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.refresh, size: 16, color: Colors.white70),
                onPressed: widget.onRefresh,
                tooltip: 'Refresh Status',
              ),
              IconButton(
                icon: const Icon(Icons.cloud_upload_outlined, size: 16, color: Colors.white70),
                onPressed: widget.onPush,
                tooltip: 'Push to Remote',
              ),
            ],
          ),
        ),

        // Commit Input
        Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _messageController,
                maxLines: 3,
                style: const TextStyle(fontSize: 12, color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Message (Cmd+Enter to commit)',
                  hintStyle: const TextStyle(color: Colors.white24),
                  filled: true,
                  fillColor: const Color(0xFF1E1E2E),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.all(12),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: stagedFiles.isEmpty ? null : () {
                        if (_messageController.text.isNotEmpty) {
                          widget.onCommit(_messageController.text);
                          _messageController.clear();
                        }
                      },
                      icon: const Icon(Icons.check, size: 14),
                      label: const Text('Commit'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 8),
                        minimumSize: const Size(0, 32),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                         // TODO: Call AI to generate message
                         // For now just simulate
                         widget.onGenerateMessage('Generate commit message based on staged changes');
                      },
                      icon: const Icon(Icons.auto_awesome, size: 14),
                      label: const Text('Generate'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 8),
                        minimumSize: const Size(0, 32),
                        side: BorderSide(color: AppTheme.primaryColor.withOpacity(0.5)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        
        const Divider(height: 1, color: Color(0xFF3D3D4F)),

        // Files List
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(8),
            children: [
              if (stagedFiles.isNotEmpty) ...[
                _buildSectionHeader('STAGED CHANGES', stagedFiles.length),
                ...stagedFiles.map((file) => _buildFileItem(file)),
                const SizedBox(height: 16),
              ],
              
              _buildSectionHeader('CHANGES', changesFiles.length),
              if (changesFiles.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text('No changes', style: TextStyle(color: Colors.white24, fontSize: 12)),
                ),
              ...changesFiles.map((file) => _buildFileItem(file)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, int count) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Row(
        children: [
          Text(title, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white54)),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(
              color: Colors.white10,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text('$count', style: const TextStyle(fontSize: 10, color: Colors.white70)),
          ),
        ],
      ),
    );
  }

  Widget _buildFileItem(GitFileStatus file) {
    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      child: Row(
        children: [
          IconButton(
            icon: Icon(
              file.isStaged ? Icons.remove : Icons.add, 
              size: 14, 
              color: Colors.white54
            ),
            onPressed: () {
              if (file.isStaged) {
                widget.onUnstage(file.path);
              } else {
                widget.onStage(file.path);
              }
            },
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
          ),
           Text(
            file.status, 
            style: TextStyle(
              color: _getStatusColor(file.status),
              fontWeight: FontWeight.bold,
              fontSize: 12,
            )
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              file.path,
              style: const TextStyle(color: Colors.white70, fontSize: 13),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // TODO: Open file button?
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'M': return Colors.amber;
      case 'A': return Colors.green;
      case 'D': return Colors.red;
      case '??': return Colors.green.withOpacity(0.7);
      default: return Colors.white54;
    }
  }
}
