
import 'package:flutter/material.dart';

class ThemeDataModel {
  final Map<String, Color> colors;
  final Map<String, TextStyle> textStyles;

  const ThemeDataModel({
    this.colors = const {},
    this.textStyles = const {},
  });
}

class ThemeService {
  static final ThemeService _instance = ThemeService._internal();
  factory ThemeService() => _instance;
  ThemeService._internal();

  ThemeDataModel _currentTheme = const ThemeDataModel();
  ThemeDataModel get currentTheme => _currentTheme;

  /// Parse the theme file content to extract colors and text styles
  /// For this MVP we will do simple regex parsing of a specific format.
  /// 
  /// Expected format in lib/core/theme/app_theme.dart:
  /// static const Color primaryColor = Color(0xFF6200EE);
  /// static const TextStyle headline1 = TextStyle(...);
  Future<void> parseThemeFile(String content) async {
    final Map<String, Color> colors = {};
    final Map<String, TextStyle> textStyles = {};

    // Parse Colors
    // Regex for: static const Color colorName = Color(0xFF...);
    final colorRegex = RegExp(r'static const Color (\w+) = Color\((0x[A-Fa-f0-9]+)\);');
    for (final match in colorRegex.allMatches(content)) {
      final name = match.group(1);
      final valueStr = match.group(2);
      if (name != null && valueStr != null) {
        try {
          final value = int.parse(valueStr);
          colors[name] = Color(value);
        } catch (e) {
          debugPrint('Error parsing color $name: $e');
        }
      }
    }

    // Parse TextStyles (simplified)
    // We'll just capture the names for now to show in dropdowns, simpler than full AST parsing for this MVP
    // Regex for: static const TextStyle styleName = ...
    final styleRegex = RegExp(r'static const TextStyle (\w+)\s*=');
    for (final match in styleRegex.allMatches(content)) {
      final name = match.group(1);
      if (name != null) {
        // Just placeholder styles with the correct name
        textStyles[name] = const TextStyle(); 
      }
    }

    _currentTheme = ThemeDataModel(colors: colors, textStyles: textStyles);
    debugPrint('Parsed Theme: ${colors.length} colors, ${textStyles.length} styles');
  }

  // Helper to find closest theme color name for a given Color
  String? findThemeColorName(Color color) {
    for (final entry in _currentTheme.colors.entries) {
      if (entry.value.value == color.value) {
        return entry.key;
      }
    }
    return null;
  }
}
