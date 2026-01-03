import '../models/file_node.dart';
import '../models/project.dart';

/// Interface for project manager operations
///
/// Handles loading, creating, and managing Flutter projects.
/// Backend implements with dart:io file operations.
abstract class IProjectManagerService {
  /// Currently loaded project
  FlutterProject? get currentProject;

  /// Current project path
  String? get currentProjectPath;

  /// Whether current project is valid Flutter project
  bool get isValidProject;

  /// Open a project from a path
  Future<FlutterProject?> openProject(String path);

  /// Create a new Flutter project
  Stream<String> createProject({
    required String name,
    required String outputPath,
    String? template,
    String? stateManagement,
    String? organization,
    List<String>? platforms,
  });

  /// Get file tree for current project
  List<FileNode> getProjectFileTree();

  /// Read file content
  Future<String?> readFile(String filePath);

  /// Write file content
  Future<void> writeFile(String filePath, String content);

  /// Create a new file
  Future<void> createFile(String fileName, String parentPath);

  /// Create a new directory
  Future<void> createDirectory(String dirName, String parentPath);

  /// Delete a file or directory
  Future<void> delete(String path);

  /// Get recent projects
  Future<List<RecentProject>> getRecentProjects();

  /// Get default project directory
  Future<String> getDefaultProjectDirectory();

  /// Clear current project
  void clearProject();
}
