import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';

/// API client for communicating with the Visual App Builder backend server.
/// Handles HTTP requests, WebSocket connections, and SSE streams.
class ApiClient {
  final String baseUrl;
  final http.Client _httpClient;
  WebSocketChannel? _terminalWebSocket;
  StreamController<String>? _terminalStreamController;

  ApiClient({
    this.baseUrl = 'http://localhost:8080',
    http.Client? httpClient,
  }) : _httpClient = httpClient ?? http.Client();

  // ============================================
  // HTTP Helper Methods
  // ============================================

  Future<Map<String, dynamic>> get(String path, {Map<String, String>? queryParams}) async {
    final uri = Uri.parse('$baseUrl$path').replace(queryParameters: queryParams);
    final response = await _httpClient.get(uri, headers: _headers);
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> post(String path, {Map<String, dynamic>? body}) async {
    final uri = Uri.parse('$baseUrl$path');
    final response = await _httpClient.post(
      uri,
      headers: _headers,
      body: body != null ? jsonEncode(body) : null,
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> put(String path, {Map<String, dynamic>? body}) async {
    final uri = Uri.parse('$baseUrl$path');
    final response = await _httpClient.put(
      uri,
      headers: _headers,
      body: body != null ? jsonEncode(body) : null,
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> delete(String path) async {
    final uri = Uri.parse('$baseUrl$path');
    final response = await _httpClient.delete(uri, headers: _headers);
    return _handleResponse(response);
  }

  /// Make a POST request that returns an SSE stream
  Stream<String> postStream(String path, {Map<String, dynamic>? body}) async* {
    final uri = Uri.parse('$baseUrl$path');
    final request = http.Request('POST', uri);
    request.headers.addAll(_headers);
    if (body != null) {
      request.body = jsonEncode(body);
    }

    final streamedResponse = await _httpClient.send(request);

    if (streamedResponse.statusCode != 200) {
      throw ApiException('Request failed with status: ${streamedResponse.statusCode}');
    }

    await for (final chunk in streamedResponse.stream.transform(utf8.decoder)) {
      // Parse SSE format: "data: <content>\n\n"
      for (final line in chunk.split('\n')) {
        if (line.startsWith('data: ')) {
          yield line.substring(6);
        }
      }
    }
  }

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  Map<String, dynamic> _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return {};
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      final error = response.body.isNotEmpty
          ? (jsonDecode(response.body)['error'] ?? 'Unknown error')
          : 'Request failed with status ${response.statusCode}';
      throw ApiException(error.toString());
    }
  }

  // ============================================
  // Project APIs
  // ============================================

  /// Create a new Flutter project (returns SSE stream of progress)
  Stream<String> createProject({
    required String name,
    required String outputPath,
    String? template,
    String? stateManagement,
    String? organization,
    List<String>? platforms,
  }) {
    return postStream('/api/projects/create', body: {
      'name': name,
      'outputPath': outputPath,
      if (template != null) 'template': template,
      if (stateManagement != null) 'stateManagement': stateManagement,
      if (organization != null) 'organization': organization,
      if (platforms != null) 'platforms': platforms,
    });
  }

  /// Open an existing project
  Future<Map<String, dynamic>> openProject(String path) {
    return post('/api/projects/open', body: {'path': path});
  }

  /// Get recent projects
  Future<List<Map<String, dynamic>>> getRecentProjects() async {
    final response = await get('/api/projects/recent');
    return (response['projects'] as List).cast<Map<String, dynamic>>();
  }

  /// Get current project
  Future<Map<String, dynamic>?> getCurrentProject() async {
    try {
      return await get('/api/projects/current');
    } catch (e) {
      return null;
    }
  }

  /// Close current project
  Future<void> closeProject() async {
    await post('/api/projects/close');
  }

  /// Get default project directory
  Future<String> getDefaultDirectory() async {
    final response = await get('/api/projects/default-directory');
    return response['directory'] as String;
  }

  // ============================================
  // File APIs
  // ============================================

  /// List files in a directory
  Future<List<Map<String, dynamic>>> listFiles(String path) async {
    final response = await get('/api/files', queryParams: {'path': path});
    return (response['files'] as List).cast<Map<String, dynamic>>();
  }

  /// Read file content
  Future<String?> readFile(String path) async {
    final response = await get('/api/files/content', queryParams: {'path': path});
    return response['content'] as String?;
  }

  /// Write file content
  Future<void> writeFile(String path, String content) async {
    await put('/api/files/content', body: {
      'path': path,
      'content': content,
    });
  }

  /// Create a new file or directory
  Future<void> createFile(String name, {String parentPath = '', bool isDirectory = false}) async {
    await post('/api/files', body: {
      'name': name,
      'parentPath': parentPath,
      'isDirectory': isDirectory,
    });
  }

  /// Delete a file or directory
  Future<void> deleteFile(String path) async {
    await delete('/api/files?path=${Uri.encodeComponent(path)}');
  }

  // ============================================
  // Terminal APIs
  // ============================================

  /// Run Flutter project (returns SSE stream)
  Stream<String> runProject({
    required String projectPath,
    String? device,
    bool verbose = false,
  }) {
    return postStream('/api/terminal/run', body: {
      'projectPath': projectPath,
      if (device != null) 'device': device,
      'verbose': verbose,
    });
  }

  /// Trigger hot reload
  Future<void> hotReload() async {
    await post('/api/terminal/hot-reload');
  }

  /// Trigger hot restart
  Future<void> hotRestart() async {
    await post('/api/terminal/hot-restart');
  }

  /// Stop running process
  Future<void> stopTerminal() async {
    await post('/api/terminal/stop');
  }

  /// Build project (returns SSE stream)
  Stream<String> buildProject({
    required String projectPath,
    required String platform,
    bool release = false,
    bool verbose = false,
  }) {
    return postStream('/api/terminal/build', body: {
      'projectPath': projectPath,
      'platform': platform,
      'release': release,
      'verbose': verbose,
    });
  }

  /// Run pub get (returns SSE stream)
  Stream<String> pubGet(String projectPath) {
    return postStream('/api/terminal/pub-get', body: {
      'projectPath': projectPath,
    });
  }

  /// Run flutter clean (returns SSE stream)
  Stream<String> clean(String projectPath) {
    return postStream('/api/terminal/clean', body: {
      'projectPath': projectPath,
    });
  }

  /// Run flutter analyze (returns SSE stream)
  Stream<String> analyze(String projectPath) {
    return postStream('/api/terminal/analyze', body: {
      'projectPath': projectPath,
    });
  }

  /// Run flutter test (returns SSE stream)
  Stream<String> test(String projectPath, {String? testFile, bool verbose = false}) {
    return postStream('/api/terminal/test', body: {
      'projectPath': projectPath,
      if (testFile != null) 'testFile': testFile,
      'verbose': verbose,
    });
  }

  /// Run arbitrary command (returns SSE stream)
  Stream<String> runCommand({
    required String command,
    List<String> args = const [],
    required String workingDirectory,
  }) {
    return postStream('/api/terminal/command', body: {
      'command': command,
      'args': args,
      'workingDirectory': workingDirectory,
    });
  }

  /// Get available Flutter devices
  Future<List<Map<String, dynamic>>> getDevices() async {
    final response = await get('/api/terminal/devices');
    return (response['devices'] as List).cast<Map<String, dynamic>>();
  }

  /// Get Flutter SDK info
  Future<Map<String, dynamic>?> getFlutterInfo() async {
    try {
      return await get('/api/terminal/flutter-info');
    } catch (e) {
      return null;
    }
  }

  /// Get terminal status
  Future<bool> getTerminalStatus() async {
    final response = await get('/api/terminal/status');
    return response['isRunning'] as bool;
  }

  // ============================================
  // WebSocket Terminal Stream
  // ============================================

  /// Connect to terminal WebSocket for real-time output
  Stream<String> connectTerminalWebSocket() {
    _terminalStreamController?.close();
    _terminalStreamController = StreamController<String>.broadcast();

    final wsUrl = baseUrl.replaceFirst('http', 'ws');
    _terminalWebSocket = WebSocketChannel.connect(Uri.parse('$wsUrl/ws/terminal'));

    _terminalWebSocket!.stream.listen(
      (data) {
        _terminalStreamController?.add(data.toString());
      },
      onError: (error) {
        _terminalStreamController?.addError(error);
      },
      onDone: () {
        _terminalStreamController?.close();
      },
    );

    return _terminalStreamController!.stream;
  }

  /// Send command to terminal WebSocket
  void sendTerminalCommand(String command) {
    _terminalWebSocket?.sink.add(command);
  }

  /// Disconnect terminal WebSocket
  void disconnectTerminalWebSocket() {
    _terminalWebSocket?.sink.close();
    _terminalStreamController?.close();
    _terminalWebSocket = null;
    _terminalStreamController = null;
  }

  // ============================================
  // Git APIs
  // ============================================

  /// Get git status
  Future<Map<String, dynamic>> getGitStatus(String projectPath) async {
    return get('/api/git/status', queryParams: {'path': projectPath});
  }

  /// Stage files
  Future<void> stageFiles(String projectPath, List<String> files) async {
    await post('/api/git/stage', body: {
      'projectPath': projectPath,
      'files': files,
    });
  }

  /// Stage all files
  Future<void> stageAll(String projectPath) async {
    await post('/api/git/stage-all', body: {
      'projectPath': projectPath,
    });
  }

  /// Unstage files
  Future<void> unstageFiles(String projectPath, List<String> files) async {
    await post('/api/git/unstage', body: {
      'projectPath': projectPath,
      'files': files,
    });
  }

  /// Create commit
  Future<Map<String, dynamic>> commit(String projectPath, String message) async {
    return post('/api/git/commit', body: {
      'projectPath': projectPath,
      'message': message,
    });
  }

  /// Push to remote
  Future<void> push(String projectPath, {String? remote, String? branch}) async {
    await post('/api/git/push', body: {
      'projectPath': projectPath,
      if (remote != null) 'remote': remote,
      if (branch != null) 'branch': branch,
    });
  }

  /// Pull from remote
  Future<void> pull(String projectPath, {String? remote, String? branch}) async {
    await post('/api/git/pull', body: {
      'projectPath': projectPath,
      if (remote != null) 'remote': remote,
      if (branch != null) 'branch': branch,
    });
  }

  /// Get commit history
  Future<List<Map<String, dynamic>>> getCommitHistory(String projectPath, {int limit = 50}) async {
    final response = await get('/api/git/history', queryParams: {
      'path': projectPath,
      'limit': limit.toString(),
    });
    return (response['commits'] as List).cast<Map<String, dynamic>>();
  }

  /// Initialize git repository
  Future<void> gitInit(String projectPath) async {
    await post('/api/git/init', body: {
      'projectPath': projectPath,
    });
  }

  /// Get current branch
  Future<String> getCurrentBranch(String projectPath) async {
    final response = await get('/api/git/branch', queryParams: {'path': projectPath});
    return response['branch'] as String;
  }

  /// Get all branches
  Future<List<String>> getBranches(String projectPath) async {
    final response = await get('/api/git/branches', queryParams: {'path': projectPath});
    return (response['branches'] as List).cast<String>();
  }

  /// Checkout branch
  Future<void> checkout(String projectPath, String branch) async {
    await post('/api/git/checkout', body: {
      'projectPath': projectPath,
      'branch': branch,
    });
  }

  /// Create new branch
  Future<void> createBranch(String projectPath, String branchName) async {
    await post('/api/git/create-branch', body: {
      'projectPath': projectPath,
      'branchName': branchName,
    });
  }

  /// Discard changes in a file
  Future<void> discardChanges(String projectPath, String filePath) async {
    await post('/api/git/discard', body: {
      'projectPath': projectPath,
      'filePath': filePath,
    });
  }

  // ============================================
  // Config APIs
  // ============================================

  /// Get all config
  Future<Map<String, dynamic>> getAllConfig() async {
    return get('/api/config');
  }

  /// Get OpenAI config
  Future<Map<String, dynamic>> getOpenAIConfig() async {
    return get('/api/config/openai');
  }

  /// Set OpenAI config
  Future<void> setOpenAIConfig({String? apiKey, String? model}) async {
    await put('/api/config/openai', body: {
      if (apiKey != null) 'apiKey': apiKey,
      if (model != null) 'model': model,
    });
  }

  /// Get config value
  Future<String?> getConfigValue(String key) async {
    try {
      final response = await get('/api/config/$key');
      return response['value'] as String?;
    } catch (e) {
      return null;
    }
  }

  /// Set config value
  Future<void> setConfigValue(String key, String value) async {
    await put('/api/config/$key', body: {'value': value});
  }

  /// Remove config value
  Future<void> removeConfigValue(String key) async {
    await delete('/api/config/$key');
  }

  // ============================================
  // Health Check
  // ============================================

  /// Check if backend server is running
  Future<bool> isServerRunning() async {
    try {
      final uri = Uri.parse('$baseUrl/health');
      final response = await _httpClient.get(uri).timeout(
        const Duration(seconds: 5),
        onTimeout: () => http.Response('', 504),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Dispose resources
  void dispose() {
    disconnectTerminalWebSocket();
    _httpClient.close();
  }
}

/// Exception thrown when an API request fails
class ApiException implements Exception {
  final String message;

  ApiException(this.message);

  @override
  String toString() => 'ApiException: $message';
}
