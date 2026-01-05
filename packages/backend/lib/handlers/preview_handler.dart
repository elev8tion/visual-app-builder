import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:path/path.dart' as path;

/// REST handler for project preview operations
/// Builds Flutter Web and serves the preview in an IFrame
class PreviewHandler {
  final Map<String, _PreviewSession> _activePreviews = {};
  final int _basePreviewPort;

  PreviewHandler({int basePreviewPort = 8100}) : _basePreviewPort = basePreviewPort;

  Router get router {
    final router = Router();

    router.post('/build', _buildPreview);
    router.get('/status/<projectId>', _getPreviewStatus);
    router.post('/stop/<projectId>', _stopPreview);
    router.get('/list', _listPreviews);

    return router;
  }

  /// POST /api/preview/build
  /// Builds Flutter Web and starts a dev server for preview
  Future<Response> _buildPreview(Request request) async {
    try {
      final body = jsonDecode(await request.readAsString());
      final projectPath = body['projectPath'] as String?;
      final projectId = body['projectId'] as String?;

      if (projectPath == null) {
        return Response.badRequest(
          body: jsonEncode({'error': 'projectPath is required'}),
          headers: {'content-type': 'application/json'},
        );
      }

      // Generate project ID if not provided
      final id = projectId ?? path.basename(projectPath);

      // Check if preview already running
      if (_activePreviews.containsKey(id)) {
        final session = _activePreviews[id]!;
        return Response.ok(
          jsonEncode({
            'success': true,
            'projectId': id,
            'previewUrl': 'http://localhost:${session.port}',
            'status': session.status,
          }),
          headers: {'content-type': 'application/json'},
        );
      }

      // Find available port
      final port = await _findAvailablePort();

      // Create preview session
      final session = _PreviewSession(
        projectId: id,
        projectPath: projectPath,
        port: port,
      );

      _activePreviews[id] = session;

      // Start building in background
      _startPreviewBuild(session);

      return Response.ok(
        jsonEncode({
          'success': true,
          'projectId': id,
          'previewUrl': 'http://localhost:$port',
          'status': 'building',
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

  /// Start the preview build process
  Future<void> _startPreviewBuild(_PreviewSession session) async {
    try {
      session.status = 'building';

      // Run flutter build web
      final buildResult = await Process.run(
        'flutter',
        ['build', 'web', '--release'],
        workingDirectory: session.projectPath,
        runInShell: true,
      );

      if (buildResult.exitCode != 0) {
        session.status = 'error';
        session.error = buildResult.stderr.toString();
        return;
      }

      // Start simple HTTP server for build/web
      final webBuildPath = path.join(session.projectPath, 'build', 'web');
      if (!await Directory(webBuildPath).exists()) {
        session.status = 'error';
        session.error = 'Build output not found';
        return;
      }

      // Use Python's http.server or dart's shelf for serving
      session.process = await Process.start(
        'python3',
        ['-m', 'http.server', session.port.toString()],
        workingDirectory: webBuildPath,
        runInShell: true,
      );

      // Wait a moment for server to start
      await Future.delayed(const Duration(seconds: 2));

      session.status = 'running';
    } catch (e) {
      session.status = 'error';
      session.error = e.toString();
    }
  }

  /// GET /api/preview/status/<projectId>
  Future<Response> _getPreviewStatus(Request request, String projectId) async {
    final session = _activePreviews[projectId];
    if (session == null) {
      return Response.notFound(
        jsonEncode({'error': 'Preview not found'}),
        headers: {'content-type': 'application/json'},
      );
    }

    return Response.ok(
      jsonEncode({
        'projectId': projectId,
        'status': session.status,
        'previewUrl': 'http://localhost:${session.port}',
        'error': session.error,
      }),
      headers: {'content-type': 'application/json'},
    );
  }

  /// POST /api/preview/stop/<projectId>
  Future<Response> _stopPreview(Request request, String projectId) async {
    final session = _activePreviews.remove(projectId);
    if (session == null) {
      return Response.notFound(
        jsonEncode({'error': 'Preview not found'}),
        headers: {'content-type': 'application/json'},
      );
    }

    session.process?.kill();

    return Response.ok(
      jsonEncode({'success': true}),
      headers: {'content-type': 'application/json'},
    );
  }

  /// GET /api/preview/list
  Future<Response> _listPreviews(Request request) async {
    final previews = _activePreviews.entries.map((e) => {
          'projectId': e.key,
          'projectPath': e.value.projectPath,
          'port': e.value.port,
          'status': e.value.status,
          'previewUrl': 'http://localhost:${e.value.port}',
        }).toList();

    return Response.ok(
      jsonEncode({'previews': previews}),
      headers: {'content-type': 'application/json'},
    );
  }

  /// Find an available port starting from base port
  Future<int> _findAvailablePort() async {
    var port = _basePreviewPort;

    while (_activePreviews.values.any((s) => s.port == port)) {
      port++;
    }

    // Verify port is actually available
    try {
      final server = await ServerSocket.bind(InternetAddress.anyIPv4, port);
      await server.close();
      return port;
    } catch (e) {
      return _findAvailablePort();
    }
  }

  /// Stop all previews
  void dispose() {
    for (final session in _activePreviews.values) {
      session.process?.kill();
    }
    _activePreviews.clear();
  }
}

/// Internal class to track preview sessions
class _PreviewSession {
  final String projectId;
  final String projectPath;
  final int port;

  String status = 'pending';
  String? error;
  Process? process;

  _PreviewSession({
    required this.projectId,
    required this.projectPath,
    required this.port,
  });
}
