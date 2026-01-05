import 'package:visual_app_builder_shared/visual_app_builder_shared.dart';

import '../api_client.dart';

/// Web implementation of project manager service using API client
class ProjectManagerWeb implements IProjectManagerService {
  final ApiClient _apiClient;
  FlutterProject? _currentProject;
  String? _currentProjectPath;
  List<FileNode> _cachedFileTree = [];

  ProjectManagerWeb(this._apiClient);

  @override
  FlutterProject? get currentProject => _currentProject;

  @override
  String? get currentProjectPath => _currentProjectPath;

  @override
  bool get isValidProject => _currentProject != null;

  @override
  Stream<String> createProject({
    required String name,
    required String outputPath,
    String? template,
    String? stateManagement,
    String? organization,
    List<String>? platforms,
  }) async* {
    try {
      await for (final line in _apiClient.createProject(
        name: name,
        outputPath: outputPath,
        template: template,
        stateManagement: stateManagement,
        organization: organization,
        platforms: platforms,
      )) {
        yield line;
      }

      // After creation, open the project
      final projectPath = '$outputPath/$name';
      await openProject(projectPath);
    } catch (e) {
      yield 'Error creating project: $e\n';
    }
  }

  @override
  Future<FlutterProject?> openProject(String path) async {
    try {
      final response = await _apiClient.openProject(path);
      final projectData = response['project'] as Map<String, dynamic>;

      _currentProject = FlutterProject.fromJson(projectData);
      _currentProjectPath = path;

      // Fetch and cache file tree immediately after opening project
      await refreshFileTree();

      return _currentProject;
    } catch (e) {
      return null;
    }
  }

  /// Refresh the cached file tree from backend
  Future<void> refreshFileTree() async {
    _cachedFileTree = await fetchFileTree();
  }

  @override
  List<FileNode> getProjectFileTree() {
    // Return cached file tree (populated after openProject or refreshFileTree)
    return _cachedFileTree;
  }

  @override
  Future<String?> readFile(String filePath) async {
    try {
      return await _apiClient.readFile(filePath);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> writeFile(String filePath, String content) async {
    await _apiClient.writeFile(filePath, content);
  }

  @override
  Future<void> createFile(String fileName, String parentPath) async {
    await _apiClient.createFile(fileName, parentPath: parentPath);
    // Refresh cached file tree after file operations
    await refreshFileTree();
  }

  @override
  Future<void> createDirectory(String dirName, String parentPath) async {
    await _apiClient.createFile(dirName, parentPath: parentPath, isDirectory: true);
    // Refresh cached file tree after file operations
    await refreshFileTree();
  }

  @override
  Future<void> delete(String path) async {
    await _apiClient.deleteFile(path);
    // Refresh cached file tree after file operations
    await refreshFileTree();
  }

  @override
  Future<List<RecentProject>> getRecentProjects() async {
    try {
      final projects = await _apiClient.getRecentProjects();
      return projects.map((p) => RecentProject.fromJson(p)).toList();
    } catch (e) {
      return [];
    }
  }

  @override
  Future<String> getDefaultProjectDirectory() async {
    try {
      return await _apiClient.getDefaultDirectory();
    } catch (e) {
      return '';
    }
  }

  @override
  void clearProject() {
    _currentProject = null;
    _currentProjectPath = null;
    _cachedFileTree = [];
  }

  /// Fetch file tree from backend
  Future<List<FileNode>> fetchFileTree() async {
    if (_currentProjectPath == null) return [];

    try {
      final files = await _apiClient.listFiles(_currentProjectPath!);
      return files.map((f) => FileNode.fromJson(f)).toList();
    } catch (e) {
      return [];
    }
  }
}
