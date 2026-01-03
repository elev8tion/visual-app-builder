/// Flutter device info
class FlutterDevice {
  final String id;
  final String name;
  final String platform;
  final bool isEmulator;

  const FlutterDevice({
    required this.id,
    required this.name,
    required this.platform,
    required this.isEmulator,
  });

  factory FlutterDevice.fromJson(Map<String, dynamic> json) {
    return FlutterDevice(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      platform: json['platform'] as String? ?? json['targetPlatform'] as String? ?? '',
      isEmulator: json['emulator'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'platform': platform,
        'emulator': isEmulator,
      };
}

/// Flutter installation info
class FlutterInfo {
  final String version;
  final String channel;
  final String dartVersion;
  final String frameworkRevision;

  const FlutterInfo({
    required this.version,
    required this.channel,
    required this.dartVersion,
    required this.frameworkRevision,
  });

  factory FlutterInfo.fromJson(Map<String, dynamic> json) {
    return FlutterInfo(
      version: json['flutterVersion'] as String? ?? '',
      channel: json['channel'] as String? ?? '',
      dartVersion: json['dartSdkVersion'] as String? ?? '',
      frameworkRevision: json['frameworkRevision'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'flutterVersion': version,
        'channel': channel,
        'dartSdkVersion': dartVersion,
        'frameworkRevision': frameworkRevision,
      };
}

/// Terminal command request
class TerminalCommand {
  final String command;
  final List<String> args;
  final String workingDirectory;

  const TerminalCommand({
    required this.command,
    required this.args,
    required this.workingDirectory,
  });

  factory TerminalCommand.fromJson(Map<String, dynamic> json) {
    return TerminalCommand(
      command: json['command'] as String,
      args: (json['args'] as List<dynamic>?)?.cast<String>() ?? [],
      workingDirectory: json['workingDirectory'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'command': command,
        'args': args,
        'workingDirectory': workingDirectory,
      };
}

/// Terminal output message
class TerminalOutput {
  final String data;
  final TerminalOutputType type;
  final DateTime timestamp;

  const TerminalOutput({
    required this.data,
    required this.type,
    required this.timestamp,
  });

  factory TerminalOutput.fromJson(Map<String, dynamic> json) {
    return TerminalOutput(
      data: json['data'] as String,
      type: TerminalOutputType.values.firstWhere(
        (t) => t.name == json['type'],
        orElse: () => TerminalOutputType.stdout,
      ),
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'data': data,
        'type': type.name,
        'timestamp': timestamp.toIso8601String(),
      };
}

enum TerminalOutputType {
  stdout,
  stderr,
  system,
}
