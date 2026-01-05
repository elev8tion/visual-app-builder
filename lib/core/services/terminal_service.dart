import 'dart:async';
import 'dart:convert';
import 'dart:io';

/// Terminal Service
///
/// Executes Flutter commands with real-time output streaming.
/// Supports running apps, hot reload, build, and other flutter commands.
class TerminalService {
  static final TerminalService _instance = TerminalService._internal();
  static TerminalService get instance => _instance;

  TerminalService._internal();

  Process? _runningProcess;
  final StreamController<String> _outputController = StreamController<String>.broadcast();

  /// Stream of all terminal output
  Stream<String> get outputStream => _outputController.stream;

  /// Check if a process is currently running
  bool get isRunning => _runningProcess != null;

  /// Run a Flutter project
  Stream<String> runProject({
    required String projectPath,
    String? device,
    bool verbose = false,
  }) async* {
    if (_runningProcess != null) {
      yield 'Error: A process is already running. Stop it first.\n';
      return;
    }

    final args = ['run'];
    if (device != null) {
      args.addAll(['-d', device]);
    }
    if (verbose) {
      args.add('-v');
    }

    yield '> flutter ${args.join(' ')}\n';
    yield 'Working directory: $projectPath\n\n';

    yield* _startProcess('flutter', args, workingDirectory: projectPath);
  }

  /// Hot reload the running app
  Future<void> hotReload() async {
    if (_runningProcess != null) {
      _runningProcess!.stdin.writeln('r');
      await _runningProcess!.stdin.flush();
      _outputController.add('Performing hot reload...\n');
    }
  }

  /// Hot restart the running app
  Future<void> hotRestart() async {
    if (_runningProcess != null) {
      _runningProcess!.stdin.writeln('R');
      await _runningProcess!.stdin.flush();
      _outputController.add('Performing hot restart...\n');
    }
  }

  /// Stop the running process
  Future<void> stop() async {
    if (_runningProcess != null) {
      // Try graceful quit first
      _runningProcess!.stdin.writeln('q');
      await _runningProcess!.stdin.flush();
      _outputController.add('Stopping application...\n');

      // Wait a moment for graceful shutdown
      await Future.delayed(const Duration(seconds: 1));

      // Force kill if still running
      if (_runningProcess != null) {
        _runningProcess!.kill(ProcessSignal.sigterm);
        _runningProcess = null;
        _outputController.add('Application terminated.\n');
      }
    }
  }

  /// Build the Flutter project
  Stream<String> buildProject({
    required String projectPath,
    required String platform, // 'apk', 'appbundle', 'ios', 'web', 'macos', 'windows', 'linux'
    bool release = false,
    bool verbose = false,
  }) async* {
    final args = ['build', platform];
    if (release) {
      args.add('--release');
    }
    if (verbose) {
      args.add('-v');
    }

    yield '> flutter ${args.join(' ')}\n';
    yield 'Working directory: $projectPath\n\n';

    yield* _runCommand('flutter', args, workingDirectory: projectPath);
  }

  /// Run flutter pub get
  Stream<String> pubGet({required String projectPath}) async* {
    yield '> flutter pub get\n';
    yield 'Working directory: $projectPath\n\n';

    yield* _runCommand('flutter', ['pub', 'get'], workingDirectory: projectPath);
  }

  /// Run flutter clean
  Stream<String> clean({required String projectPath}) async* {
    yield '> flutter clean\n';
    yield 'Working directory: $projectPath\n\n';

    yield* _runCommand('flutter', ['clean'], workingDirectory: projectPath);
  }

  /// Run flutter create
  Stream<String> createProject({
    required String name,
    required String outputPath,
    String? organization,
    List<String>? platforms,
    String? template,
  }) async* {
    final args = ['create', name];

    if (organization != null) {
      args.addAll(['--org', organization]);
    }

    if (platforms != null && platforms.isNotEmpty) {
      args.addAll(['--platforms', platforms.join(',')]);
    }

    if (template != null) {
      args.addAll(['-t', template]);
    }

    yield '> flutter ${args.join(' ')}\n';
    yield 'Working directory: $outputPath\n\n';

    yield* _runCommand('flutter', args, workingDirectory: outputPath);
  }

  /// Run flutter analyze
  Stream<String> analyze({required String projectPath}) async* {
    yield '> flutter analyze\n';
    yield 'Working directory: $projectPath\n\n';

    yield* _runCommand('flutter', ['analyze'], workingDirectory: projectPath);
  }

  /// Run flutter test
  Stream<String> test({
    required String projectPath,
    String? testFile,
    bool verbose = false,
  }) async* {
    final args = ['test'];
    if (testFile != null) {
      args.add(testFile);
    }
    if (verbose) {
      args.add('-v');
    }

    yield '> flutter ${args.join(' ')}\n';
    yield 'Working directory: $projectPath\n\n';

    yield* _runCommand('flutter', args, workingDirectory: projectPath);
  }

  /// Run any flutter command
  Stream<String> runCommand({
    required String command,
    required List<String> args,
    required String workingDirectory,
  }) async* {
    yield '> $command ${args.join(' ')}\n';
    yield 'Working directory: $workingDirectory\n\n';

    yield* _runCommand(command, args, workingDirectory: workingDirectory);
  }

  /// Start a long-running process (like flutter run)
  Stream<String> _startProcess(
    String executable,
    List<String> arguments, {
    required String workingDirectory,
  }) async* {
    try {
      _runningProcess = await Process.start(
        executable,
        arguments,
        workingDirectory: workingDirectory,
        runInShell: Platform.isWindows,
      );

      // Stream stdout
      _runningProcess!.stdout.transform(utf8.decoder).listen((data) {
        _outputController.add(data);
      });

      // Stream stderr
      _runningProcess!.stderr.transform(utf8.decoder).listen((data) {
        _outputController.add(data);
      });

      // Handle process exit
      _runningProcess!.exitCode.then((code) {
        _outputController.add('\nProcess exited with code: $code\n');
        _runningProcess = null;
      });

      // Yield initial output from the stream with proper timeout handling
      // Use a timeout that actually cancels the stream instead of an empty callback
      try {
        final timeoutDuration = const Duration(seconds: 60);
        final startTime = DateTime.now();

        await for (final output in _outputController.stream) {
          yield output;

          // Break after initial setup (when we see "Running" or similar)
          if (output.contains('is available at') ||
              output.contains('Application running') ||
              output.contains('Syncing files')) {
            break;
          }

          // Manual timeout check to prevent hanging
          if (DateTime.now().difference(startTime) > timeoutDuration) {
            yield 'Timeout waiting for application to start\n';
            break;
          }
        }
      } on TimeoutException catch (e) {
        yield 'Timeout: $e\n';
      }
    } catch (e) {
      yield 'Error starting process: $e\n';
      _runningProcess = null;
    }
  }

  /// Run a command and wait for completion
  Stream<String> _runCommand(
    String executable,
    List<String> arguments, {
    required String workingDirectory,
  }) async* {
    try {
      final process = await Process.start(
        executable,
        arguments,
        workingDirectory: workingDirectory,
        runInShell: Platform.isWindows,
      );

      // Stream stdout
      await for (final data in process.stdout.transform(utf8.decoder)) {
        yield data;
        _outputController.add(data);
      }

      // Stream stderr
      await for (final data in process.stderr.transform(utf8.decoder)) {
        yield data;
        _outputController.add(data);
      }

      final exitCode = await process.exitCode;
      final exitMessage = '\nProcess completed with exit code: $exitCode\n';
      yield exitMessage;
      _outputController.add(exitMessage);
    } catch (e) {
      final errorMessage = 'Error running command: $e\n';
      yield errorMessage;
      _outputController.add(errorMessage);
    }
  }

  /// Get available devices
  Future<List<FlutterDevice>> getDevices() async {
    try {
      final result = await Process.run(
        'flutter',
        ['devices', '--machine'],
        runInShell: Platform.isWindows,
      );

      if (result.exitCode == 0) {
        final devices = jsonDecode(result.stdout) as List;
        return devices.map((d) => FlutterDevice.fromJson(d)).toList();
      }
    } catch (e) {
      // Failed to get devices
    }
    return [];
  }

  /// Check Flutter installation
  Future<FlutterInfo?> getFlutterInfo() async {
    try {
      final result = await Process.run(
        'flutter',
        ['--version', '--machine'],
        runInShell: Platform.isWindows,
      );

      if (result.exitCode == 0) {
        return FlutterInfo.fromJson(jsonDecode(result.stdout));
      }
    } catch (e) {
      // Failed to get Flutter info
    }
    return null;
  }

  /// Dispose of resources
  void dispose() {
    stop();
    _outputController.close();
  }
}

/// Flutter device info
class FlutterDevice {
  final String id;
  final String name;
  final String platform;
  final bool isEmulator;

  FlutterDevice({
    required this.id,
    required this.name,
    required this.platform,
    required this.isEmulator,
  });

  factory FlutterDevice.fromJson(Map<String, dynamic> json) {
    return FlutterDevice(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      platform: json['platform'] ?? json['targetPlatform'] ?? '',
      isEmulator: json['emulator'] ?? false,
    );
  }
}

/// Flutter installation info
class FlutterInfo {
  final String version;
  final String channel;
  final String dartVersion;
  final String frameworkRevision;

  FlutterInfo({
    required this.version,
    required this.channel,
    required this.dartVersion,
    required this.frameworkRevision,
  });

  factory FlutterInfo.fromJson(Map<String, dynamic> json) {
    return FlutterInfo(
      version: json['flutterVersion'] ?? '',
      channel: json['channel'] ?? '',
      dartVersion: json['dartSdkVersion'] ?? '',
      frameworkRevision: json['frameworkRevision'] ?? '',
    );
  }
}
