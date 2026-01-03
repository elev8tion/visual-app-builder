import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:visual_app_builder_shared/visual_app_builder_shared.dart';

/// Backend implementation of config service using file storage
class ConfigServiceImpl implements IConfigService {
  static const String _configFileName = '.visual_app_builder_config.json';
  Map<String, dynamic>? _cache;

  String get _configFilePath {
    final home = Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'] ?? '.';
    return path.join(home, _configFileName);
  }

  Future<Map<String, dynamic>> _loadConfig() async {
    if (_cache != null) return _cache!;

    try {
      final file = File(_configFilePath);
      if (await file.exists()) {
        final content = await file.readAsString();
        _cache = jsonDecode(content) as Map<String, dynamic>;
      } else {
        _cache = {};
      }
    } catch (e) {
      _cache = {};
    }
    return _cache!;
  }

  Future<void> _saveConfig() async {
    try {
      final file = File(_configFilePath);
      await file.writeAsString(jsonEncode(_cache ?? {}));
    } catch (e) {
      // Failed to save config
    }
  }

  @override
  Future<String?> getOpenAIKey() async {
    final config = await _loadConfig();
    return config['openai_api_key'] as String?;
  }

  @override
  Future<void> setOpenAIKey(String key) async {
    final config = await _loadConfig();
    config['openai_api_key'] = key;
    _cache = config;
    await _saveConfig();
  }

  @override
  Future<String?> getOpenAIModel() async {
    final config = await _loadConfig();
    return config['openai_model'] as String?;
  }

  @override
  Future<void> setOpenAIModel(String model) async {
    final config = await _loadConfig();
    config['openai_model'] = model;
    _cache = config;
    await _saveConfig();
  }

  @override
  Future<bool> isOpenAIConfigured() async {
    final key = await getOpenAIKey();
    return key != null && key.isNotEmpty;
  }

  @override
  Future<String?> getOrganization() async {
    final config = await _loadConfig();
    return config['organization'] as String?;
  }

  @override
  Future<void> setOrganization(String org) async {
    final config = await _loadConfig();
    config['organization'] = org;
    _cache = config;
    await _saveConfig();
  }

  @override
  Future<String?> getDefaultProjectPath() async {
    final config = await _loadConfig();
    return config['default_project_path'] as String?;
  }

  @override
  Future<void> setDefaultProjectPath(String path) async {
    final config = await _loadConfig();
    config['default_project_path'] = path;
    _cache = config;
    await _saveConfig();
  }

  @override
  Future<List<RecentProject>> getRecentProjects() async {
    final config = await _loadConfig();
    final recentList = config['recent_projects'] as List<dynamic>? ?? [];
    return recentList.map((r) => RecentProject.fromJson(r as Map<String, dynamic>)).toList();
  }

  @override
  Future<void> addRecentProject(String projectPath) async {
    final config = await _loadConfig();
    final recentList = (config['recent_projects'] as List<dynamic>? ?? [])
        .map((r) => RecentProject.fromJson(r as Map<String, dynamic>))
        .toList();

    // Remove if exists
    recentList.removeWhere((r) => r.path == projectPath);

    // Add to front
    final projectName = path.basename(projectPath);
    recentList.insert(
        0,
        RecentProject(
          name: projectName,
          path: projectPath,
          lastOpened: DateTime.now(),
        ));

    // Keep only 10 recent
    if (recentList.length > 10) {
      recentList.removeRange(10, recentList.length);
    }

    config['recent_projects'] = recentList.map((r) => r.toJson()).toList();
    _cache = config;
    await _saveConfig();
  }

  @override
  Future<void> removeRecentProject(String projectPath) async {
    final config = await _loadConfig();
    final recentList = (config['recent_projects'] as List<dynamic>? ?? [])
        .map((r) => RecentProject.fromJson(r as Map<String, dynamic>))
        .toList();

    recentList.removeWhere((r) => r.path == projectPath);

    config['recent_projects'] = recentList.map((r) => r.toJson()).toList();
    _cache = config;
    await _saveConfig();
  }

  @override
  Future<void> clearRecentProjects() async {
    final config = await _loadConfig();
    config['recent_projects'] = [];
    _cache = config;
    await _saveConfig();
  }

  @override
  Future<String?> getValue(String key) async {
    final config = await _loadConfig();
    return config[key] as String?;
  }

  @override
  Future<void> setValue(String key, String value) async {
    final config = await _loadConfig();
    config[key] = value;
    _cache = config;
    await _saveConfig();
  }

  @override
  Future<void> removeValue(String key) async {
    final config = await _loadConfig();
    config.remove(key);
    _cache = config;
    await _saveConfig();
  }
}
