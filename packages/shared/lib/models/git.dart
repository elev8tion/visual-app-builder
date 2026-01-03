/// Git status for a repository
class GitStatus {
  final String branch;
  final List<GitFileChange> staged;
  final List<GitFileChange> unstaged;
  final List<String> untracked;
  final bool hasRemote;
  final int? ahead;
  final int? behind;

  const GitStatus({
    required this.branch,
    this.staged = const [],
    this.unstaged = const [],
    this.untracked = const [],
    this.hasRemote = false,
    this.ahead,
    this.behind,
  });

  factory GitStatus.fromJson(Map<String, dynamic> json) {
    return GitStatus(
      branch: json['branch'] as String? ?? 'main',
      staged: (json['staged'] as List<dynamic>?)
              ?.map((f) => GitFileChange.fromJson(f as Map<String, dynamic>))
              .toList() ??
          [],
      unstaged: (json['unstaged'] as List<dynamic>?)
              ?.map((f) => GitFileChange.fromJson(f as Map<String, dynamic>))
              .toList() ??
          [],
      untracked: (json['untracked'] as List<dynamic>?)?.cast<String>() ?? [],
      hasRemote: json['hasRemote'] as bool? ?? false,
      ahead: json['ahead'] as int?,
      behind: json['behind'] as int?,
    );
  }

  Map<String, dynamic> toJson() => {
        'branch': branch,
        'staged': staged.map((f) => f.toJson()).toList(),
        'unstaged': unstaged.map((f) => f.toJson()).toList(),
        'untracked': untracked,
        'hasRemote': hasRemote,
        if (ahead != null) 'ahead': ahead,
        if (behind != null) 'behind': behind,
      };

  bool get hasChanges =>
      staged.isNotEmpty || unstaged.isNotEmpty || untracked.isNotEmpty;
}

/// Git file change entry
class GitFileChange {
  final String path;
  final GitChangeType changeType;

  const GitFileChange({
    required this.path,
    required this.changeType,
  });

  factory GitFileChange.fromJson(Map<String, dynamic> json) {
    return GitFileChange(
      path: json['path'] as String,
      changeType: GitChangeType.values.firstWhere(
        (t) => t.name == json['changeType'],
        orElse: () => GitChangeType.modified,
      ),
    );
  }

  Map<String, dynamic> toJson() => {
        'path': path,
        'changeType': changeType.name,
      };
}

/// Git change types
enum GitChangeType {
  added,
  modified,
  deleted,
  renamed,
  copied,
}

/// Git commit info
class GitCommit {
  final String hash;
  final String message;
  final String author;
  final DateTime date;

  const GitCommit({
    required this.hash,
    required this.message,
    required this.author,
    required this.date,
  });

  factory GitCommit.fromJson(Map<String, dynamic> json) {
    return GitCommit(
      hash: json['hash'] as String,
      message: json['message'] as String,
      author: json['author'] as String,
      date: DateTime.parse(json['date'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'hash': hash,
        'message': message,
        'author': author,
        'date': date.toIso8601String(),
      };
}

/// Git commit request
class GitCommitRequest {
  final String projectPath;
  final String message;
  final List<String>? files;

  const GitCommitRequest({
    required this.projectPath,
    required this.message,
    this.files,
  });

  factory GitCommitRequest.fromJson(Map<String, dynamic> json) {
    return GitCommitRequest(
      projectPath: json['projectPath'] as String,
      message: json['message'] as String,
      files: (json['files'] as List<dynamic>?)?.cast<String>(),
    );
  }

  Map<String, dynamic> toJson() => {
        'projectPath': projectPath,
        'message': message,
        if (files != null) 'files': files,
      };
}

/// Git push request
class GitPushRequest {
  final String projectPath;
  final String? remote;
  final String? branch;

  const GitPushRequest({
    required this.projectPath,
    this.remote,
    this.branch,
  });

  factory GitPushRequest.fromJson(Map<String, dynamic> json) {
    return GitPushRequest(
      projectPath: json['projectPath'] as String,
      remote: json['remote'] as String?,
      branch: json['branch'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'projectPath': projectPath,
        if (remote != null) 'remote': remote,
        if (branch != null) 'branch': branch,
      };
}
