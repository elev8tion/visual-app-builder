import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';
import 'package:shelf_cors_headers/shelf_cors_headers.dart';

import 'handlers/files_handler.dart';
import 'handlers/terminal_handler.dart';
import 'handlers/git_handler.dart';
import 'handlers/project_handler.dart';
import 'handlers/config_handler.dart';
import 'handlers/upload_handler.dart';
import 'handlers/preview_handler.dart';
import 'websocket/terminal_websocket.dart';
import 'services/terminal_service_impl.dart';
import 'services/project_manager_impl.dart';
import 'services/config_service_impl.dart';
import 'services/git_service_impl.dart';

/// Main server class for Visual App Builder backend
class VisualAppBuilderServer {
  final int port;
  final String? staticFilesPath;

  HttpServer? _server;
  late TerminalServiceImpl _terminalService;
  late ProjectManagerImpl _projectManager;
  late ConfigServiceImpl _configService;
  late GitServiceImpl _gitService;
  late TerminalWebSocket _terminalWebSocket;
  late UploadHandler _uploadHandler;
  late PreviewHandler _previewHandler;

  VisualAppBuilderServer({
    this.port = 8080,
    this.staticFilesPath,
  });

  Future<void> start() async {
    // Initialize services
    _terminalService = TerminalServiceImpl();
    _configService = ConfigServiceImpl();
    _projectManager = ProjectManagerImpl(_configService);
    _gitService = GitServiceImpl();
    _terminalWebSocket = TerminalWebSocket(_terminalService);

    // Create router
    final router = Router();

    // Mount API handlers
    final filesHandler = FilesHandler(_projectManager);
    final terminalHandler = TerminalHandler(_terminalService);
    final gitHandler = GitHandler(_gitService);
    final projectHandler = ProjectHandler(_projectManager);
    final configHandler = ConfigHandler(_configService);
    _uploadHandler = UploadHandler(_projectManager);
    _previewHandler = PreviewHandler();

    // API routes
    router.mount('/api/files', filesHandler.router.call);
    router.mount('/api/terminal', terminalHandler.router.call);
    router.mount('/api/git', gitHandler.router.call);
    router.mount('/api/projects', projectHandler.router.call);
    router.mount('/api/config', configHandler.router.call);
    router.mount('/api/upload', _uploadHandler.router.call);
    router.mount('/api/preview', _previewHandler.router.call);

    // WebSocket route for terminal streaming
    router.get('/ws/terminal', _terminalWebSocket.handler);

    // Health check
    router.get('/health', (Request request) {
      return Response.ok('{"status": "ok"}', headers: {
        'content-type': 'application/json',
      });
    });

    // Static file handler (if configured)
    Handler handler = router.call;

    // Add CORS middleware
    handler = const Pipeline()
        .addMiddleware(corsHeaders(headers: {
          ACCESS_CONTROL_ALLOW_ORIGIN: '*',
          ACCESS_CONTROL_ALLOW_METHODS: 'GET, POST, PUT, DELETE, OPTIONS',
          ACCESS_CONTROL_ALLOW_HEADERS: 'Origin, Content-Type, Accept, Authorization',
        }))
        .addMiddleware(_logRequests())
        .addHandler(handler);

    // Add static file handler if path provided
    if (staticFilesPath != null) {
      handler = _staticFilesHandler(staticFilesPath!, handler);
    }

    // Start server
    _server = await shelf_io.serve(handler, InternetAddress.anyIPv4, port);
    _server!.autoCompress = true;
  }

  Future<void> stop() async {
    _terminalService.dispose();
    _terminalWebSocket.dispose();
    _previewHandler.dispose();
    await _server?.close(force: true);
  }

  /// Middleware to log requests
  Middleware _logRequests() {
    return (Handler handler) {
      return (Request request) async {
        final sw = Stopwatch()..start();
        final response = await handler(request);
        sw.stop();
        print('[${DateTime.now().toIso8601String()}] '
            '${request.method} ${request.requestedUri.path} '
            '${response.statusCode} (${sw.elapsedMilliseconds}ms)');
        return response;
      };
    };
  }

  /// Handler to serve static files with SPA fallback
  Handler _staticFilesHandler(String path, Handler apiHandler) {
    return (Request request) async {
      // Try API handler first
      if (request.url.path.startsWith('api/') ||
          request.url.path.startsWith('ws/') ||
          request.url.path == 'health') {
        return apiHandler(request);
      }

      // Try static file
      final filePath = '${path}/${request.url.path}';
      final file = File(filePath);

      if (await file.exists()) {
        final extension = filePath.split('.').last.toLowerCase();
        final contentType = _getContentType(extension);
        final bytes = await file.readAsBytes();
        return Response.ok(bytes, headers: {'content-type': contentType});
      }

      // Fall back to index.html for SPA routing
      final indexFile = File('$path/index.html');
      if (await indexFile.exists()) {
        final bytes = await indexFile.readAsBytes();
        return Response.ok(bytes, headers: {'content-type': 'text/html'});
      }

      // Try API handler as fallback
      return apiHandler(request);
    };
  }

  String _getContentType(String extension) {
    switch (extension) {
      case 'html':
        return 'text/html';
      case 'css':
        return 'text/css';
      case 'js':
        return 'application/javascript';
      case 'json':
        return 'application/json';
      case 'png':
        return 'image/png';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'svg':
        return 'image/svg+xml';
      case 'ico':
        return 'image/x-icon';
      case 'woff':
        return 'font/woff';
      case 'woff2':
        return 'font/woff2';
      case 'ttf':
        return 'font/ttf';
      default:
        return 'application/octet-stream';
    }
  }
}
