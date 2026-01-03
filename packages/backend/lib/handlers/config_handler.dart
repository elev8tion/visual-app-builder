import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../services/config_service_impl.dart';

/// REST handler for configuration operations
class ConfigHandler {
  final ConfigServiceImpl _config;

  ConfigHandler(this._config);

  Router get router {
    final router = Router();

    router.get('/', _getAllConfig);
    router.get('/openai', _getOpenAIConfig);
    router.put('/openai', _setOpenAIConfig);
    router.get('/<key>', _getValue);
    router.put('/<key>', _setValue);
    router.delete('/<key>', _removeValue);

    return router;
  }

  /// GET /api/config
  Future<Response> _getAllConfig(Request request) async {
    try {
      final openAIKey = await _config.getOpenAIKey();
      final openAIModel = await _config.getOpenAIModel();
      final organization = await _config.getOrganization();
      final defaultPath = await _config.getDefaultProjectPath();
      final isConfigured = await _config.isOpenAIConfigured();

      return Response.ok(
        jsonEncode({
          'openai': {
            'hasKey': openAIKey != null && openAIKey.isNotEmpty,
            'model': openAIModel,
            'isConfigured': isConfigured,
          },
          'organization': organization,
          'defaultProjectPath': defaultPath,
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

  /// GET /api/config/openai
  Future<Response> _getOpenAIConfig(Request request) async {
    try {
      final key = await _config.getOpenAIKey();
      final model = await _config.getOpenAIModel();
      final isConfigured = await _config.isOpenAIConfigured();

      return Response.ok(
        jsonEncode({
          'hasKey': key != null && key.isNotEmpty,
          'model': model ?? 'gpt-4o',
          'isConfigured': isConfigured,
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

  /// PUT /api/config/openai
  Future<Response> _setOpenAIConfig(Request request) async {
    try {
      final body = jsonDecode(await request.readAsString());
      final apiKey = body['apiKey'] as String?;
      final model = body['model'] as String?;

      if (apiKey != null) {
        await _config.setOpenAIKey(apiKey);
      }
      if (model != null) {
        await _config.setOpenAIModel(model);
      }

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

  /// GET /api/config/:key
  Future<Response> _getValue(Request request, String key) async {
    try {
      String? value;

      switch (key) {
        case 'organization':
          value = await _config.getOrganization();
          break;
        case 'defaultProjectPath':
          value = await _config.getDefaultProjectPath();
          break;
        default:
          value = await _config.getValue(key);
      }

      if (value == null) {
        return Response.notFound(
          jsonEncode({'error': 'Key not found'}),
          headers: {'content-type': 'application/json'},
        );
      }

      return Response.ok(
        jsonEncode({'key': key, 'value': value}),
        headers: {'content-type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': e.toString()}),
        headers: {'content-type': 'application/json'},
      );
    }
  }

  /// PUT /api/config/:key
  Future<Response> _setValue(Request request, String key) async {
    try {
      final body = jsonDecode(await request.readAsString());
      final value = body['value'] as String?;

      if (value == null) {
        return Response.badRequest(
          body: jsonEncode({'error': 'value required'}),
          headers: {'content-type': 'application/json'},
        );
      }

      switch (key) {
        case 'organization':
          await _config.setOrganization(value);
          break;
        case 'defaultProjectPath':
          await _config.setDefaultProjectPath(value);
          break;
        default:
          await _config.setValue(key, value);
      }

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

  /// DELETE /api/config/:key
  Future<Response> _removeValue(Request request, String key) async {
    try {
      await _config.removeValue(key);
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
