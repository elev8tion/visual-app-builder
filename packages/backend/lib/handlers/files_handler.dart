import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../services/project_manager_impl.dart';

/// REST handler for file operations
class FilesHandler {
  final ProjectManagerImpl _projectManager;

  FilesHandler(this._projectManager);

  Router get router {
    final router = Router();

    // List directory contents
    router.get('/', _listFiles);
    router.get('/tree', _getFileTree);
    router.get('/content', _readFile);
    router.put('/content', _writeFile);
    router.post('/', _createFile);
    router.delete('/', _deleteFile);

    return router;
  }

  /// GET /api/files?path=... - List directory contents
  Future<Response> _listFiles(Request request) async {
    try {
      final tree = _projectManager.getProjectFileTree();
      return Response.ok(
        jsonEncode({'files': tree.map((n) => n.toJson()).toList()}),
        headers: {'content-type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': e.toString()}),
        headers: {'content-type': 'application/json'},
      );
    }
  }

  /// GET /api/files/tree - Get full file tree
  Future<Response> _getFileTree(Request request) async {
    try {
      final tree = _projectManager.getProjectFileTree();
      return Response.ok(
        jsonEncode({'tree': tree.map((n) => n.toJson()).toList()}),
        headers: {'content-type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': e.toString()}),
        headers: {'content-type': 'application/json'},
      );
    }
  }

  /// GET /api/files/content?path=... - Read file content
  Future<Response> _readFile(Request request) async {
    try {
      final filePath = request.url.queryParameters['path'];
      if (filePath == null || filePath.isEmpty) {
        return Response.badRequest(
          body: jsonEncode({'error': 'path parameter required'}),
          headers: {'content-type': 'application/json'},
        );
      }

      final content = await _projectManager.readFile(filePath);
      if (content == null) {
        return Response.notFound(
          jsonEncode({'error': 'File not found'}),
          headers: {'content-type': 'application/json'},
        );
      }

      return Response.ok(
        jsonEncode({'path': filePath, 'content': content}),
        headers: {'content-type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': e.toString()}),
        headers: {'content-type': 'application/json'},
      );
    }
  }

  /// PUT /api/files/content - Write file content
  Future<Response> _writeFile(Request request) async {
    try {
      final body = jsonDecode(await request.readAsString());
      final filePath = body['path'] as String?;
      final content = body['content'] as String?;

      if (filePath == null || content == null) {
        return Response.badRequest(
          body: jsonEncode({'error': 'path and content required'}),
          headers: {'content-type': 'application/json'},
        );
      }

      await _projectManager.writeFile(filePath, content);

      return Response.ok(
        jsonEncode({'success': true, 'path': filePath}),
        headers: {'content-type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': e.toString()}),
        headers: {'content-type': 'application/json'},
      );
    }
  }

  /// POST /api/files - Create file or directory
  Future<Response> _createFile(Request request) async {
    try {
      final body = jsonDecode(await request.readAsString());
      final name = body['name'] as String?;
      final parentPath = body['parentPath'] as String? ?? '';
      final isDirectory = body['isDirectory'] as bool? ?? false;

      if (name == null || name.isEmpty) {
        return Response.badRequest(
          body: jsonEncode({'error': 'name required'}),
          headers: {'content-type': 'application/json'},
        );
      }

      if (isDirectory) {
        await _projectManager.createDirectory(name, parentPath);
      } else {
        await _projectManager.createFile(name, parentPath);
      }

      return Response.ok(
        jsonEncode({'success': true, 'name': name}),
        headers: {'content-type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': e.toString()}),
        headers: {'content-type': 'application/json'},
      );
    }
  }

  /// DELETE /api/files?path=... - Delete file or directory
  Future<Response> _deleteFile(Request request) async {
    try {
      final filePath = request.url.queryParameters['path'];
      if (filePath == null || filePath.isEmpty) {
        return Response.badRequest(
          body: jsonEncode({'error': 'path parameter required'}),
          headers: {'content-type': 'application/json'},
        );
      }

      await _projectManager.delete(filePath);

      return Response.ok(
        jsonEncode({'success': true, 'path': filePath}),
        headers: {'content-type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': e.toString()}),
        headers: {'content-type': 'application/json'},
      );
    }
  }
}
