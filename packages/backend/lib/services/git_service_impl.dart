import 'dart:io';

import 'package:visual_app_builder_shared/visual_app_builder_shared.dart';

/// Backend implementation of Git service using dart:io
class GitServiceImpl implements IGitService {
  @override
  Future<bool> isGitRepository(String path) async {
    final gitDir = Directory('$path/.git');
    return gitDir.exists();
  }

  @override
  Future<GitStatus> getStatus(String projectPath) async {
    if (!await isGitRepository(projectPath)) {
      return const GitStatus(branch: 'Not a git repository');
    }

    // Get branch name
    final branchResult = await Process.run(
      'git',
      ['branch', '--show-current'],
      workingDirectory: projectPath,
    );
    final branch = branchResult.stdout.toString().trim();

    // Get status
    final statusResult = await Process.run(
      'git',
      ['status', '--porcelain'],
      workingDirectory: projectPath,
    );

    final staged = <GitFileChange>[];
    final unstaged = <GitFileChange>[];
    final untracked = <String>[];

    final lines = statusResult.stdout.toString().split('\n');
    for (final line in lines) {
      if (line.length < 3) continue;

      final indexStatus = line[0];
      final workTreeStatus = line[1];
      final filePath = line.substring(3);

      // Staged changes
      if (indexStatus != ' ' && indexStatus != '?') {
        staged.add(GitFileChange(
          path: filePath,
          changeType: _parseChangeType(indexStatus),
        ));
      }

      // Unstaged changes
      if (workTreeStatus != ' ' && workTreeStatus != '?') {
        unstaged.add(GitFileChange(
          path: filePath,
          changeType: _parseChangeType(workTreeStatus),
        ));
      }

      // Untracked files
      if (indexStatus == '?' && workTreeStatus == '?') {
        untracked.add(filePath);
      }
    }

    // Check for remote
    final remoteResult = await Process.run(
      'git',
      ['remote'],
      workingDirectory: projectPath,
    );
    final hasRemote = remoteResult.stdout.toString().trim().isNotEmpty;

    // Get ahead/behind counts if remote exists
    int? ahead;
    int? behind;
    if (hasRemote) {
      try {
        final abResult = await Process.run(
          'git',
          ['rev-list', '--left-right', '--count', '@{u}...HEAD'],
          workingDirectory: projectPath,
        );
        if (abResult.exitCode == 0) {
          final parts = abResult.stdout.toString().trim().split('\t');
          if (parts.length == 2) {
            behind = int.tryParse(parts[0]);
            ahead = int.tryParse(parts[1]);
          }
        }
      } catch (e) {
        // No upstream configured
      }
    }

    return GitStatus(
      branch: branch,
      staged: staged,
      unstaged: unstaged,
      untracked: untracked,
      hasRemote: hasRemote,
      ahead: ahead,
      behind: behind,
    );
  }

  GitChangeType _parseChangeType(String status) {
    switch (status) {
      case 'A':
        return GitChangeType.added;
      case 'M':
        return GitChangeType.modified;
      case 'D':
        return GitChangeType.deleted;
      case 'R':
        return GitChangeType.renamed;
      case 'C':
        return GitChangeType.copied;
      default:
        return GitChangeType.modified;
    }
  }

  @override
  Future<void> stageFiles(String projectPath, List<String> files) async {
    await Process.run(
      'git',
      ['add', ...files],
      workingDirectory: projectPath,
    );
  }

  @override
  Future<void> stageAll(String projectPath) async {
    await Process.run(
      'git',
      ['add', '-A'],
      workingDirectory: projectPath,
    );
  }

  @override
  Future<void> unstageFiles(String projectPath, List<String> files) async {
    await Process.run(
      'git',
      ['reset', 'HEAD', ...files],
      workingDirectory: projectPath,
    );
  }

  @override
  Future<GitCommit> commit(String projectPath, String message) async {
    final result = await Process.run(
      'git',
      ['commit', '-m', message],
      workingDirectory: projectPath,
    );

    if (result.exitCode != 0) {
      throw Exception('Commit failed: ${result.stderr}');
    }

    // Get the commit info
    final logResult = await Process.run(
      'git',
      ['log', '-1', '--format=%H|%s|%an|%aI'],
      workingDirectory: projectPath,
    );

    final parts = logResult.stdout.toString().trim().split('|');
    return GitCommit(
      hash: parts.isNotEmpty ? parts[0] : '',
      message: parts.length > 1 ? parts[1] : message,
      author: parts.length > 2 ? parts[2] : 'Unknown',
      date: parts.length > 3 ? DateTime.parse(parts[3]) : DateTime.now(),
    );
  }

  @override
  Future<void> push(String projectPath, {String? remote, String? branch}) async {
    final args = ['push'];
    if (remote != null) args.add(remote);
    if (branch != null) args.add(branch);

    final result = await Process.run(
      'git',
      args,
      workingDirectory: projectPath,
    );

    if (result.exitCode != 0) {
      throw Exception('Push failed: ${result.stderr}');
    }
  }

  @override
  Future<void> pull(String projectPath, {String? remote, String? branch}) async {
    final args = ['pull'];
    if (remote != null) args.add(remote);
    if (branch != null) args.add(branch);

    final result = await Process.run(
      'git',
      args,
      workingDirectory: projectPath,
    );

    if (result.exitCode != 0) {
      throw Exception('Pull failed: ${result.stderr}');
    }
  }

  @override
  Future<List<GitCommit>> getCommitHistory(String projectPath, {int limit = 50}) async {
    final result = await Process.run(
      'git',
      ['log', '-$limit', '--format=%H|%s|%an|%aI'],
      workingDirectory: projectPath,
    );

    if (result.exitCode != 0) {
      return [];
    }

    final commits = <GitCommit>[];
    final lines = result.stdout.toString().trim().split('\n');

    for (final line in lines) {
      if (line.isEmpty) continue;
      final parts = line.split('|');
      if (parts.length >= 4) {
        commits.add(GitCommit(
          hash: parts[0],
          message: parts[1],
          author: parts[2],
          date: DateTime.parse(parts[3]),
        ));
      }
    }

    return commits;
  }

  @override
  Future<void> init(String projectPath) async {
    final result = await Process.run(
      'git',
      ['init'],
      workingDirectory: projectPath,
    );

    if (result.exitCode != 0) {
      throw Exception('Git init failed: ${result.stderr}');
    }
  }

  @override
  Future<String> getCurrentBranch(String projectPath) async {
    final result = await Process.run(
      'git',
      ['branch', '--show-current'],
      workingDirectory: projectPath,
    );
    return result.stdout.toString().trim();
  }

  @override
  Future<List<String>> getBranches(String projectPath) async {
    final result = await Process.run(
      'git',
      ['branch', '-a'],
      workingDirectory: projectPath,
    );

    return result.stdout
        .toString()
        .split('\n')
        .map((b) => b.replaceAll('*', '').trim())
        .where((b) => b.isNotEmpty)
        .toList();
  }

  @override
  Future<void> checkout(String projectPath, String branch) async {
    final result = await Process.run(
      'git',
      ['checkout', branch],
      workingDirectory: projectPath,
    );

    if (result.exitCode != 0) {
      throw Exception('Checkout failed: ${result.stderr}');
    }
  }

  @override
  Future<void> createBranch(String projectPath, String branchName) async {
    final result = await Process.run(
      'git',
      ['checkout', '-b', branchName],
      workingDirectory: projectPath,
    );

    if (result.exitCode != 0) {
      throw Exception('Create branch failed: ${result.stderr}');
    }
  }

  @override
  Future<void> discardChanges(String projectPath, String filePath) async {
    await Process.run(
      'git',
      ['checkout', '--', filePath],
      workingDirectory: projectPath,
    );
  }
}
