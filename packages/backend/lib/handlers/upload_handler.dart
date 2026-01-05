import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:path/path.dart' as path;

import '../services/project_manager_impl.dart';

/// REST handler for project upload operations (zip files)
class UploadHandler {
  final ProjectManagerImpl _projectManager;
  final String _uploadDirectory;

  UploadHandler(this._projectManager, {String? uploadDirectory})
      : _uploadDirectory = uploadDirectory ??
            path.join(Directory.current.path, 'uploads');

  Router get router {
    final router = Router();

    router.post('/zip', _uploadZip);
    router.get('/status/<uploadId>', _getUploadStatus);

    return router;
  }

  /// POST /api/upload/zip
  /// Accepts multipart form data with a zip file
  Future<Response> _uploadZip(Request request) async {
    try {
      // Ensure upload directory exists
      final uploadDir = Directory(_uploadDirectory);
      if (!await uploadDir.exists()) {
        await uploadDir.create(recursive: true);
      }

      // Read the request body as bytes
      final bytes = await request.read().expand((chunk) => chunk).toList();

      // Parse content type for boundary
      final contentType = request.headers['content-type'];
      if (contentType == null || !contentType.contains('multipart/form-data')) {
        return Response.badRequest(
          body: jsonEncode({'error': 'Content-Type must be multipart/form-data'}),
          headers: {'content-type': 'application/json'},
        );
      }

      // Extract boundary from content-type
      final boundaryMatch = RegExp(r'boundary=(.+)').firstMatch(contentType);
      if (boundaryMatch == null) {
        return Response.badRequest(
          body: jsonEncode({'error': 'Missing boundary in Content-Type'}),
          headers: {'content-type': 'application/json'},
        );
      }

      // Simple multipart parser - find zip file data
      final boundary = '--${boundaryMatch.group(1)}';
      final bodyStr = utf8.decode(bytes, allowMalformed: true);

      // Find zip file in multipart data
      final parts = bodyStr.split(boundary);
      List<int>? zipBytes;
      String? projectName;

      for (final part in parts) {
        if (part.contains('Content-Disposition') && part.contains('filename=')) {
          // Extract filename
          final filenameMatch = RegExp(r'filename="([^"]+)"').firstMatch(part);
          if (filenameMatch != null) {
            final filename = filenameMatch.group(1)!;
            if (filename.endsWith('.zip')) {
              projectName = path.basenameWithoutExtension(filename);

              // Find the binary data after headers
              final headerEnd = part.indexOf('\r\n\r\n');
              if (headerEnd != -1) {
                final dataStart = bodyStr.indexOf(part) + headerEnd + 4;
                final dataEnd = bytes.length - boundary.length - 6; // Account for trailing boundary
                zipBytes = bytes.sublist(dataStart, dataEnd);
              }
            }
          }
        } else if (part.contains('name="projectName"')) {
          // Extract project name from form field
          final valueStart = part.indexOf('\r\n\r\n');
          if (valueStart != -1) {
            projectName = part.substring(valueStart + 4).trim().split('\r\n').first;
          }
        }
      }

      if (zipBytes == null || zipBytes.isEmpty) {
        return Response.badRequest(
          body: jsonEncode({'error': 'No zip file found in upload'}),
          headers: {'content-type': 'application/json'},
        );
      }

      projectName ??= 'uploaded_project_${DateTime.now().millisecondsSinceEpoch}';

      // Create project directory
      final projectDir = Directory(path.join(_uploadDirectory, projectName));
      if (await projectDir.exists()) {
        // Add timestamp to avoid conflicts
        projectName = '${projectName}_${DateTime.now().millisecondsSinceEpoch}';
      }

      final finalProjectDir = Directory(path.join(_uploadDirectory, projectName));
      await finalProjectDir.create(recursive: true);

      // Decode and extract zip
      final archive = ZipDecoder().decodeBytes(zipBytes);

      for (final file in archive) {
        final filename = file.name;
        final filePath = path.join(finalProjectDir.path, filename);

        if (file.isFile) {
          final outputFile = File(filePath);
          await outputFile.create(recursive: true);
          await outputFile.writeAsBytes(file.content as List<int>);
        } else {
          await Directory(filePath).create(recursive: true);
        }
      }

      // Open the uploaded project
      final project = await _projectManager.openProject(finalProjectDir.path);

      return Response.ok(
        jsonEncode({
          'success': true,
          'projectPath': finalProjectDir.path,
          'projectName': projectName,
          'project': project?.toJson(),
        }),
        headers: {'content-type': 'application/json'},
      );
    } catch (e, stack) {
      print('Upload error: $e\n$stack');
      return Response.internalServerError(
        body: jsonEncode({'error': e.toString()}),
        headers: {'content-type': 'application/json'},
      );
    }
  }

  /// GET /api/upload/status/<uploadId>
  Future<Response> _getUploadStatus(Request request, String uploadId) async {
    // For now, uploads are synchronous
    // This endpoint can be extended for async uploads with progress tracking
    return Response.ok(
      jsonEncode({
        'uploadId': uploadId,
        'status': 'completed',
      }),
      headers: {'content-type': 'application/json'},
    );
  }
}
