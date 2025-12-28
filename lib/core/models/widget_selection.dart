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

  const ProjectFile({
    required this.path,
    required this.content,
    required this.fileName,
    this.isDirty = false,
    this.lastModified,
  });

  ProjectFile copyWith({
    String? path,
    String? content,
    String? fileName,
    bool? isDirty,
    DateTime? lastModified,
  }) {
    return ProjectFile(
      path: path ?? this.path,
      content: content ?? this.content,
      fileName: fileName ?? this.fileName,
      isDirty: isDirty ?? this.isDirty,
      lastModified: lastModified ?? this.lastModified,
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
}
