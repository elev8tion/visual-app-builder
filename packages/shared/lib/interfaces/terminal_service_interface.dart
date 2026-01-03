import '../models/terminal.dart';

/// Interface for terminal service operations
///
/// This interface defines all terminal/process operations that require
/// system access. Backend implements with dart:io, frontend uses HTTP/WebSocket.
abstract class ITerminalService {
  /// Check if a process is currently running
  bool get isRunning;

  /// Stream of terminal output
  Stream<String> get outputStream;

  /// Run a Flutter project
  Stream<String> runProject({
    required String projectPath,
    String? device,
    bool verbose = false,
  });

  /// Hot reload the running app
  Future<void> hotReload();

  /// Hot restart the running app
  Future<void> hotRestart();

  /// Stop the running process
  Future<void> stop();

  /// Build the Flutter project
  Stream<String> buildProject({
    required String projectPath,
    required String platform,
    bool release = false,
    bool verbose = false,
  });

  /// Run flutter pub get
  Stream<String> pubGet({required String projectPath});

  /// Run flutter clean
  Stream<String> clean({required String projectPath});

  /// Run flutter create
  Stream<String> createProject({
    required String name,
    required String outputPath,
    String? organization,
    List<String>? platforms,
    String? template,
  });

  /// Run flutter analyze
  Stream<String> analyze({required String projectPath});

  /// Run flutter test
  Stream<String> test({
    required String projectPath,
    String? testFile,
    bool verbose = false,
  });

  /// Run any command
  Stream<String> runCommand({
    required String command,
    required List<String> args,
    required String workingDirectory,
  });

  /// Get available Flutter devices
  Future<List<FlutterDevice>> getDevices();

  /// Get Flutter installation info
  Future<FlutterInfo?> getFlutterInfo();

  /// Dispose resources
  void dispose();
}
