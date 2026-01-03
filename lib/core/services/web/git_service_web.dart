import 'package:visual_app_builder_shared/visual_app_builder_shared.dart';

import '../api_client.dart';

/// Web implementation of git service using API client
class GitServiceWeb implements IGitService {
  final ApiClient _apiClient;

  GitServiceWeb(this._apiClient);

  @override
  Future<bool> isGitRepository(String path) async {
    try {
      final status = await _apiClient.getGitStatus(path);
      return status['isRepository'] as bool? ?? true;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<GitStatus> getStatus(String projectPath) async {
    final response = await _apiClient.getGitStatus(projectPath);
    return GitStatus.fromJson(response);
  }

  @override
  Future<void> stageFiles(String projectPath, List<String> files) async {
    await _apiClient.stageFiles(projectPath, files);
  }

  @override
  Future<void> stageAll(String projectPath) async {
    await _apiClient.stageAll(projectPath);
  }

  @override
  Future<void> unstageFiles(String projectPath, List<String> files) async {
    await _apiClient.unstageFiles(projectPath, files);
  }

  @override
  Future<GitCommit> commit(String projectPath, String message) async {
    final response = await _apiClient.commit(projectPath, message);
    return GitCommit.fromJson(response);
  }

  @override
  Future<void> push(String projectPath, {String? remote, String? branch}) async {
    await _apiClient.push(projectPath, remote: remote, branch: branch);
  }

  @override
  Future<void> pull(String projectPath, {String? remote, String? branch}) async {
    await _apiClient.pull(projectPath, remote: remote, branch: branch);
  }

  @override
  Future<List<GitCommit>> getCommitHistory(String projectPath, {int limit = 50}) async {
    final commits = await _apiClient.getCommitHistory(projectPath, limit: limit);
    return commits.map((c) => GitCommit.fromJson(c)).toList();
  }

  @override
  Future<void> init(String projectPath) async {
    await _apiClient.gitInit(projectPath);
  }

  @override
  Future<String> getCurrentBranch(String projectPath) async {
    return _apiClient.getCurrentBranch(projectPath);
  }

  @override
  Future<List<String>> getBranches(String projectPath) async {
    return _apiClient.getBranches(projectPath);
  }

  @override
  Future<void> checkout(String projectPath, String branch) async {
    await _apiClient.checkout(projectPath, branch);
  }

  @override
  Future<void> createBranch(String projectPath, String branchName) async {
    await _apiClient.createBranch(projectPath, branchName);
  }

  @override
  Future<void> discardChanges(String projectPath, String filePath) async {
    await _apiClient.discardChanges(projectPath, filePath);
  }
}
