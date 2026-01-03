import 'package:visual_app_builder_shared/visual_app_builder_shared.dart';

import '../api_client.dart';

/// Web implementation of config service using API client
class ConfigServiceWeb implements IConfigService {
  final ApiClient _apiClient;

  ConfigServiceWeb(this._apiClient);

  @override
  Future<String?> getOpenAIKey() async {
    try {
      final config = await _apiClient.getOpenAIConfig();
      // API doesn't return the actual key for security, only if it's set
      return config['hasKey'] == true ? '<configured>' : null;
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> setOpenAIKey(String key) async {
    await _apiClient.setOpenAIConfig(apiKey: key);
  }

  @override
  Future<String?> getOpenAIModel() async {
    try {
      final config = await _apiClient.getOpenAIConfig();
      return config['model'] as String?;
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> setOpenAIModel(String model) async {
    await _apiClient.setOpenAIConfig(model: model);
  }

  @override
  Future<bool> isOpenAIConfigured() async {
    try {
      final config = await _apiClient.getOpenAIConfig();
      return config['isConfigured'] as bool? ?? false;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<String?> getOrganization() async {
    return _apiClient.getConfigValue('organization');
  }

  @override
  Future<void> setOrganization(String organization) async {
    await _apiClient.setConfigValue('organization', organization);
  }

  @override
  Future<String?> getDefaultProjectPath() async {
    return _apiClient.getConfigValue('defaultProjectPath');
  }

  @override
  Future<void> setDefaultProjectPath(String path) async {
    await _apiClient.setConfigValue('defaultProjectPath', path);
  }

  @override
  Future<List<RecentProject>> getRecentProjects() async {
    try {
      final projects = await _apiClient.getRecentProjects();
      return projects.map((p) => RecentProject.fromJson(p)).toList();
    } catch (e) {
      return [];
    }
  }

  @override
  Future<void> addRecentProject(String path) async {
    // This is handled internally by the backend when opening a project
    // No direct API call needed
  }

  @override
  Future<void> removeRecentProject(String projectPath) async {
    // TODO: Add API endpoint for removing recent project
    // For now, this is a no-op as the backend manages recent projects
  }

  @override
  Future<void> clearRecentProjects() async {
    // TODO: Add API endpoint for clearing recent projects
    // For now, this is a no-op as the backend manages recent projects
  }

  @override
  Future<String?> getValue(String key) async {
    return _apiClient.getConfigValue(key);
  }

  @override
  Future<void> setValue(String key, String value) async {
    await _apiClient.setConfigValue(key, value);
  }

  @override
  Future<void> removeValue(String key) async {
    await _apiClient.removeConfigValue(key);
  }
}
