import 'dart:io';
import 'package:visual_app_builder_backend/server.dart';

Future<void> main(List<String> args) async {
  // Parse command line arguments
  int port = 8080;
  String? staticFilesPath;

  for (int i = 0; i < args.length; i++) {
    switch (args[i]) {
      case '--port':
      case '-p':
        if (i + 1 < args.length) {
          port = int.tryParse(args[i + 1]) ?? 8080;
          i++;
        }
        break;
      case '--static-files':
      case '-s':
        if (i + 1 < args.length) {
          staticFilesPath = args[i + 1];
          i++;
        }
        break;
      case '--help':
      case '-h':
        _printHelp();
        exit(0);
    }
  }

  print('Visual App Builder Backend Server');
  print('=' * 40);

  final server = VisualAppBuilderServer(
    port: port,
    staticFilesPath: staticFilesPath,
  );

  await server.start();

  print('Server running on http://localhost:$port');
  if (staticFilesPath != null) {
    print('Serving static files from: $staticFilesPath');
  }
  print('Press Ctrl+C to stop');

  // Handle shutdown
  ProcessSignal.sigint.watch().listen((_) async {
    print('\nShutting down...');
    await server.stop();
    exit(0);
  });
}

void _printHelp() {
  print('''
Visual App Builder Backend Server

Usage: dart run bin/server.dart [options]

Options:
  -p, --port <port>           Server port (default: 8080)
  -s, --static-files <path>   Serve static files from path
  -h, --help                  Show this help message

Example:
  dart run bin/server.dart --port 8080 --static-files ./web
''');
}
