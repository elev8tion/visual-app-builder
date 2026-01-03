import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:visual_app_builder_shared/visual_app_builder_shared.dart';

import 'config_service_impl.dart';

/// Backend implementation of project manager using dart:io
class ProjectManagerImpl implements IProjectManagerService {
  final ConfigServiceImpl _configService;
  FlutterProject? _currentProject;
  List<ProjectFile> _projectFiles = [];

  ProjectManagerImpl(this._configService);

  @override
  FlutterProject? get currentProject => _currentProject;

  @override
  String? get currentProjectPath => _currentProject?.path;

  @override
  bool get isValidProject {
    if (_currentProject == null) return false;
    return _projectFiles.any((f) => f.name == 'pubspec.yaml');
  }

  @override
  Future<FlutterProject?> openProject(String path) async {
    final directory = Directory(path);
    if (!await directory.exists()) {
      throw Exception('Directory does not exist: $path');
    }

    _projectFiles = [];
    final projectName = p.basename(path);

    await for (final entity in directory.list(recursive: true)) {
      if (entity is File) {
        final relativePath = p.relative(entity.path, from: path);

        if (_shouldSkipFile(relativePath)) continue;

        String content = '';
        try {
          content = await entity.readAsString();
        } catch (e) {
          continue; // Skip binary files
        }

        _projectFiles.add(ProjectFile(
          path: relativePath,
          name: p.basename(relativePath),
          content: content,
        ));
      }
    }

    _currentProject = FlutterProject(
      name: projectName,
      path: path,
      createdAt: DateTime.now(),
      modifiedAt: DateTime.now(),
    );

    await _configService.addRecentProject(path);
    return _currentProject;
  }

  @override
  Stream<String> createProject({
    required String name,
    required String outputPath,
    String? template,
    String? stateManagement,
    String? organization,
    List<String>? platforms,
  }) async* {
    final projectPath = p.join(outputPath, name);

    yield 'Creating Flutter project: $name\n';
    yield 'Location: $projectPath\n\n';

    final args = ['create', name];

    if (organization != null) {
      args.addAll(['--org', organization]);
    }

    if (platforms != null && platforms.isNotEmpty) {
      args.addAll(['--platforms', platforms.join(',')]);
    }

    if (template != null) {
      args.addAll(['-t', template]);
    }

    yield '> flutter ${args.join(' ')}\n';

    try {
      final process = await Process.start(
        'flutter',
        args,
        workingDirectory: outputPath,
        runInShell: Platform.isWindows,
      );

      await for (final data in process.stdout.transform(const SystemEncoding().decoder)) {
        yield data;
      }

      await for (final data in process.stderr.transform(const SystemEncoding().decoder)) {
        yield data;
      }

      final exitCode = await process.exitCode;
      yield '\nFlutter create completed with exit code: $exitCode\n';

      if (exitCode == 0) {
        // Load the created project
        await openProject(projectPath);
        yield 'Project loaded successfully!\n';
      }
    } catch (e) {
      yield 'Error creating project: $e\n';
    }
  }

  @override
  List<FileNode> getProjectFileTree() {
    if (_currentProject == null) return [];

    final nodes = <String, FileNode>{};
    final rootNodes = <FileNode>[];

    final sortedFiles = List<ProjectFile>.from(_projectFiles)
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
            isExpanded: isDirectory && i < 2,
            children: const [],
          );
          nodes[currentPath] = node;

          if (parentPath.isEmpty) {
            rootNodes.add(node);
          } else if (nodes.containsKey(parentPath)) {
            final parent = nodes[parentPath]!;
            nodes[parentPath] = parent.copyWith(
              children: [...parent.children, node],
            );
          }
        }
      }
    }

    return _buildFinalTree(rootNodes, nodes);
  }

  List<FileNode> _buildFinalTree(List<FileNode> nodes, Map<String, FileNode> allNodes) {
    return nodes.map((node) {
      final updatedNode = allNodes[node.path] ?? node;
      if (updatedNode.isDirectory && updatedNode.children.isNotEmpty) {
        return updatedNode.copyWith(
          children: _buildFinalTree(updatedNode.children, allNodes),
        );
      }
      return updatedNode;
    }).toList();
  }

  @override
  Future<String?> readFile(String filePath) async {
    if (_currentProject == null) return null;

    final fullPath = p.join(_currentProject!.path, filePath);
    final file = File(fullPath);

    if (await file.exists()) {
      try {
        return await file.readAsString();
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  @override
  Future<void> writeFile(String filePath, String content) async {
    if (_currentProject == null) {
      throw Exception('No project loaded');
    }

    final fullPath = p.join(_currentProject!.path, filePath);
    final file = File(fullPath);

    // Create directory if needed
    final dir = Directory(p.dirname(fullPath));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }

    await file.writeAsString(content);

    // Update in-memory cache
    final index = _projectFiles.indexWhere((f) => f.path == filePath);
    if (index >= 0) {
      _projectFiles[index] = ProjectFile(
        path: filePath,
        name: p.basename(filePath),
        content: content,
      );
    } else {
      _projectFiles.add(ProjectFile(
        path: filePath,
        name: p.basename(filePath),
        content: content,
      ));
    }
  }

  @override
  Future<void> createFile(String fileName, String parentPath) async {
    if (_currentProject == null) {
      throw Exception('No project loaded');
    }

    final fullPath = p.join(_currentProject!.path, parentPath, fileName);
    final file = File(fullPath);

    if (await file.exists()) {
      throw Exception('File already exists');
    }

    await file.create(recursive: true);

    final relativePath = p.join(parentPath, fileName);
    _projectFiles.add(ProjectFile(
      path: relativePath,
      name: fileName,
      content: '',
    ));
  }

  @override
  Future<void> createDirectory(String dirName, String parentPath) async {
    if (_currentProject == null) {
      throw Exception('No project loaded');
    }

    final fullPath = p.join(_currentProject!.path, parentPath, dirName);
    final dir = Directory(fullPath);

    if (await dir.exists()) {
      throw Exception('Directory already exists');
    }

    await dir.create(recursive: true);
  }

  @override
  Future<void> delete(String path) async {
    if (_currentProject == null) {
      throw Exception('No project loaded');
    }

    final fullPath = p.join(_currentProject!.path, path);
    final file = File(fullPath);
    final dir = Directory(fullPath);

    if (await file.exists()) {
      await file.delete();
      _projectFiles.removeWhere((f) => f.path == path);
    } else if (await dir.exists()) {
      await dir.delete(recursive: true);
      _projectFiles.removeWhere((f) => f.path.startsWith(path));
    }
  }

  @override
  Future<List<RecentProject>> getRecentProjects() async {
    return _configService.getRecentProjects();
  }

  @override
  Future<String> getDefaultProjectDirectory() async {
    final defaultPath = await _configService.getDefaultProjectPath();
    if (defaultPath != null && await Directory(defaultPath).exists()) {
      return defaultPath;
    }

    final home = Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'] ?? '.';
    final documentsPath = p.join(home, 'Documents', 'FlutterProjects');
    final dir = Directory(documentsPath);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return documentsPath;
  }

  @override
  void clearProject() {
    _currentProject = null;
    _projectFiles = [];
  }

  bool _shouldSkipFile(String filePath) {
    final parts = filePath.split('/');

    if (parts.any((p) => p.startsWith('.'))) return true;
    if (parts.contains('build')) return true;
    if (parts.contains('.dart_tool')) return true;
    if (parts.contains('.idea')) return true;
    if (parts.contains('android') && parts.contains('gradle')) return true;
    if (parts.contains('ios') && parts.contains('Pods')) return true;

    final ext = p.extension(filePath).toLowerCase();
    final textExtensions = [
      '.dart', '.yaml', '.yml', '.json', '.md', '.txt',
      '.xml', '.html', '.css', '.js', '.ts', '.gradle',
      '.properties', '.swift', '.kt', '.java', '.plist',
    ];

    if (ext.isEmpty) return true;
    if (!textExtensions.contains(ext)) return true;

    return false;
  }
}
