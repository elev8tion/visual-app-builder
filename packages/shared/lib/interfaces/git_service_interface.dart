import '../models/git.dart';

/// Interface for Git operations
///
/// Handles Git repository interactions.
abstract class IGitService {
  /// Check if path is a Git repository
  Future<bool> isGitRepository(String path);

  /// Get Git status for a repository
  Future<GitStatus> getStatus(String projectPath);

  /// Stage files for commit
  Future<void> stageFiles(String projectPath, List<String> files);

  /// Stage all changes
  Future<void> stageAll(String projectPath);

  /// Unstage files
  Future<void> unstageFiles(String projectPath, List<String> files);

  /// Commit staged changes
  Future<GitCommit> commit(String projectPath, String message);

  /// Push to remote
  Future<void> push(String projectPath, {String? remote, String? branch});

  /// Pull from remote
  Future<void> pull(String projectPath, {String? remote, String? branch});

  /// Get commit history
  Future<List<GitCommit>> getCommitHistory(String projectPath, {int limit = 50});

  /// Initialize a new Git repository
  Future<void> init(String projectPath);

  /// Get current branch name
  Future<String> getCurrentBranch(String projectPath);

  /// Get list of branches
  Future<List<String>> getBranches(String projectPath);

  /// Checkout a branch
  Future<void> checkout(String projectPath, String branch);

  /// Create a new branch
  Future<void> createBranch(String projectPath, String branchName);

  /// Discard changes to a file
  Future<void> discardChanges(String projectPath, String filePath);
}
