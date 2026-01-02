import 'dart:async';

class TerminalService {
  static final TerminalService _instance = TerminalService._internal();
  static TerminalService get instance => _instance;

  TerminalService._internal();

  /// Simulates running the Flutter project
  Stream<String> runProject() async* {
    yield 'Launching lib/main.dart on macOS...\n';
    await Future.delayed(const Duration(milliseconds: 500));
    yield 'CocoaPods\' podfile setup completed.\n';
    await Future.delayed(const Duration(milliseconds: 300));
    yield 'Resolving dependencies...\n';
    await Future.delayed(const Duration(milliseconds: 800));
    yield 'Building macOS application...\n';
    await Future.delayed(const Duration(seconds: 2));
    yield 'Syncing files to device macOS...\n';
    await Future.delayed(const Duration(milliseconds: 500));
    yield '\n';
    yield 'Flutter run key commands.\n';
    yield 'r Hot reload. 🔥\n';
    yield 'R Hot restart.\n';
    yield 'h List all available interactive commands.\n';
    yield 'd Detach (terminate "flutter run" but leave application running).\n';
    yield 'c Clear the screen\n';
    yield 'q Quit (terminate the application on the device).\n';
    yield '\n';
    yield '💪 Application running!\n';
  }

  /// Simulates a hot reload
  Stream<String> hotReload() async* {
    yield 'Performing hot reload...\n';
    await Future.delayed(const Duration(milliseconds: 400));
    yield 'Reloaded 1 of 612 libraries in 432ms.\n';
  }
}
