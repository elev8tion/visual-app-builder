import 'dart:async';
import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../services/terminal_service_impl.dart';

/// REST handler for terminal operations
class TerminalHandler {
  final TerminalServiceImpl _terminal;

  TerminalHandler(this._terminal);

  Router get router {
    final router = Router();

    router.post('/run', _runProject);
    router.post('/hot-reload', _hotReload);
    router.post('/hot-restart', _hotRestart);
    router.post('/stop', _stop);
    router.post('/build', _buildProject);
    router.post('/pub-get', _pubGet);
    router.post('/clean', _clean);
    router.post('/analyze', _analyze);
    router.post('/test', _test);
    router.post('/command', _runCommand);
    router.get('/devices', _getDevices);
    router.get('/flutter-info', _getFlutterInfo);
    router.get('/status', _getStatus);

    return router;
  }

  /// POST /api/terminal/run - Run Flutter project (SSE stream)
  Future<Response> _runProject(Request request) async {
    try {
      final body = jsonDecode(await request.readAsString());
      final projectPath = body['projectPath'] as String?;
      final device = body['device'] as String?;
      final verbose = body['verbose'] as bool? ?? false;

      if (projectPath == null) {
        return Response.badRequest(
          body: jsonEncode({'error': 'projectPath required'}),
          headers: {'content-type': 'application/json'},
        );
      }

      // Return SSE stream
      final stream = _terminal.runProject(
        projectPath: projectPath,
        device: device,
        verbose: verbose,
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

  /// POST /api/terminal/hot-reload
  Future<Response> _hotReload(Request request) async {
    try {
      await _terminal.hotReload();
      return Response.ok(
        jsonEncode({'success': true}),
        headers: {'content-type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': e.toString()}),
        headers: {'content-type': 'application/json'},
      );
    }
  }

  /// POST /api/terminal/hot-restart
  Future<Response> _hotRestart(Request request) async {
    try {
      await _terminal.hotRestart();
      return Response.ok(
        jsonEncode({'success': true}),
        headers: {'content-type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': e.toString()}),
        headers: {'content-type': 'application/json'},
      );
    }
  }

  /// POST /api/terminal/stop
  Future<Response> _stop(Request request) async {
    try {
      await _terminal.stop();
      return Response.ok(
        jsonEncode({'success': true}),
        headers: {'content-type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': e.toString()}),
        headers: {'content-type': 'application/json'},
      );
    }
  }

  /// POST /api/terminal/build - Build project (SSE stream)
  Future<Response> _buildProject(Request request) async {
    try {
      final body = jsonDecode(await request.readAsString());
      final projectPath = body['projectPath'] as String?;
      final platform = body['platform'] as String?;
      final release = body['release'] as bool? ?? false;
      final verbose = body['verbose'] as bool? ?? false;

      if (projectPath == null || platform == null) {
        return Response.badRequest(
          body: jsonEncode({'error': 'projectPath and platform required'}),
          headers: {'content-type': 'application/json'},
        );
      }

      final stream = _terminal.buildProject(
        projectPath: projectPath,
        platform: platform,
        release: release,
        verbose: verbose,
      );

      return Response.ok(
        _sseStream(stream),
        headers: {
          'content-type': 'text/event-stream',
          'cache-control': 'no-cache',
        },
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': e.toString()}),
        headers: {'content-type': 'application/json'},
      );
    }
  }

  /// POST /api/terminal/pub-get (SSE stream)
  Future<Response> _pubGet(Request request) async {
    try {
      final body = jsonDecode(await request.readAsString());
      final projectPath = body['projectPath'] as String?;

      if (projectPath == null) {
        return Response.badRequest(
          body: jsonEncode({'error': 'projectPath required'}),
          headers: {'content-type': 'application/json'},
        );
      }

      final stream = _terminal.pubGet(projectPath: projectPath);

      return Response.ok(
        _sseStream(stream),
        headers: {
          'content-type': 'text/event-stream',
          'cache-control': 'no-cache',
        },
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': e.toString()}),
        headers: {'content-type': 'application/json'},
      );
    }
  }

  /// POST /api/terminal/clean (SSE stream)
  Future<Response> _clean(Request request) async {
    try {
      final body = jsonDecode(await request.readAsString());
      final projectPath = body['projectPath'] as String?;

      if (projectPath == null) {
        return Response.badRequest(
          body: jsonEncode({'error': 'projectPath required'}),
          headers: {'content-type': 'application/json'},
        );
      }

      final stream = _terminal.clean(projectPath: projectPath);

      return Response.ok(
        _sseStream(stream),
        headers: {
          'content-type': 'text/event-stream',
          'cache-control': 'no-cache',
        },
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': e.toString()}),
        headers: {'content-type': 'application/json'},
      );
    }
  }

  /// POST /api/terminal/analyze (SSE stream)
  Future<Response> _analyze(Request request) async {
    try {
      final body = jsonDecode(await request.readAsString());
      final projectPath = body['projectPath'] as String?;

      if (projectPath == null) {
        return Response.badRequest(
          body: jsonEncode({'error': 'projectPath required'}),
          headers: {'content-type': 'application/json'},
        );
      }

      final stream = _terminal.analyze(projectPath: projectPath);

      return Response.ok(
        _sseStream(stream),
        headers: {
          'content-type': 'text/event-stream',
          'cache-control': 'no-cache',
        },
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': e.toString()}),
        headers: {'content-type': 'application/json'},
      );
    }
  }

  /// POST /api/terminal/test (SSE stream)
  Future<Response> _test(Request request) async {
    try {
      final body = jsonDecode(await request.readAsString());
      final projectPath = body['projectPath'] as String?;
      final testFile = body['testFile'] as String?;
      final verbose = body['verbose'] as bool? ?? false;

      if (projectPath == null) {
        return Response.badRequest(
          body: jsonEncode({'error': 'projectPath required'}),
          headers: {'content-type': 'application/json'},
        );
      }

      final stream = _terminal.test(
        projectPath: projectPath,
        testFile: testFile,
        verbose: verbose,
      );

      return Response.ok(
        _sseStream(stream),
        headers: {
          'content-type': 'text/event-stream',
          'cache-control': 'no-cache',
        },
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': e.toString()}),
        headers: {'content-type': 'application/json'},
      );
    }
  }

  /// POST /api/terminal/command - Run arbitrary command (SSE stream)
  Future<Response> _runCommand(Request request) async {
    try {
      final body = jsonDecode(await request.readAsString());
      final command = body['command'] as String?;
      final args = (body['args'] as List<dynamic>?)?.cast<String>() ?? [];
      final workingDirectory = body['workingDirectory'] as String?;

      if (command == null || workingDirectory == null) {
        return Response.badRequest(
          body: jsonEncode({'error': 'command and workingDirectory required'}),
          headers: {'content-type': 'application/json'},
        );
      }

      final stream = _terminal.runCommand(
        command: command,
        args: args,
        workingDirectory: workingDirectory,
      );

      return Response.ok(
        _sseStream(stream),
        headers: {
          'content-type': 'text/event-stream',
          'cache-control': 'no-cache',
        },
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': e.toString()}),
        headers: {'content-type': 'application/json'},
      );
    }
  }

  /// GET /api/terminal/devices
  Future<Response> _getDevices(Request request) async {
    try {
      final devices = await _terminal.getDevices();
      return Response.ok(
        jsonEncode({'devices': devices.map((d) => d.toJson()).toList()}),
        headers: {'content-type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': e.toString()}),
        headers: {'content-type': 'application/json'},
      );
    }
  }

  /// GET /api/terminal/flutter-info
  Future<Response> _getFlutterInfo(Request request) async {
    try {
      final info = await _terminal.getFlutterInfo();
      if (info == null) {
        return Response.notFound(
          jsonEncode({'error': 'Flutter not found'}),
          headers: {'content-type': 'application/json'},
        );
      }
      return Response.ok(
        jsonEncode(info.toJson()),
        headers: {'content-type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': e.toString()}),
        headers: {'content-type': 'application/json'},
      );
    }
  }

  /// GET /api/terminal/status
  Future<Response> _getStatus(Request request) async {
    return Response.ok(
      jsonEncode({'isRunning': _terminal.isRunning}),
      headers: {'content-type': 'application/json'},
    );
  }

  /// Convert stream to SSE format
  Stream<List<int>> _sseStream(Stream<String> source) {
    return source.map((data) {
      final escaped = data.replaceAll('\n', '\ndata: ');
      return utf8.encode('data: $escaped\n\n');
    });
  }
}
