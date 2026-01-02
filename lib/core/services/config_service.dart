import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;

/// Config Service
///
/// Manages application configuration including API keys and settings.
/// Stores config in a local JSON file for persistence.
class ConfigService {
  static final ConfigService _instance = ConfigService._internal();
  static ConfigService get instance => _instance;
  ConfigService._internal();

  Map<String, dynamic> _config = {};
  bool _isLoaded = false;

  static const String _configFileName = '.visual_app_builder_config.json';

  /// Get the config file path
  String get _configFilePath {
    final home = Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'] ?? '.';
    return p.join(home, _configFileName);
  }

  /// Load configuration from disk
  Future<void> load() async {
    if (_isLoaded) return;

    try {
      final file = File(_configFilePath);
      if (await file.exists()) {
        final content = await file.readAsString();
        _config = jsonDecode(content) as Map<String, dynamic>;
      }
      _isLoaded = true;
    } catch (e) {
      _config = {};
      _isLoaded = true;
    }
  }

  /// Save configuration to disk
  Future<void> _save() async {
    try {
      final file = File(_configFilePath);
      await file.writeAsString(jsonEncode(_config));
    } catch (e) {
      // Failed to save config
    }
  }

  /// Ensure config is loaded before accessing
  Future<void> _ensureLoaded() async {
    if (!_isLoaded) {
      await load();
    }
  }

  // ==================== OpenAI Settings ====================

  /// Get the OpenAI API key
  Future<String?> getOpenAIKey() async {
    await _ensureLoaded();
    return _config['openai_api_key'] as String?;
  }

  /// Set the OpenAI API key
  Future<void> setOpenAIKey(String key) async {
    await _ensureLoaded();
    _config['openai_api_key'] = key;
    await _save();
  }

  /// Clear the OpenAI API key
  Future<void> clearOpenAIKey() async {
    await _ensureLoaded();
    _config.remove('openai_api_key');
    await _save();
  }

  /// Check if OpenAI is configured
  Future<bool> isOpenAIConfigured() async {
    final key = await getOpenAIKey();
    return key != null && key.isNotEmpty;
  }

  /// Get the OpenAI model
  Future<String> getOpenAIModel() async {
    await _ensureLoaded();
    return _config['openai_model'] as String? ?? 'gpt-4-turbo-preview';
  }

  /// Set the OpenAI model
  Future<void> setOpenAIModel(String model) async {
    await _ensureLoaded();
    _config['openai_model'] = model;
    await _save();
  }

  // ==================== Project Settings ====================

  /// Get the default project path
  Future<String?> getDefaultProjectPath() async {
    await _ensureLoaded();
    return _config['default_project_path'] as String?;
  }

  /// Set the default project path
  Future<void> setDefaultProjectPath(String path) async {
    await _ensureLoaded();
    _config['default_project_path'] = path;
    await _save();
  }

  /// Get recent projects
  Future<List<String>> getRecentProjects() async {
    await _ensureLoaded();
    final recent = _config['recent_projects'] as List<dynamic>?;
    return recent?.cast<String>() ?? [];
  }

  /// Add a recent project
  Future<void> addRecentProject(String path) async {
    await _ensureLoaded();
    final recent = await getRecentProjects();
    recent.remove(path); // Remove if exists
    recent.insert(0, path); // Add to front
    if (recent.length > 10) {
      recent.removeLast(); // Keep only 10 recent
    }
    _config['recent_projects'] = recent;
    await _save();
  }

  // ==================== Editor Settings ====================

  /// Get editor theme
  Future<String> getEditorTheme() async {
    await _ensureLoaded();
    return _config['editor_theme'] as String? ?? 'dark';
  }

  /// Set editor theme
  Future<void> setEditorTheme(String theme) async {
    await _ensureLoaded();
    _config['editor_theme'] = theme;
    await _save();
  }

  /// Get font size
  Future<double> getFontSize() async {
    await _ensureLoaded();
    return (_config['font_size'] as num?)?.toDouble() ?? 14.0;
  }

  /// Set font size
  Future<void> setFontSize(double size) async {
    await _ensureLoaded();
    _config['font_size'] = size;
    await _save();
  }

  /// Get auto-save enabled
  Future<bool> getAutoSaveEnabled() async {
    await _ensureLoaded();
    return _config['auto_save_enabled'] as bool? ?? true;
  }

  /// Set auto-save enabled
  Future<void> setAutoSaveEnabled(bool enabled) async {
    await _ensureLoaded();
    _config['auto_save_enabled'] = enabled;
    await _save();
  }

  // ==================== Generation Settings ====================

  /// Get preferred state management
  Future<String> getPreferredStateManagement() async {
    await _ensureLoaded();
    return _config['preferred_state_management'] as String? ?? 'provider';
  }

  /// Set preferred state management
  Future<void> setPreferredStateManagement(String sm) async {
    await _ensureLoaded();
    _config['preferred_state_management'] = sm;
    await _save();
  }

  /// Get organization identifier
  Future<String> getOrganization() async {
    await _ensureLoaded();
    return _config['organization'] as String? ?? 'com.example';
  }

  /// Set organization identifier
  Future<void> setOrganization(String org) async {
    await _ensureLoaded();
    _config['organization'] = org;
    await _save();
  }

  // ==================== Generic Settings ====================

  /// Get a setting value
  Future<T?> get<T>(String key) async {
    await _ensureLoaded();
    return _config[key] as T?;
  }

  /// Set a setting value
  Future<void> set<T>(String key, T value) async {
    await _ensureLoaded();
    _config[key] = value;
    await _save();
  }

  /// Remove a setting
  Future<void> remove(String key) async {
    await _ensureLoaded();
    _config.remove(key);
    await _save();
  }

  /// Clear all settings
  Future<void> clearAll() async {
    _config = {};
    await _save();
  }
}
