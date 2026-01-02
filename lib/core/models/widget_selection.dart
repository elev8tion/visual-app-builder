/// Widget Selection Model
/// Represents a selected widget with full metadata for bidirectional sync
class WidgetSelection {
  final String widgetType;
  final String widgetId;
  final String filePath;
  final int lineNumber;
  final int? endLineNumber;
  final Map<String, dynamic> properties;
  final String sourceCode;
  final WidgetLayoutInfo? layoutInfo;
  final List<String>? parentChain;

  const WidgetSelection({
    required this.widgetType,
    required this.widgetId,
    required this.filePath,
    required this.lineNumber,
    this.endLineNumber,
    this.properties = const {},
    this.sourceCode = '',
    this.layoutInfo,
    this.parentChain,
  });

  WidgetSelection copyWith({
    String? widgetType,
    String? widgetId,
    String? filePath,
    int? lineNumber,
    int? endLineNumber,
    Map<String, dynamic>? properties,
    String? sourceCode,
    WidgetLayoutInfo? layoutInfo,
    List<String>? parentChain,
  }) {
    return WidgetSelection(
      widgetType: widgetType ?? this.widgetType,
      widgetId: widgetId ?? this.widgetId,
      filePath: filePath ?? this.filePath,
      lineNumber: lineNumber ?? this.lineNumber,
      endLineNumber: endLineNumber ?? this.endLineNumber,
      properties: properties ?? this.properties,
      sourceCode: sourceCode ?? this.sourceCode,
      layoutInfo: layoutInfo ?? this.layoutInfo,
      parentChain: parentChain ?? this.parentChain,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WidgetSelection &&
        other.widgetId == widgetId &&
        other.filePath == filePath &&
        other.lineNumber == lineNumber;
  }

  @override
  int get hashCode => widgetId.hashCode ^ filePath.hashCode ^ lineNumber.hashCode;

  @override
  String toString() {
    return 'WidgetSelection($widgetType at $filePath:$lineNumber)';
  }
}

/// Layout information for a widget
class WidgetLayoutInfo {
  final double? width;
  final double? height;
  final double? x;
  final double? y;
  final int? flex;
  final String? alignment;
  final EdgeInsetsData? padding;
  final EdgeInsetsData? margin;
  final bool hasOverflow;

  const WidgetLayoutInfo({
    this.width,
    this.height,
    this.x,
    this.y,
    this.flex,
    this.alignment,
    this.padding,
    this.margin,
    this.hasOverflow = false,
  });

  Map<String, dynamic> toMap() {
    return {
      if (width != null) 'width': width,
      if (height != null) 'height': height,
      if (x != null) 'x': x,
      if (y != null) 'y': y,
      if (flex != null) 'flex': flex,
      if (alignment != null) 'alignment': alignment,
      if (padding != null) 'padding': padding?.toMap(),
      if (margin != null) 'margin': margin?.toMap(),
      'hasOverflow': hasOverflow,
    };
  }
}

/// Edge insets data for padding/margin
class EdgeInsetsData {
  final double left;
  final double top;
  final double right;
  final double bottom;

  const EdgeInsetsData({
    this.left = 0,
    this.top = 0,
    this.right = 0,
    this.bottom = 0,
  });

  const EdgeInsetsData.all(double value)
      : left = value,
        top = value,
        right = value,
        bottom = value;

  Map<String, double> toMap() {
    return {
      'left': left,
      'top': top,
      'right': right,
      'bottom': bottom,
    };
  }

  @override
  String toString() => 'EdgeInsets($left, $top, $right, $bottom)';
}

/// Widget type classification
enum WidgetType {
  root,
  app,
  layout,
  component,
  input,
  display,
}

/// Widget tree node for AST-parsed widget hierarchy
class WidgetTreeNode {
  final String name;
  final WidgetType type;
  final int line;
  final int? endLine;
  final Map<String, dynamic> properties;
  final List<WidgetTreeNode> children;
  final String? sourceCode;
  final int? nestingLevel;

  const WidgetTreeNode({
    required this.name,
    required this.type,
    required this.line,
    this.endLine,
    this.properties = const {},
    this.children = const [],
    this.sourceCode,
    this.nestingLevel,
  });

  WidgetTreeNode copyWith({
    String? name,
    WidgetType? type,
    int? line,
    int? endLine,
    Map<String, dynamic>? properties,
    List<WidgetTreeNode>? children,
    String? sourceCode,
    int? nestingLevel,
  }) {
    return WidgetTreeNode(
      name: name ?? this.name,
      type: type ?? this.type,
      line: line ?? this.line,
      endLine: endLine ?? this.endLine,
      properties: properties ?? this.properties,
      children: children ?? this.children,
      sourceCode: sourceCode ?? this.sourceCode,
      nestingLevel: nestingLevel ?? this.nestingLevel,
    );
  }

  @override
  String toString() => 'WidgetTreeNode($name at line $line)';
}

/// Project file model
class ProjectFile {
  final String path;
  final String content;
  final String fileName;
  final bool isDirty;
  final DateTime? lastModified;
  final bool isDirectory;
  final FileType type;

  ProjectFile({
    required this.path,
    required this.content,
    String? fileName,
    this.isDirty = false,
    this.lastModified,
    this.isDirectory = false,
    FileType? type,
  })  : fileName = fileName ?? path.split('/').last,
        type = type ?? FileTypeExtension.fromExtension(path.split('.').last);

  String get extension => fileName.contains('.') ? fileName.split('.').last : '';

  bool get isDartFile => extension == 'dart';

  bool get isYamlFile => extension == 'yaml' || extension == 'yml';

  bool get isJsonFile => extension == 'json';

  bool get isTextFile => isDartFile || isYamlFile || isJsonFile ||
                         extension == 'md' || extension == 'txt';

  ProjectFile copyWith({
    String? path,
    String? content,
    String? fileName,
    bool? isDirty,
    DateTime? lastModified,
    bool? isDirectory,
    FileType? type,
  }) {
    return ProjectFile(
      path: path ?? this.path,
      content: content ?? this.content,
      fileName: fileName ?? this.fileName,
      isDirty: isDirty ?? this.isDirty,
      lastModified: lastModified ?? this.lastModified,
      isDirectory: isDirectory ?? this.isDirectory,
      type: type ?? this.type,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'path': path,
      'content': content,
      'fileName': fileName,
      'isDirty': isDirty,
      'lastModified': lastModified?.toIso8601String(),
      'isDirectory': isDirectory,
      'type': type.name,
    };
  }

  factory ProjectFile.fromJson(Map<String, dynamic> json) {
    return ProjectFile(
      path: json['path'] ?? '',
      content: json['content'] ?? '',
      fileName: json['fileName'],
      isDirty: json['isDirty'] ?? false,
      lastModified: json['lastModified'] != null
          ? DateTime.parse(json['lastModified'])
          : null,
      isDirectory: json['isDirectory'] ?? false,
      type: json['type'] != null
          ? FileType.values.firstWhere(
              (e) => e.name == json['type'],
              orElse: () => FileType.other,
            )
          : null,
    );
  }
}

/// Flutter project model
class FlutterProject {
  final String name;
  final String path;
  final List<ProjectFile> files;
  final DateTime? createdAt;
  final DateTime? lastOpened;

  const FlutterProject({
    required this.name,
    required this.path,
    this.files = const [],
    this.createdAt,
    this.lastOpened,
  });

  List<ProjectFile> get dartFiles => files.where((f) => f.isDartFile).toList();

  List<ProjectFile> get directories => files.where((f) => f.isDirectory).toList();

  ProjectFile? get pubspecFile => files.where((f) => f.fileName == 'pubspec.yaml').firstOrNull;

  ProjectFile? get mainFile => files.where((f) => f.path.contains('lib/main.dart')).firstOrNull;

  bool get isValidFlutterProject {
    return pubspecFile != null &&
           files.any((f) => f.path.contains('lib/')) &&
           files.any((f) => f.path.contains('lib/main.dart'));
  }

  ProjectFile? findFileByPath(String filePath) {
    return files.where((f) => f.path == filePath).firstOrNull;
  }

  FlutterProject updateFile(String filePath, String newContent) {
    final updatedFiles = files.map((file) {
      if (file.path == filePath) {
        return file.copyWith(content: newContent, isDirty: true);
      }
      return file;
    }).toList();

    return copyWith(files: updatedFiles);
  }

  FlutterProject addFile(ProjectFile file) {
    return copyWith(files: [...files, file]);
  }

  FlutterProject copyWith({
    String? name,
    String? path,
    List<ProjectFile>? files,
    DateTime? createdAt,
    DateTime? lastOpened,
  }) {
    return FlutterProject(
      name: name ?? this.name,
      path: path ?? this.path,
      files: files ?? this.files,
      createdAt: createdAt ?? this.createdAt,
      lastOpened: lastOpened ?? this.lastOpened,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'path': path,
      'files': files.map((f) => f.toJson()).toList(),
      'createdAt': createdAt?.toIso8601String(),
      'lastOpened': lastOpened?.toIso8601String(),
    };
  }

  factory FlutterProject.fromJson(Map<String, dynamic> json) {
    return FlutterProject(
      name: json['name'] ?? 'Unnamed Project',
      path: json['path'] ?? '',
      files: (json['files'] as List? ?? [])
          .map((f) => ProjectFile.fromJson(f as Map<String, dynamic>))
          .toList(),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
      lastOpened: json['lastOpened'] != null
          ? DateTime.parse(json['lastOpened'])
          : null,
    );
  }
}

/// File type classification
enum FileType {
  dart,
  yaml,
  json,
  markdown,
  text,
  image,
  other,
}

/// Extension methods for FileType
extension FileTypeExtension on FileType {
  static FileType fromExtension(String extension) {
    switch (extension.toLowerCase()) {
      case 'dart':
        return FileType.dart;
      case 'yaml':
      case 'yml':
        return FileType.yaml;
      case 'json':
        return FileType.json;
      case 'md':
        return FileType.markdown;
      case 'txt':
        return FileType.text;
      case 'png':
      case 'jpg':
      case 'jpeg':
      case 'gif':
      case 'webp':
        return FileType.image;
      default:
        return FileType.other;
    }
  }

  String get displayName {
    switch (this) {
      case FileType.dart:
        return 'Dart';
      case FileType.yaml:
        return 'YAML';
      case FileType.json:
        return 'JSON';
      case FileType.markdown:
        return 'Markdown';
      case FileType.text:
        return 'Text';
      case FileType.image:
        return 'Image';
      case FileType.other:
        return 'Other';
    }
  }
}
