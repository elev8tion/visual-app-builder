import '../models/project.dart';

/// Interface for configuration service
///
/// Manages application settings and preferences.
abstract class IConfigService {
  /// Get OpenAI API key
  Future<String?> getOpenAIKey();

  /// Set OpenAI API key
  Future<void> setOpenAIKey(String key);

  /// Get OpenAI model
  Future<String?> getOpenAIModel();

  /// Set OpenAI model
  Future<void> setOpenAIModel(String model);

  /// Check if OpenAI is configured
  Future<bool> isOpenAIConfigured();

  /// Get organization identifier
  Future<String?> getOrganization();

  /// Set organization identifier
  Future<void> setOrganization(String org);

  /// Get default project path
  Future<String?> getDefaultProjectPath();

  /// Set default project path
  Future<void> setDefaultProjectPath(String path);

  /// Get recent projects
  Future<List<RecentProject>> getRecentProjects();

  /// Add a recent project
  Future<void> addRecentProject(String projectPath);

  /// Remove a recent project
  Future<void> removeRecentProject(String projectPath);

  /// Clear all recent projects
  Future<void> clearRecentProjects();

  /// Get a generic config value
  Future<String?> getValue(String key);

  /// Set a generic config value
  Future<void> setValue(String key, String value);

  /// Remove a config value
  Future<void> removeValue(String key);
}
