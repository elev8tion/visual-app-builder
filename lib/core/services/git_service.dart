
import 'dart:io';

class GitStatus {
  final String branch;
  final List<GitFileStatus> files;

  GitStatus({required this.branch, required this.files});
}

class GitFileStatus {
  final String path;
  final String status; // 'M' = modified, 'A' = added, 'D' = deleted, '??' = untracked
  final bool isStaged;

  GitFileStatus({required this.path, required this.status, required this.isStaged});
}

class GitService {
  static final GitService _instance = GitService._internal();
  factory GitService() => _instance;
  GitService._internal();

  String? _workingDirectory;

  void setWorkingDirectory(String path) {
    _workingDirectory = path;
  }

  Future<bool> isGitRepository() async {
    if (_workingDirectory == null) return false;
    try {
      final result = await Process.run('git', ['rev-parse', '--is-inside-work-tree'], workingDirectory: _workingDirectory);
      return result.exitCode == 0 && result.stdout.toString().trim() == 'true';
    } catch (e) {
      return false;
    }
  }

  Future<void> init() async {
    if (_workingDirectory == null) throw Exception('Working directory not set');
    await Process.run('git', ['init'], workingDirectory: _workingDirectory);
  }

  Future<GitStatus> getStatus() async {
    if (_workingDirectory == null) throw Exception('Working directory not set');
    
    // Get branch name
    final branchResult = await Process.run('git', ['branch', '--show-current'], workingDirectory: _workingDirectory);
    final branch = branchResult.stdout.toString().trim();

    // Get status
    final statusResult = await Process.run('git', ['status', '--porcelain'], workingDirectory: _workingDirectory);
    final lines = statusResult.stdout.toString().split('\n').where((l) => l.isNotEmpty);

    final files = <GitFileStatus>[];
    for (final line in lines) {
      if (line.length < 4) continue;
      final x = line[0];
      final y = line[1];
      final path = line.substring(3).trim();

      // X = index (staged), Y = worktree (unstaged)
      // If X is not ' ' or '?', then it has staged changes
      if (x != ' ' && x != '?') {
         files.add(GitFileStatus(path: path, status: x, isStaged: true));
      }
      // If Y is not ' ', then it has unstaged changes
      if (y != ' ') {
        files.add(GitFileStatus(path: path, status: y, isStaged: false));
      }
      // Untracked
      if (x == '?' && y == '?') {
        files.add(GitFileStatus(path: path, status: '??', isStaged: false));
      }
    }

    return GitStatus(branch: branch.isEmpty ? 'HEAD' : branch, files: files);
  }

  Future<void> stageFile(String path) async {
    if (_workingDirectory == null) throw Exception('Working directory not set');
    await Process.run('git', ['add', path], workingDirectory: _workingDirectory);
  }

  Future<void> unstageFile(String path) async {
    if (_workingDirectory == null) throw Exception('Working directory not set');
    await Process.run('git', ['reset', 'HEAD', path], workingDirectory: _workingDirectory);
  }

  Future<void> commit(String message) async {
    if (_workingDirectory == null) throw Exception('Working directory not set');
    await Process.run('git', ['commit', '-m', message], workingDirectory: _workingDirectory);
  }

  Future<void> push() async {
    if (_workingDirectory == null) throw Exception('Working directory not set');
    // Assumes upstream is configured
    await Process.run('git', ['push'], workingDirectory: _workingDirectory);
  }
  
  Future<void> pull() async {
    if (_workingDirectory == null) throw Exception('Working directory not set');
    await Process.run('git', ['pull'], workingDirectory: _workingDirectory);
  }
}
