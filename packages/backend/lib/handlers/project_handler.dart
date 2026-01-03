import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../services/project_manager_impl.dart';

/// REST handler for project operations
class ProjectHandler {
  final ProjectManagerImpl _projectManager;

  ProjectHandler(this._projectManager);

  Router get router {
    final router = Router();

    router.post('/create', _createProject);
    router.post('/open', _openProject);
    router.get('/recent', _getRecentProjects);
    router.get('/current', _getCurrentProject);
    router.post('/close', _closeProject);
    router.get('/default-directory', _getDefaultDirectory);

    return router;
  }

  /// POST /api/projects/create (SSE stream)
  Future<Response> _createProject(Request request) async {
    try {
      final body = jsonDecode(await request.readAsString());
      final name = body['name'] as String?;
      final outputPath = body['outputPath'] as String?;
      final template = body['template'] as String?;
      final stateManagement = body['stateManagement'] as String?;
      final organization = body['organization'] as String?;
      final platforms = (body['platforms'] as List<dynamic>?)?.cast<String>();

      if (name == null || outputPath == null) {
        return Response.badRequest(
          body: jsonEncode({'error': 'name and outputPath required'}),
          headers: {'content-type': 'application/json'},
        );
      }

      final stream = _projectManager.createProject(
        name: name,
        outputPath: outputPath,
        template: template,
        stateManagement: stateManagement,
        organization: organization,
        platforms: platforms,
      );

      return Response.ok(
        _sseStream(stream),
        headers: {
          'content-type': 'text/event-stream',
          'cache-control': 'no-cache',
          'connection': 'keep-alive',
        },
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': e.toString()}),
        headers: {'content-type': 'application/json'},
      );
    }
  }

  /// POST /api/projects/open
  Future<Response> _openProject(Request request) async {
    try {
      final body = jsonDecode(await request.readAsString());
      final path = body['path'] as String?;

      if (path == null) {
        return Response.badRequest(
          body: jsonEncode({'error': 'path required'}),
          headers: {'content-type': 'application/json'},
        );
      }

      final project = await _projectManager.openProject(path);
      if (project == null) {
        return Response.notFound(
          jsonEncode({'error': 'Project not found'}),
          headers: {'content-type': 'application/json'},
        );
      }

      return Response.ok(
        jsonEncode({
          'project': project.toJson(),
          'isValid': _projectManager.isValidProject,
        }),
        headers: {'content-type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': e.toString()}),
        headers: {'content-type': 'application/json'},
      );
    }
  }

  /// GET /api/projects/recent
  Future<Response> _getRecentProjects(Request request) async {
    try {
      final projects = await _projectManager.getRecentProjects();
      return Response.ok(
        jsonEncode({
          'projects': projects.map((p) => p.toJson()).toList(),
        }),
        headers: {'content-type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': e.toString()}),
        headers: {'content-type': 'application/json'},
      );
    }
  }

  /// GET /api/projects/current
  Future<Response> _getCurrentProject(Request request) async {
    final project = _projectManager.currentProject;
    if (project == null) {
      return Response.notFound(
        jsonEncode({'error': 'No project loaded'}),
        headers: {'content-type': 'application/json'},
      );
    }

    return Response.ok(
      jsonEncode({
        'project': project.toJson(),
        'isValid': _projectManager.isValidProject,
      }),
      headers: {'content-type': 'application/json'},
    );
  }

  /// POST /api/projects/close
  Future<Response> _closeProject(Request request) async {
    _projectManager.clearProject();
    return Response.ok(
      jsonEncode({'success': true}),
      headers: {'content-type': 'application/json'},
    );
  }

  /// GET /api/projects/default-directory
  Future<Response> _getDefaultDirectory(Request request) async {
    try {
      final directory = await _projectManager.getDefaultProjectDirectory();
      return Response.ok(
        jsonEncode({'directory': directory}),
        headers: {'content-type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': e.toString()}),
        headers: {'content-type': 'application/json'},
      );
    }
  }

  /// Convert stream to SSE format
  Stream<List<int>> _sseStream(Stream<String> source) {
    return source.map((data) {
      final escaped = data.replaceAll('\n', '\ndata: ');
      return utf8.encode('data: $escaped\n\n');
    });
  }
}
