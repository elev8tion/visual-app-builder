import 'package:flutter/foundation.dart';
import 'package:visual_app_builder_shared/visual_app_builder_shared.dart';

import 'api_client.dart';
import 'web/terminal_service_web.dart';
import 'web/project_manager_web.dart';
import 'web/config_service_web.dart';
import 'web/git_service_web.dart';

/// Service locator for managing service instances.
///
/// On web platform, uses the API client to communicate with the backend server.
/// On desktop platform, uses direct dart:io implementations.
class ServiceLocator {
  static ServiceLocator? _instance;
  static ServiceLocator get instance => _instance ??= ServiceLocator._();

  ServiceLocator._();

  ApiClient? _apiClient;
  ITerminalService? _terminalService;
  IProjectManagerService? _projectManager;
  IConfigService? _configService;
  IGitService? _gitService;

  bool _initialized = false;
  String _backendUrl = 'http://localhost:8080';

  /// Initialize the service locator
  Future<void> initialize({String? backendUrl}) async {
    if (_initialized) return;

    if (backendUrl != null) {
      _backendUrl = backendUrl;
    }

    if (kIsWeb) {
      await _initializeWebServices();
    } else {
      await _initializeDesktopServices();
    }

    _initialized = true;
  }

  /// Initialize web services using API client
  Future<void> _initializeWebServices() async {
    _apiClient = ApiClient(baseUrl: _backendUrl);

    // Check if backend server is running
    final isServerRunning = await _apiClient!.isServerRunning();
    if (!isServerRunning) {
      throw ServiceLocatorException(
        'Backend server is not running. Please start the server at $_backendUrl',
      );
    }

    _terminalService = TerminalServiceWeb(_apiClient!);
    _projectManager = ProjectManagerWeb(_apiClient!);
    _configService = ConfigServiceWeb(_apiClient!);
    _gitService = GitServiceWeb(_apiClient!);
  }

  /// Initialize desktop services using dart:io
  /// Note: On desktop, we still use the web services through the local backend
  /// This ensures consistent behavior and allows the app to work as a PWA
  Future<void> _initializeDesktopServices() async {
    // For now, we use the same web services on desktop
    // The backend server handles all dart:io operations
    await _initializeWebServices();
  }

  /// Get the API client
  ApiClient get apiClient {
    _ensureInitialized();
    return _apiClient!;
  }

  /// Get the terminal service
  ITerminalService get terminalService {
    _ensureInitialized();
    return _terminalService!;
  }

  /// Get the project manager
  IProjectManagerService get projectManager {
    _ensureInitialized();
    return _projectManager!;
  }

  /// Get the config service
  IConfigService get configService {
    _ensureInitialized();
    return _configService!;
  }

  /// Get the git service
  IGitService get gitService {
    _ensureInitialized();
    return _gitService!;
  }

  void _ensureInitialized() {
    if (!_initialized) {
      throw ServiceLocatorException(
        'ServiceLocator not initialized. Call initialize() first.',
      );
    }
  }

  /// Check if the backend server is reachable
  Future<bool> isBackendAvailable() async {
    if (_apiClient == null) {
      final tempClient = ApiClient(baseUrl: _backendUrl);
      final result = await tempClient.isServerRunning();
      tempClient.dispose();
      return result;
    }
    return _apiClient!.isServerRunning();
  }

  /// Update backend URL and reinitialize
  Future<void> updateBackendUrl(String url) async {
    _backendUrl = url;
    _initialized = false;
    dispose();
    await initialize(backendUrl: url);
  }

  /// Dispose all services
  void dispose() {
    _apiClient?.dispose();
    _terminalService?.dispose();
    _apiClient = null;
    _terminalService = null;
    _projectManager = null;
    _configService = null;
    _gitService = null;
    _initialized = false;
  }

  /// Reset the singleton instance (for testing)
  static void reset() {
    _instance?.dispose();
    _instance = null;
  }
}

/// Exception thrown when service locator encounters an error
class ServiceLocatorException implements Exception {
  final String message;

  ServiceLocatorException(this.message);

  @override
  String toString() => 'ServiceLocatorException: $message';
}
