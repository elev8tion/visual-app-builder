import 'dart:io';
import 'package:archive/archive.dart';
import 'package:file_picker/file_picker.dart' as picker;
import 'package:path/path.dart' as path;
import '../models/widget_node.dart';
import '../models/widget_selection.dart';
import '../templates/project_templates.dart';
import 'terminal_service.dart';
import 'config_service.dart';

/// Project Manager Service
///
/// Handles loading Flutter projects from zip files or directories,
/// managing project files, and project state.
class ProjectManagerService {
  static final ProjectManagerService _instance = ProjectManagerService._();
  static ProjectManagerService get instance => _instance;
  ProjectManagerService._();

  FlutterProject? _currentProject;
  FlutterProject? get currentProject => _currentProject;
  String? get currentProjectPath => _currentProject?.path;

  /// Load a Flutter project from a zip file using file picker
  Future<FlutterProject?> loadProjectFromZip() async {
    try {
      // On macOS/desktop, withData doesn't work - must use file path
      final result = await picker.FilePicker.platform.pickFiles(
        type: picker.FileType.custom,
        allowedExtensions: ['zip'],
        withData: false,  // Bytes don't work on macOS, use path instead
      );

      if (result == null || result.files.isEmpty) {
        return null;
      }

      final file = result.files.first;

      // Read bytes from file path (required for macOS)
      List<int> bytes;
      if (file.path != null) {
        bytes = await File(file.path!).readAsBytes();
      } else if (file.bytes != null) {
        bytes = file.bytes!;
      } else {
        throw Exception('Failed to read file: no path or bytes available');
      }

      return await _extractProjectFromBytes(bytes, file.name);
    } catch (e) {
      throw Exception('Failed to load project: $e');
    }
  }

  /// Load a Flutter project from a directory using folder picker
  Future<FlutterProject?> loadProjectFromDirectory() async {
    try {
      final result = await picker.FilePicker.platform.getDirectoryPath();

      if (result == null) {
        return null;
      }

      return await _loadProjectFromPath(result);
    } catch (e) {
      throw Exception('Failed to load project: $e');
    }
  }

  /// Extract project from zip bytes
  Future<FlutterProject> _extractProjectFromBytes(List<int> bytes, String fileName) async {
    final archive = ZipDecoder().decodeBytes(bytes);
    final files = <ProjectFile>[];
    String projectName = fileName.replaceAll('.zip', '');
    String basePath = '';

    // Find the base path (first directory that contains lib or pubspec.yaml)
    for (final file in archive) {
      if (file.name.endsWith('pubspec.yaml')) {
        basePath = path.dirname(file.name);
        if (basePath == '.') basePath = '';
        break;
      }
    }

    // Extract files
    for (final file in archive) {
      if (file.isFile) {
        String filePath = file.name;

        // Remove base path prefix if present
        if (basePath.isNotEmpty && filePath.startsWith(basePath)) {
          filePath = filePath.substring(basePath.length);
          if (filePath.startsWith('/')) {
            filePath = filePath.substring(1);
          }
        }

        // Skip hidden files and build directories
        if (_shouldSkipFile(filePath)) continue;

        final content = _decodeFileContent(file);
        files.add(ProjectFile(
          path: filePath,
          content: content,
        ));
      }
    }

    // Extract project name from pubspec.yaml if available
    final pubspec = files.where((f) => f.fileName == 'pubspec.yaml').firstOrNull;
    if (pubspec != null) {
      final nameMatch = RegExp(r'^name:\s*(.+)$', multiLine: true).firstMatch(pubspec.content);
      if (nameMatch != null) {
        projectName = nameMatch.group(1)?.trim() ?? projectName;
      }
    }

    _currentProject = FlutterProject(
      name: projectName,
      path: projectName,
      files: files,
      createdAt: DateTime.now(),
      lastOpened: DateTime.now(),
    );

    return _currentProject!;
  }

  /// Load project from a directory path
  Future<FlutterProject> _loadProjectFromPath(String dirPath) async {
    final directory = Directory(dirPath);
    final files = <ProjectFile>[];
    final projectName = path.basename(dirPath);

    await for (final entity in directory.list(recursive: true)) {
      if (entity is File) {
        final relativePath = path.relative(entity.path, from: dirPath);

        // Skip hidden files and build directories
        if (_shouldSkipFile(relativePath)) continue;

        String content = '';
        try {
          content = await entity.readAsString();
        } catch (e) {
          // Skip binary files
          continue;
        }

        files.add(ProjectFile(
          path: relativePath,
          content: content,
        ));
      }
    }

    _currentProject = FlutterProject(
      name: projectName,
      path: dirPath,
      files: files,
      createdAt: DateTime.now(),
      lastOpened: DateTime.now(),
    );

    return _currentProject!;
  }

  /// Decode file content from archive file
  String _decodeFileContent(ArchiveFile file) {
    try {
      return String.fromCharCodes(file.content as List<int>);
    } catch (e) {
      return '';
    }
  }

  /// Check if file should be skipped
  bool _shouldSkipFile(String filePath) {
    final parts = filePath.split('/');

    // Skip hidden files and directories
    if (parts.any((p) => p.startsWith('.'))) return true;

    // Skip build directories
    if (parts.contains('build')) return true;
    if (parts.contains('.dart_tool')) return true;
    if (parts.contains('.idea')) return true;
    if (parts.contains('android') && parts.contains('gradle')) return true;
    if (parts.contains('ios') && parts.contains('Pods')) return true;

    // Only include text-like files
    final ext = path.extension(filePath).toLowerCase();
    final textExtensions = [
      '.dart', '.yaml', '.yml', '.json', '.md', '.txt',
      '.xml', '.html', '.css', '.js', '.ts', '.gradle',
      '.properties', '.swift', '.kt', '.java', '.plist',
    ];

    if (ext.isEmpty) return true;
    if (!textExtensions.contains(ext)) return true;

    return false;
  }

  /// Get file content by path
  String? getFileContent(String filePath) {
    return _currentProject?.findFileByPath(filePath)?.content;
  }

  /// Update file content in memory and on disk
  Future<void> saveFile(String filePath, String content) async {
    if (_currentProject != null) {
      // 1. Update in memory
      _currentProject = _currentProject!.updateFile(filePath, content);
      
      // 2. Write to disk
      final fullPath = path.join(_currentProject!.path, filePath);
      final file = File(fullPath);
      await file.writeAsString(content);
    }
  }

  /// Create a new file
  Future<void> createFile(String fileName, String parentPath) async {
    if (_currentProject != null) {
      final fullPath = path.join(_currentProject!.path, parentPath, fileName);
      final file = File(fullPath);
      
      if (await file.exists()) {
        throw Exception('File already exists');
      }
      
      await file.create(recursive: true);
      
      // Update project state by reloading or adding manually
      // For simplicity, we'll reload the project from the updated directory structure
      // or we could just add it to the list if we want to be faster
      final relativePath = path.join(parentPath, fileName);
       _currentProject = _currentProject!.addFile(ProjectFile(
        path: relativePath,
        content: '',
      ));
    }
  }

  /// Create a new directory
  Future<void> createDirectory(String dirName, String parentPath) async {
    if (_currentProject != null) {
      final fullPath = path.join(_currentProject!.path, parentPath, dirName);
      final dir = Directory(fullPath);
      
      if (await dir.exists()) {
        throw Exception('Directory already exists');
      }
      
      await dir.create(recursive: true);
      
      // We don't strictly track empty directories in ProjectFile list usually, 
      // but the getProjectFileTree rebuilds from the file list.
      // If we want it to show up, we might need to handle it or just rely on 
      // the file explorer re-scanning.
      // For now, let's assumes the UI will refresh the file tree.
    }
  }

  /// Get all dart files in the project
  List<ProjectFile> getDartFiles() {
    return _currentProject?.dartFiles ?? [];
  }

  /// Get project file tree as FileNode list for UI
  List<FileNode> getProjectFileTree() {
    if (_currentProject == null) return [];

    final nodes = <String, FileNode>{};
    final rootNodes = <FileNode>[];

    // Sort files by path
    final sortedFiles = List<ProjectFile>.from(_currentProject!.files)
      ..sort((a, b) => a.path.compareTo(b.path));

    for (final file in sortedFiles) {
      final parts = file.path.split('/');
      String currentPath = '';

      for (int i = 0; i < parts.length; i++) {
        final part = parts[i];
        final parentPath = currentPath;
        currentPath = currentPath.isEmpty ? part : '$currentPath/$part';

        if (!nodes.containsKey(currentPath)) {
          final isDirectory = i < parts.length - 1;
          final node = FileNode(
            name: part,
            path: currentPath,
            isDirectory: isDirectory,
            isExpanded: isDirectory && i < 2, // Expand first 2 levels
            children: const [],
          );
          nodes[currentPath] = node;

          if (parentPath.isEmpty) {
            rootNodes.add(node);
          } else if (nodes.containsKey(parentPath)) {
            final parent = nodes[parentPath]!;
            nodes[parentPath] = FileNode(
              name: parent.name,
              path: parent.path,
              isDirectory: parent.isDirectory,
              isExpanded: parent.isExpanded,
              children: [...parent.children, node],
            );
          }
        }
      }
    }

    return _buildFinalTree(rootNodes, nodes);
  }

  /// Build final tree with updated children
  List<FileNode> _buildFinalTree(List<FileNode> nodes, Map<String, FileNode> allNodes) {
    return nodes.map((node) {
      final updatedNode = allNodes[node.path] ?? node;
      if (updatedNode.isDirectory && updatedNode.children.isNotEmpty) {
        return FileNode(
          name: updatedNode.name,
          path: updatedNode.path,
          isDirectory: updatedNode.isDirectory,
          isExpanded: updatedNode.isExpanded,
          children: _buildFinalTree(updatedNode.children, allNodes),
        );
      }
      return updatedNode;
    }).toList();
  }

  /// Check if project is valid Flutter project
  bool get isValidProject => _currentProject?.isValidFlutterProject ?? false;

  /// Clear current project
  void clearProject() {
    _currentProject = null;
  }

  // ==================== Project Creation ====================

  final TerminalService _terminal = TerminalService.instance;
  final ConfigService _config = ConfigService.instance;

  /// Create a new Flutter project from template
  ///
  /// Returns a stream of progress messages during creation
  Stream<String> createNewProject({
    required String name,
    required String outputPath,
    ProjectTemplate template = ProjectTemplate.blank,
    StateManagement stateManagement = StateManagement.provider,
    String? organization,
    List<String>? platforms,
  }) async* {
    final projectPath = path.join(outputPath, name);

    yield 'Creating Flutter project: $name\n';
    yield 'Location: $projectPath\n';
    yield 'Template: ${template.name}\n';
    yield 'State Management: ${stateManagement.name}\n\n';

    // Step 1: Run flutter create
    yield '=== Step 1: Running flutter create ===\n';
    final org = organization ?? await _config.getOrganization();

    await for (final output in _terminal.createProject(
      name: name,
      outputPath: outputPath,
      organization: org,
      platforms: platforms,
    )) {
      yield output;
    }

    // Check if project was created successfully
    final pubspecFile = File(path.join(projectPath, 'pubspec.yaml'));
    if (!await pubspecFile.exists()) {
      yield '\nError: Project creation failed. pubspec.yaml not found.\n';
      return;
    }

    yield '\n=== Step 2: Applying template ===\n';

    // Step 2: Apply template files
    if (template != ProjectTemplate.blank) {
      final templateConfig = ProjectTemplates.getTemplate(template);
      if (templateConfig != null) {
        yield 'Applying ${templateConfig.name} template...\n';

        // Get template files from config
        final templateFiles = templateConfig.fileTemplates;

        for (final entry in templateFiles.entries) {
          final filePath = path.join(projectPath, entry.key);
          final file = File(filePath);

          // Create directory if needed
          final dir = Directory(path.dirname(filePath));
          if (!await dir.exists()) {
            await dir.create(recursive: true);
          }

          await file.writeAsString(entry.value);
          yield 'Created: ${entry.key}\n';
        }
      }
    }

    // Step 3: Add dependencies to pubspec.yaml
    yield '\n=== Step 3: Updating dependencies ===\n';

    final dependencies = _getDependencies(stateManagement, template);
    if (dependencies.isNotEmpty) {
      await _addDependenciesToPubspec(projectPath, dependencies);
      yield 'Added dependencies: ${dependencies.keys.join(', ')}\n';
    }

    // Step 4: Run flutter pub get
    yield '\n=== Step 4: Getting packages ===\n';
    await for (final output in _terminal.pubGet(projectPath: projectPath)) {
      yield output;
    }

    // Step 5: Load the created project
    yield '\n=== Step 5: Loading project ===\n';
    try {
      await _loadProjectFromPath(projectPath);
      await _config.addRecentProject(projectPath);
      yield 'Project loaded successfully!\n';
    } catch (e) {
      yield 'Warning: Could not load project: $e\n';
    }

    yield '\n=== Project creation complete! ===\n';
    yield 'Project path: $projectPath\n';
  }

  /// Get dependencies based on state management and template
  Map<String, String> _getDependencies(StateManagement sm, ProjectTemplate template) {
    final deps = <String, String>{};

    // State management dependencies
    switch (sm) {
      case StateManagement.provider:
        deps['provider'] = '^6.1.1';
        break;
      case StateManagement.riverpod:
        deps['flutter_riverpod'] = '^2.4.9';
        deps['riverpod_annotation'] = '^2.3.3';
        break;
      case StateManagement.bloc:
        deps['flutter_bloc'] = '^8.1.3';
        deps['bloc'] = '^8.1.2';
        break;
      case StateManagement.getx:
        deps['get'] = '^4.6.6';
        break;
      case StateManagement.none:
        break;
    }

    // Template-specific dependencies
    switch (template) {
      case ProjectTemplate.ecommerce:
        deps['cached_network_image'] = '^3.3.1';
        deps['intl'] = '^0.19.0';
        break;
      case ProjectTemplate.social:
        deps['cached_network_image'] = '^3.3.1';
        deps['timeago'] = '^3.6.1';
        break;
      case ProjectTemplate.dashboard:
        deps['fl_chart'] = '^0.66.2';
        deps['intl'] = '^0.19.0';
        break;
      default:
        break;
    }

    return deps;
  }

  /// Add dependencies to pubspec.yaml
  Future<void> _addDependenciesToPubspec(String projectPath, Map<String, String> dependencies) async {
    final pubspecPath = path.join(projectPath, 'pubspec.yaml');
    final pubspecFile = File(pubspecPath);

    if (!await pubspecFile.exists()) return;

    String content = await pubspecFile.readAsString();

    // Find the dependencies section
    final depsPattern = RegExp(r'dependencies:\s*\n', multiLine: true);
    final match = depsPattern.firstMatch(content);

    if (match != null) {
      final insertPosition = match.end;
      final depsToAdd = StringBuffer();

      for (final entry in dependencies.entries) {
        // Check if dependency already exists
        if (!content.contains('${entry.key}:')) {
          depsToAdd.writeln('  ${entry.key}: ${entry.value}');
        }
      }

      if (depsToAdd.isNotEmpty) {
        content = content.substring(0, insertPosition) +
                  depsToAdd.toString() +
                  content.substring(insertPosition);
        await pubspecFile.writeAsString(content);
      }
    }
  }

  /// Pick output directory for new project
  Future<String?> pickProjectLocation() async {
    try {
      final result = await picker.FilePicker.platform.getDirectoryPath(
        dialogTitle: 'Select location for new project',
      );
      return result;
    } catch (e) {
      return null;
    }
  }

  /// Get the default project directory
  Future<String> getDefaultProjectDirectory() async {
    final defaultPath = await _config.getDefaultProjectPath();
    if (defaultPath != null && await Directory(defaultPath).exists()) {
      return defaultPath;
    }

    // Fall back to Documents/FlutterProjects
    final home = Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'] ?? '.';
    final documentsPath = path.join(home, 'Documents', 'FlutterProjects');
    final dir = Directory(documentsPath);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return documentsPath;
  }
}
