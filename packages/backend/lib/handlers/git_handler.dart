import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../services/git_service_impl.dart';

/// REST handler for Git operations
class GitHandler {
  final GitServiceImpl _git;

  GitHandler(this._git);

  Router get router {
    final router = Router();

    router.get('/status', _getStatus);
    router.post('/stage', _stageFiles);
    router.post('/stage-all', _stageAll);
    router.post('/unstage', _unstageFiles);
    router.post('/commit', _commit);
    router.post('/push', _push);
    router.post('/pull', _pull);
    router.get('/history', _getHistory);
    router.post('/init', _init);
    router.get('/branch', _getCurrentBranch);
    router.get('/branches', _getBranches);
    router.post('/checkout', _checkout);
    router.post('/create-branch', _createBranch);
    router.post('/discard', _discardChanges);

    return router;
  }

  /// GET /api/git/status?path=...
  Future<Response> _getStatus(Request request) async {
    try {
      final projectPath = request.url.queryParameters['path'];
      if (projectPath == null) {
        return Response.badRequest(
          body: jsonEncode({'error': 'path parameter required'}),
          headers: {'content-type': 'application/json'},
        );
      }

      final status = await _git.getStatus(projectPath);
      return Response.ok(
        jsonEncode(status.toJson()),
        headers: {'content-type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': e.toString()}),
        headers: {'content-type': 'application/json'},
      );
    }
  }

  /// POST /api/git/stage
  Future<Response> _stageFiles(Request request) async {
    try {
      final body = jsonDecode(await request.readAsString());
      final projectPath = body['projectPath'] as String?;
      final files = (body['files'] as List<dynamic>?)?.cast<String>();

      if (projectPath == null || files == null) {
        return Response.badRequest(
          body: jsonEncode({'error': 'projectPath and files required'}),
          headers: {'content-type': 'application/json'},
        );
      }

      await _git.stageFiles(projectPath, files);
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

  /// POST /api/git/stage-all
  Future<Response> _stageAll(Request request) async {
    try {
      final body = jsonDecode(await request.readAsString());
      final projectPath = body['projectPath'] as String?;

      if (projectPath == null) {
        return Response.badRequest(
          body: jsonEncode({'error': 'projectPath required'}),
          headers: {'content-type': 'application/json'},
        );
      }

      await _git.stageAll(projectPath);
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

  /// POST /api/git/unstage
  Future<Response> _unstageFiles(Request request) async {
    try {
      final body = jsonDecode(await request.readAsString());
      final projectPath = body['projectPath'] as String?;
      final files = (body['files'] as List<dynamic>?)?.cast<String>();

      if (projectPath == null || files == null) {
        return Response.badRequest(
          body: jsonEncode({'error': 'projectPath and files required'}),
          headers: {'content-type': 'application/json'},
        );
      }

      await _git.unstageFiles(projectPath, files);
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

  /// POST /api/git/commit
  Future<Response> _commit(Request request) async {
    try {
      final body = jsonDecode(await request.readAsString());
      final projectPath = body['projectPath'] as String?;
      final message = body['message'] as String?;

      if (projectPath == null || message == null) {
        return Response.badRequest(
          body: jsonEncode({'error': 'projectPath and message required'}),
          headers: {'content-type': 'application/json'},
        );
      }

      final commit = await _git.commit(projectPath, message);
      return Response.ok(
        jsonEncode(commit.toJson()),
        headers: {'content-type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': e.toString()}),
        headers: {'content-type': 'application/json'},
      );
    }
  }

  /// POST /api/git/push
  Future<Response> _push(Request request) async {
    try {
      final body = jsonDecode(await request.readAsString());
      final projectPath = body['projectPath'] as String?;
      final remote = body['remote'] as String?;
      final branch = body['branch'] as String?;

      if (projectPath == null) {
        return Response.badRequest(
          body: jsonEncode({'error': 'projectPath required'}),
          headers: {'content-type': 'application/json'},
        );
      }

      await _git.push(projectPath, remote: remote, branch: branch);
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

  /// POST /api/git/pull
  Future<Response> _pull(Request request) async {
    try {
      final body = jsonDecode(await request.readAsString());
      final projectPath = body['projectPath'] as String?;
      final remote = body['remote'] as String?;
      final branch = body['branch'] as String?;

      if (projectPath == null) {
        return Response.badRequest(
          body: jsonEncode({'error': 'projectPath required'}),
          headers: {'content-type': 'application/json'},
        );
      }

      await _git.pull(projectPath, remote: remote, branch: branch);
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

  /// GET /api/git/history?path=...&limit=50
  Future<Response> _getHistory(Request request) async {
    try {
      final projectPath = request.url.queryParameters['path'];
      final limitStr = request.url.queryParameters['limit'];
      final limit = int.tryParse(limitStr ?? '50') ?? 50;

      if (projectPath == null) {
        return Response.badRequest(
          body: jsonEncode({'error': 'path parameter required'}),
          headers: {'content-type': 'application/json'},
        );
      }

      final history = await _git.getCommitHistory(projectPath, limit: limit);
      return Response.ok(
        jsonEncode({'commits': history.map((c) => c.toJson()).toList()}),
        headers: {'content-type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': e.toString()}),
        headers: {'content-type': 'application/json'},
      );
    }
  }

  /// POST /api/git/init
  Future<Response> _init(Request request) async {
    try {
      final body = jsonDecode(await request.readAsString());
      final projectPath = body['projectPath'] as String?;

      if (projectPath == null) {
        return Response.badRequest(
          body: jsonEncode({'error': 'projectPath required'}),
          headers: {'content-type': 'application/json'},
        );
      }

      await _git.init(projectPath);
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

  /// GET /api/git/branch?path=...
  Future<Response> _getCurrentBranch(Request request) async {
    try {
      final projectPath = request.url.queryParameters['path'];
      if (projectPath == null) {
        return Response.badRequest(
          body: jsonEncode({'error': 'path parameter required'}),
          headers: {'content-type': 'application/json'},
        );
      }

      final branch = await _git.getCurrentBranch(projectPath);
      return Response.ok(
        jsonEncode({'branch': branch}),
        headers: {'content-type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': e.toString()}),
        headers: {'content-type': 'application/json'},
      );
    }
  }

  /// GET /api/git/branches?path=...
  Future<Response> _getBranches(Request request) async {
    try {
      final projectPath = request.url.queryParameters['path'];
      if (projectPath == null) {
        return Response.badRequest(
          body: jsonEncode({'error': 'path parameter required'}),
          headers: {'content-type': 'application/json'},
        );
      }

      final branches = await _git.getBranches(projectPath);
      return Response.ok(
        jsonEncode({'branches': branches}),
        headers: {'content-type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': e.toString()}),
        headers: {'content-type': 'application/json'},
      );
    }
  }

  /// POST /api/git/checkout
  Future<Response> _checkout(Request request) async {
    try {
      final body = jsonDecode(await request.readAsString());
      final projectPath = body['projectPath'] as String?;
      final branch = body['branch'] as String?;

      if (projectPath == null || branch == null) {
        return Response.badRequest(
          body: jsonEncode({'error': 'projectPath and branch required'}),
          headers: {'content-type': 'application/json'},
        );
      }

      await _git.checkout(projectPath, branch);
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

  /// POST /api/git/create-branch
  Future<Response> _createBranch(Request request) async {
    try {
      final body = jsonDecode(await request.readAsString());
      final projectPath = body['projectPath'] as String?;
      final branchName = body['branchName'] as String?;

      if (projectPath == null || branchName == null) {
        return Response.badRequest(
          body: jsonEncode({'error': 'projectPath and branchName required'}),
          headers: {'content-type': 'application/json'},
        );
      }

      await _git.createBranch(projectPath, branchName);
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

  /// POST /api/git/discard
  Future<Response> _discardChanges(Request request) async {
    try {
      final body = jsonDecode(await request.readAsString());
      final projectPath = body['projectPath'] as String?;
      final filePath = body['filePath'] as String?;

      if (projectPath == null || filePath == null) {
        return Response.badRequest(
          body: jsonEncode({'error': 'projectPath and filePath required'}),
          headers: {'content-type': 'application/json'},
        );
      }

      await _git.discardChanges(projectPath, filePath);
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
}
