import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:visual_app_builder_shared/visual_app_builder_shared.dart';

/// Backend implementation of terminal service using dart:io
class TerminalServiceImpl implements ITerminalService {
  Process? _runningProcess;
  final StreamController<String> _outputController = StreamController<String>.broadcast();

  @override
  Stream<String> get outputStream => _outputController.stream;

  @override
  bool get isRunning => _runningProcess != null;

  @override
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

  @override
  Future<void> hotReload() async {
    if (_runningProcess != null) {
      _runningProcess!.stdin.writeln('r');
      await _runningProcess!.stdin.flush();
      _outputController.add('Performing hot reload...\n');
    }
  }

  @override
  Future<void> hotRestart() async {
    if (_runningProcess != null) {
      _runningProcess!.stdin.writeln('R');
      await _runningProcess!.stdin.flush();
      _outputController.add('Performing hot restart...\n');
    }
  }

  @override
  Future<void> stop() async {
    if (_runningProcess != null) {
      _runningProcess!.stdin.writeln('q');
      await _runningProcess!.stdin.flush();
      _outputController.add('Stopping application...\n');

      await Future.delayed(const Duration(seconds: 1));

      if (_runningProcess != null) {
        _runningProcess!.kill(ProcessSignal.sigterm);
        _runningProcess = null;
        _outputController.add('Application terminated.\n');
      }
    }
  }

  @override
  Stream<String> buildProject({
    required String projectPath,
    required String platform,
    bool release = false,
    bool verbose = false,
  }) async* {
    final args = ['build', platform];
    if (release) args.add('--release');
    if (verbose) args.add('-v');

    yield '> flutter ${args.join(' ')}\n';
    yield 'Working directory: $projectPath\n\n';

    yield* _runCommand('flutter', args, workingDirectory: projectPath);
  }

  @override
  Stream<String> pubGet({required String projectPath}) async* {
    yield '> flutter pub get\n';
    yield 'Working directory: $projectPath\n\n';

    yield* _runCommand('flutter', ['pub', 'get'], workingDirectory: projectPath);
  }

  @override
  Stream<String> clean({required String projectPath}) async* {
    yield '> flutter clean\n';
    yield 'Working directory: $projectPath\n\n';

    yield* _runCommand('flutter', ['clean'], workingDirectory: projectPath);
  }

  @override
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

  @override
  Stream<String> analyze({required String projectPath}) async* {
    yield '> flutter analyze\n';
    yield 'Working directory: $projectPath\n\n';

    yield* _runCommand('flutter', ['analyze'], workingDirectory: projectPath);
  }

  @override
  Stream<String> test({
    required String projectPath,
    String? testFile,
    bool verbose = false,
  }) async* {
    final args = ['test'];
    if (testFile != null) args.add(testFile);
    if (verbose) args.add('-v');

    yield '> flutter ${args.join(' ')}\n';
    yield 'Working directory: $projectPath\n\n';

    yield* _runCommand('flutter', args, workingDirectory: projectPath);
  }

  @override
  Stream<String> runCommand({
    required String command,
    required List<String> args,
    required String workingDirectory,
  }) async* {
    yield '> $command ${args.join(' ')}\n';
    yield 'Working directory: $workingDirectory\n\n';

    yield* _runCommand(command, args, workingDirectory: workingDirectory);
  }

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

      _runningProcess!.stdout.transform(utf8.decoder).listen((data) {
        _outputController.add(data);
      });

      _runningProcess!.stderr.transform(utf8.decoder).listen((data) {
        _outputController.add(data);
      });

      _runningProcess!.exitCode.then((code) {
        _outputController.add('\nProcess exited with code: $code\n');
        _runningProcess = null;
      });

      await for (final output in _outputController.stream.timeout(
        const Duration(seconds: 60),
        onTimeout: (sink) {},
      )) {
        yield output;
        if (output.contains('is available at') ||
            output.contains('Application running') ||
            output.contains('Syncing files')) {
          break;
        }
      }
    } catch (e) {
      yield 'Error starting process: $e\n';
      _runningProcess = null;
    }
  }

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

      await for (final data in process.stdout.transform(utf8.decoder)) {
        yield data;
        _outputController.add(data);
      }

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

  @override
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

  @override
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

  @override
  void dispose() {
    stop();
    _outputController.close();
  }
}
