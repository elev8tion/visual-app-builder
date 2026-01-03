/// File tree node for project file system representation
class FileNode {
  final String name;
  final String path;
  final bool isDirectory;
  final List<FileNode> children;
  final bool isExpanded;

  const FileNode({
    required this.name,
    required this.path,
    this.isDirectory = false,
    this.children = const [],
    this.isExpanded = false,
  });

  FileNode copyWith({
    String? name,
    String? path,
    bool? isDirectory,
    List<FileNode>? children,
    bool? isExpanded,
  }) {
    return FileNode(
      name: name ?? this.name,
      path: path ?? this.path,
      isDirectory: isDirectory ?? this.isDirectory,
      children: children ?? this.children,
      isExpanded: isExpanded ?? this.isExpanded,
    );
  }

  factory FileNode.fromJson(Map<String, dynamic> json) {
    return FileNode(
      name: json['name'] as String,
      path: json['path'] as String,
      isDirectory: json['isDirectory'] as bool? ?? false,
      children: (json['children'] as List<dynamic>?)
              ?.map((c) => FileNode.fromJson(c as Map<String, dynamic>))
              .toList() ??
          const [],
      isExpanded: json['isExpanded'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'path': path,
        'isDirectory': isDirectory,
        'children': children.map((c) => c.toJson()).toList(),
        'isExpanded': isExpanded,
      };
}
