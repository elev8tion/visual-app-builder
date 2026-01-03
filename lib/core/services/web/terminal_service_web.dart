import 'dart:async';

import 'package:visual_app_builder_shared/visual_app_builder_shared.dart';

import '../api_client.dart';

/// Web implementation of terminal service using API client
class TerminalServiceWeb implements ITerminalService {
  final ApiClient _apiClient;
  final StreamController<String> _outputController = StreamController<String>.broadcast();
  bool _isRunning = false;
  StreamSubscription<String>? _runSubscription;

  TerminalServiceWeb(this._apiClient);

  @override
  bool get isRunning => _isRunning;

  @override
  Stream<String> get outputStream => _outputController.stream;

  @override
  Stream<String> runProject({
    required String projectPath,
    String? device,
    bool verbose = false,
  }) async* {
    _isRunning = true;

    try {
      // Connect WebSocket for real-time output
      final wsStream = _apiClient.connectTerminalWebSocket();
      _runSubscription = wsStream.listen(
        (data) => _outputController.add(data),
        onError: (e) => _outputController.addError(e),
      );

      // Start the project
      await for (final line in _apiClient.runProject(
        projectPath: projectPath,
        device: device,
        verbose: verbose,
      )) {
        yield line;
        _outputController.add(line);
      }
    } catch (e) {
      yield 'Error: $e\n';
      _outputController.addError(e);
    } finally {
      _isRunning = false;
    }
  }

  @override
  Future<void> hotReload() async {
    try {
      await _apiClient.hotReload();
      _outputController.add('Performing hot reload...\n');
    } catch (e) {
      _outputController.addError(e);
    }
  }

  @override
  Future<void> hotRestart() async {
    try {
      await _apiClient.hotRestart();
      _outputController.add('Performing hot restart...\n');
    } catch (e) {
      _outputController.addError(e);
    }
  }

  @override
  Future<void> stop() async {
    try {
      await _apiClient.stopTerminal();
      _runSubscription?.cancel();
      _apiClient.disconnectTerminalWebSocket();
      _isRunning = false;
      _outputController.add('Process stopped.\n');
    } catch (e) {
      _outputController.addError(e);
    }
  }

  @override
  Stream<String> buildProject({
    required String projectPath,
    required String platform,
    bool release = false,
    bool verbose = false,
  }) async* {
    try {
      await for (final line in _apiClient.buildProject(
        projectPath: projectPath,
        platform: platform,
        release: release,
        verbose: verbose,
      )) {
        yield line;
        _outputController.add(line);
      }
    } catch (e) {
      yield 'Error: $e\n';
      _outputController.addError(e);
    }
  }

  @override
  Stream<String> pubGet({required String projectPath}) async* {
    try {
      await for (final line in _apiClient.pubGet(projectPath)) {
        yield line;
        _outputController.add(line);
      }
    } catch (e) {
      yield 'Error: $e\n';
      _outputController.addError(e);
    }
  }

  @override
  Stream<String> clean({required String projectPath}) async* {
    try {
      await for (final line in _apiClient.clean(projectPath)) {
        yield line;
        _outputController.add(line);
      }
    } catch (e) {
      yield 'Error: $e\n';
      _outputController.addError(e);
    }
  }

  @override
  Stream<String> createProject({
    required String name,
    required String outputPath,
    String? organization,
    List<String>? platforms,
    String? template,
  }) async* {
    try {
      await for (final line in _apiClient.createProject(
        name: name,
        outputPath: outputPath,
        organization: organization,
        platforms: platforms,
        template: template,
      )) {
        yield line;
        _outputController.add(line);
      }
    } catch (e) {
      yield 'Error: $e\n';
      _outputController.addError(e);
    }
  }

  @override
  Stream<String> analyze({required String projectPath}) async* {
    try {
      await for (final line in _apiClient.analyze(projectPath)) {
        yield line;
        _outputController.add(line);
      }
    } catch (e) {
      yield 'Error: $e\n';
      _outputController.addError(e);
    }
  }

  @override
  Stream<String> test({
    required String projectPath,
    String? testFile,
    bool verbose = false,
  }) async* {
    try {
      await for (final line in _apiClient.test(
        projectPath,
        testFile: testFile,
        verbose: verbose,
      )) {
        yield line;
        _outputController.add(line);
      }
    } catch (e) {
      yield 'Error: $e\n';
      _outputController.addError(e);
    }
  }

  @override
  Stream<String> runCommand({
    required String command,
    List<String> args = const [],
    required String workingDirectory,
  }) async* {
    try {
      await for (final line in _apiClient.runCommand(
        command: command,
        args: args,
        workingDirectory: workingDirectory,
      )) {
        yield line;
        _outputController.add(line);
      }
    } catch (e) {
      yield 'Error: $e\n';
      _outputController.addError(e);
    }
  }

  @override
  Future<List<FlutterDevice>> getDevices() async {
    try {
      final devices = await _apiClient.getDevices();
      return devices.map((d) => FlutterDevice.fromJson(d)).toList();
    } catch (e) {
      return [];
    }
  }

  @override
  Future<FlutterInfo?> getFlutterInfo() async {
    try {
      final info = await _apiClient.getFlutterInfo();
      if (info != null) {
        return FlutterInfo.fromJson(info);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  @override
  void dispose() {
    _runSubscription?.cancel();
    _outputController.close();
    _apiClient.disconnectTerminalWebSocket();
  }
}
