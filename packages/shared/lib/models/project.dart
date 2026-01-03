/// Flutter project metadata
class FlutterProject {
  final String name;
  final String path;
  final String? description;
  final DateTime? createdAt;
  final DateTime? modifiedAt;
  final List<String> platforms;

  const FlutterProject({
    required this.name,
    required this.path,
    this.description,
    this.createdAt,
    this.modifiedAt,
    this.platforms = const ['android', 'ios', 'web'],
  });

  factory FlutterProject.fromJson(Map<String, dynamic> json) {
    return FlutterProject(
      name: json['name'] as String,
      path: json['path'] as String,
      description: json['description'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
      modifiedAt: json['modifiedAt'] != null
          ? DateTime.parse(json['modifiedAt'] as String)
          : null,
      platforms:
          (json['platforms'] as List<dynamic>?)?.cast<String>() ?? const [],
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'path': path,
        if (description != null) 'description': description,
        if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
        if (modifiedAt != null) 'modifiedAt': modifiedAt!.toIso8601String(),
        'platforms': platforms,
      };
}

/// Recent project entry
class RecentProject {
  final String name;
  final String path;
  final DateTime lastOpened;

  const RecentProject({
    required this.name,
    required this.path,
    required this.lastOpened,
  });

  factory RecentProject.fromJson(Map<String, dynamic> json) {
    return RecentProject(
      name: json['name'] as String,
      path: json['path'] as String,
      lastOpened: DateTime.parse(json['lastOpened'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'path': path,
        'lastOpened': lastOpened.toIso8601String(),
      };
}

/// Project file with content
class ProjectFile {
  final String path;
  final String name;
  final String content;
  final bool isModified;

  const ProjectFile({
    required this.path,
    required this.name,
    required this.content,
    this.isModified = false,
  });

  factory ProjectFile.fromJson(Map<String, dynamic> json) {
    return ProjectFile(
      path: json['path'] as String,
      name: json['name'] as String,
      content: json['content'] as String,
      isModified: json['isModified'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'path': path,
        'name': name,
        'content': content,
        'isModified': isModified,
      };
}
