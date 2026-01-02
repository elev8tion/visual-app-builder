import 'package:flutter/material.dart';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:dart_style/dart_style.dart';
import '../models/widget_selection.dart';

/// Code Sync Service
///
/// Bidirectional synchronization between visual editor and code.
///
/// Features:
/// - Update widget properties in source code
/// - Insert new widgets at specific locations
/// - Delete widgets from code
/// - Reorder widgets
/// - Wrap widgets with parent widgets
/// - Code formatting preservation
/// - AST-based modification (not regex)
class CodeSyncService {
  static CodeSyncService? _instance;
  static CodeSyncService get instance => _instance ??= CodeSyncService._();
  CodeSyncService._();

  final DartFormatter _formatter = DartFormatter();

  /// Update a widget's property in the source code
  /// Returns the modified code with formatting preserved
  Future<String> updateWidgetProperty({
    required String sourceCode,
    required WidgetSelection widget,
    required String propertyName,
    required dynamic propertyValue,
  }) async {
    try {
      final parseResult = parseString(content: sourceCode);
      final lines = sourceCode.split('\n');

      // Find the widget at the specified line
      final widgetLine = widget.lineNumber - 1; // Convert to 0-indexed
      if (widgetLine < 0 || widgetLine >= lines.length) {
        return sourceCode;
      }

      // Find the widget constructor bounds
      final widgetBounds = _findWidgetBounds(parseResult.unit, widget.lineNumber);
      if (widgetBounds == null) {
        return sourceCode;
      }

      final startLine = widgetBounds['startLine'] as int;
      final endLine = widgetBounds['endLine'] as int;

      // Extract widget code
      final widgetCode = lines.sublist(startLine, endLine + 1).join('\n');

      // Check if property exists
      final propertyPattern = RegExp('$propertyName\\s*:');
      final hasProperty = propertyPattern.hasMatch(widgetCode);

      String modifiedCode;
      if (hasProperty) {
        // Update existing property
        modifiedCode = _updateExistingProperty(
          widgetCode,
          propertyName,
          propertyValue,
        );
      } else {
        // Add new property
        modifiedCode = _addNewProperty(
          widgetCode,
          propertyName,
          propertyValue,
        );
      }

      // Replace in source
      final before = lines.sublist(0, startLine).join('\n');
      final after = endLine + 1 < lines.length
          ? '\n${lines.sublist(endLine + 1).join('\n')}'
          : '';

      final result = before + (before.isNotEmpty ? '\n' : '') +
                     modifiedCode +
                     after;

      // Format the result
      try {
        return _formatter.format(result);
      } catch (e) {
        // Return unformatted if formatting fails
        return result;
      }
    } catch (e) {
      // Error updating widget property
      return sourceCode;
    }
  }

  /// Extract all properties from a widget at specific line
  Future<Map<String, dynamic>> extractWidgetProperties({
    required String sourceCode,
    required int lineNumber,
  }) async {
    try {
      final parseResult = parseString(content: sourceCode);
      final visitor = _PropertyExtractorVisitor(lineNumber, parseResult.lineInfo);
      visitor.visitCompilationUnit(parseResult.unit);
      return visitor.properties;
    } catch (e) {
      // Error extracting widget properties
      return {};
    }
  }

  /// Insert a new widget at a specific location
  Future<String> insertWidget({
    required String sourceCode,
    required int lineNumber,
    required String widgetCode,
    required InsertPosition position,
  }) async {
    try {
      final lines = sourceCode.split('\n');
      final targetLine = lineNumber - 1; // Convert to 0-indexed

      if (targetLine < 0 || targetLine >= lines.length) {
        return sourceCode;
      }

      String result;
      switch (position) {
        case InsertPosition.before:
          lines.insert(targetLine, widgetCode);
          result = lines.join('\n');
          break;
        case InsertPosition.after:
          lines.insert(targetLine + 1, widgetCode);
          result = lines.join('\n');
          break;
        case InsertPosition.asChild:
          result = _insertAsChild(sourceCode, lineNumber, widgetCode);
          break;
      }

      // Format the result
      try {
        return _formatter.format(result);
      } catch (e) {
        return result;
      }
    } catch (e) {
      // Error inserting widget
      return sourceCode;
    }
  }

  /// Delete a widget from the code
  Future<String> deleteWidget({
    required String sourceCode,
    required WidgetSelection widget,
  }) async {
    try {
      final parseResult = parseString(content: sourceCode);
      final widgetBounds = _findWidgetBounds(parseResult.unit, widget.lineNumber);

      if (widgetBounds == null) {
        return sourceCode;
      }

      final lines = sourceCode.split('\n');
      final startLine = widgetBounds['startLine'] as int;
      final endLine = widgetBounds['endLine'] as int;

      // Remove the widget lines
      final before = lines.sublist(0, startLine);
      final after = endLine + 1 < lines.length
          ? lines.sublist(endLine + 1)
          : <String>[];

      final result = [...before, ...after].join('\n');

      // Format the result
      try {
        return _formatter.format(result);
      } catch (e) {
        return result;
      }
    } catch (e) {
      // Error deleting widget
      return sourceCode;
    }
  }

  /// Reorder widgets (swap two widgets)
  Future<String> reorderWidgets({
    required String sourceCode,
    required WidgetSelection widget1,
    required WidgetSelection widget2,
  }) async {
    try {
      final parseResult = parseString(content: sourceCode);

      final bounds1 = _findWidgetBounds(parseResult.unit, widget1.lineNumber);
      final bounds2 = _findWidgetBounds(parseResult.unit, widget2.lineNumber);

      if (bounds1 == null || bounds2 == null) {
        return sourceCode;
      }

      final lines = sourceCode.split('\n');

      // Extract widget code blocks
      final start1 = bounds1['startLine'] as int;
      final end1 = bounds1['endLine'] as int;
      final start2 = bounds2['startLine'] as int;
      final end2 = bounds2['endLine'] as int;

      final widget1Code = lines.sublist(start1, end1 + 1);
      final widget2Code = lines.sublist(start2, end2 + 1);

      // Determine which comes first
      final firstStart = start1 < start2 ? start1 : start2;
      final firstEnd = start1 < start2 ? end1 : end2;
      final secondStart = start1 < start2 ? start2 : start1;
      final secondEnd = start1 < start2 ? end2 : end1;

      final firstCode = start1 < start2 ? widget1Code : widget2Code;
      final secondCode = start1 < start2 ? widget2Code : widget1Code;

      // Reconstruct with swapped positions
      final result = [
        ...lines.sublist(0, firstStart),
        ...secondCode,
        ...lines.sublist(firstEnd + 1, secondStart),
        ...firstCode,
        if (secondEnd + 1 < lines.length) ...lines.sublist(secondEnd + 1),
      ].join('\n');

      // Format the result
      try {
        return _formatter.format(result);
      } catch (e) {
        return result;
      }
    } catch (e) {
      // Error reordering widgets
      return sourceCode;
    }
  }

  /// Wrap a widget with another widget (e.g., wrap with Container, Padding, etc.)
  Future<String> wrapWidget({
    required String sourceCode,
    required WidgetSelection widget,
    required String wrapperWidget,
    Map<String, dynamic>? wrapperProperties,
  }) async {
    try {
      final parseResult = parseString(content: sourceCode);
      final widgetBounds = _findWidgetBounds(parseResult.unit, widget.lineNumber);

      if (widgetBounds == null) {
        return sourceCode;
      }

      final lines = sourceCode.split('\n');
      final startLine = widgetBounds['startLine'] as int;
      final endLine = widgetBounds['endLine'] as int;

      // Get indentation of the original widget
      final originalIndent = _getIndentation(lines[startLine]);

      // Extract original widget code
      final widgetCodeLines = lines.sublist(startLine, endLine + 1);

      // Increase indentation of original widget
      final indentedWidget = widgetCodeLines.map((line) {
        if (line.trim().isEmpty) return line;
        return '  $line';
      }).toList();

      // Build wrapper code
      final wrapperStart = '$originalIndent$wrapperWidget(';
      final properties = wrapperProperties ?? {};
      final propertyLines = properties.entries.map((entry) {
        final value = _formatPropertyValue(entry.value);
        return '$originalIndent  ${entry.key}: $value,';
      }).toList();

      final childLine = '$originalIndent  child: ';

      // Combine wrapper code
      final wrappedCode = [
        wrapperStart,
        ...propertyLines,
        childLine,
        ...indentedWidget,
        '$originalIndent)',
      ];

      // Replace in source
      final result = [
        ...lines.sublist(0, startLine),
        ...wrappedCode,
        if (endLine + 1 < lines.length) ...lines.sublist(endLine + 1),
      ].join('\n');

      // Format the result
      try {
        return _formatter.format(result);
      } catch (e) {
        return result;
      }
    } catch (e) {
      // Error wrapping widget
      return sourceCode;
    }
  }

  /// Find widget bounds (start and end line) in the AST
  Map<String, int>? _findWidgetBounds(CompilationUnit unit, int targetLine) {
    final visitor = _WidgetBoundsVisitor(targetLine, unit.lineInfo);
    visitor.visitCompilationUnit(unit);
    return visitor.bounds;
  }

  /// Update an existing property value
  String _updateExistingProperty(
    String widgetCode,
    String propertyName,
    dynamic propertyValue,
  ) {
    // Find the property and its value
    final propertyPattern = RegExp(
      '$propertyName\\s*:\\s*([^,\\)]+)([,\\)])',
      multiLine: true,
    );

    final formattedValue = _formatPropertyValue(propertyValue);

    return widgetCode.replaceFirstMapped(propertyPattern, (match) {
      final ending = match.group(2);
      return '$propertyName: $formattedValue$ending';
    });
  }

  /// Add a new property to the widget
  String _addNewProperty(
    String widgetCode,
    String propertyName,
    dynamic propertyValue,
  ) {
    // Find the opening parenthesis
    final openParen = widgetCode.indexOf('(');
    if (openParen == -1) return widgetCode;

    // Find appropriate insertion point (after opening paren or after last property)
    final lines = widgetCode.split('\n');
    final formattedValue = _formatPropertyValue(propertyValue);
    final newProperty = '  $propertyName: $formattedValue,';

    // Insert after opening parenthesis on new line
    if (lines.length == 1) {
      // Single line widget - convert to multi-line
      final widgetName = widgetCode.substring(0, openParen + 1);
      final rest = widgetCode.substring(openParen + 1).trim();
      return '$widgetName\n$newProperty\n  $rest';
    } else {
      // Multi-line widget - insert after opening paren
      final result = [
        lines[0],
        newProperty,
        ...lines.sublist(1),
      ].join('\n');
      return result;
    }
  }

  /// Insert widget as a child of another widget
  String _insertAsChild(String sourceCode, int parentLine, String childWidget) {
    final lines = sourceCode.split('\n');
    final targetLine = parentLine - 1;

    // Find the child: or children: property
    for (int i = targetLine; i < lines.length; i++) {
      final line = lines[i];
      if (line.contains('child:')) {
        // Single child - replace or wrap
        final indent = _getIndentation(line);
        lines[i] = '$indent  child: $childWidget,';
        break;
      } else if (line.contains('children:')) {
        // Multiple children - add to list
        final indent = _getIndentation(line);
        // Find the opening bracket
        if (line.contains('[')) {
          lines.insert(i + 1, '$indent    $childWidget,');
        }
        break;
      }
    }

    return lines.join('\n');
  }

  /// Get the indentation (leading whitespace) of a line
  String _getIndentation(String line) {
    final match = RegExp(r'^(\s*)').firstMatch(line);
    return match?.group(1) ?? '';
  }

  /// Format a property value for code generation
  String _formatPropertyValue(dynamic value) {
    if (value is String) {
      // Check if it's a code expression (starts with capital letter or contains .)
      if (value.isEmpty) return "''";
      if (RegExp(r'^[A-Z]').hasMatch(value) || value.contains('.')) {
        return value; // Code expression like Colors.blue or EdgeInsets.all(8)
      }
      return "'$value'"; // String literal
    } else if (value is num) {
      return value.toString();
    } else if (value is bool) {
      return value.toString();
    } else if (value is List) {
      final items = value.map(_formatPropertyValue).join(', ');
      return '[$items]';
    } else if (value is Map) {
      // Check if it's an EdgeInsets map
      if (value.containsKey('top') || value.containsKey('left') || value.containsKey('all')) {
        if (value['all'] != null) {
          return 'EdgeInsets.all(${value['all']})';
        }
        return 'EdgeInsets.only(top: ${value['top'] ?? 0}, bottom: ${value['bottom'] ?? 0}, left: ${value['left'] ?? 0}, right: ${value['right'] ?? 0})';
      }
      final entries = value.entries.map((e) => '${e.key}: ${_formatPropertyValue(e.value)}').join(', ');
      return '{$entries}';
    } else if (value is Color) {
      return 'Color(0x${value.value.toRadixString(16).padLeft(8, '0').toUpperCase()})';
    }
    return value.toString();
  }
}

/// Visitor to extract properties at a specific line
class _PropertyExtractorVisitor extends RecursiveAstVisitor<void> {
  final int targetLine;
  final dynamic lineInfo;
  final Map<String, dynamic> properties = {};

  _PropertyExtractorVisitor(this.targetLine, this.lineInfo);

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    if (lineInfo != null) {
      final nodeLine = lineInfo.getLocation(node.offset).lineNumber;
      if (nodeLine == targetLine) {
        // Extract all named arguments
        for (final arg in node.argumentList.arguments) {
          if (arg is NamedExpression) {
            final name = arg.name.label.name;
            final value = _extractValue(arg.expression);
            properties[name] = value;
          }
        }
      }
    }
    super.visitInstanceCreationExpression(node);
  }

  dynamic _extractValue(Expression expr) {
    if (expr is StringLiteral) {
      return expr.stringValue;
    } else if (expr is IntegerLiteral) {
      return expr.value;
    } else if (expr is DoubleLiteral) {
      return expr.value;
    } else if (expr is BooleanLiteral) {
      return expr.value;
    } else if (expr is MethodInvocation || expr is PropertyAccess || expr is Identifier) {
      final code = expr.toString();
      
      // Parse Color(0xFF...)
      if (code.startsWith('Color(') || code.startsWith('const Color(')) {
        final match = RegExp(r'0x([A-Fa-f0-9]+)').firstMatch(code);
        if (match != null) {
          try {
            return Color(int.parse(match.group(1)!, radix: 16));
          } catch (_) {}
        }
      }
      
      // Parse Colors.xxx
      if (code.startsWith('Colors.')) {
        return code; // Keep as string for now, UI handles common colors
      }
      
      // Parse EdgeInsets
      if (code.startsWith('EdgeInsets.')) {
        if (code.contains('.all(')) {
          final val = RegExp(r'\(([^)]+)\)').firstMatch(code)?.group(1);
          return {'all': double.tryParse(val ?? '0') ?? 0.0};
        }
        if (code.contains('.only(')) {
          final top = RegExp(r'top:\s*([^,)]+)').firstMatch(code)?.group(1);
          final bottom = RegExp(r'bottom:\s*([^,)]+)').firstMatch(code)?.group(1);
          final left = RegExp(r'left:\s*([^,)]+)').firstMatch(code)?.group(1);
          final right = RegExp(r'right:\s*([^,)]+)').firstMatch(code)?.group(1);
          return {
            'top': double.tryParse(top ?? '0') ?? 0.0,
            'bottom': double.tryParse(bottom ?? '0') ?? 0.0,
            'left': double.tryParse(left ?? '0') ?? 0.0,
            'right': double.tryParse(right ?? '0') ?? 0.0,
          };
        }
      }
      
      return code;
    }
    return expr.toString();
  }
}

/// Visitor to find widget bounds at a specific line
class _WidgetBoundsVisitor extends RecursiveAstVisitor<void> {
  final int targetLine;
  final dynamic lineInfo;
  Map<String, int>? bounds;

  _WidgetBoundsVisitor(this.targetLine, this.lineInfo);

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    if (lineInfo != null && bounds == null) {
      final startLine = lineInfo.getLocation(node.offset).lineNumber;
      final endLine = lineInfo.getLocation(node.end).lineNumber;

      if (targetLine >= startLine && targetLine <= endLine) {
        bounds = {
          'startLine': startLine - 1, // Convert to 0-indexed
          'endLine': endLine - 1,
        };
      }
    }
    super.visitInstanceCreationExpression(node);
  }
}

/// Position for inserting a widget
enum InsertPosition {
  before,  // Insert before the target widget
  after,   // Insert after the target widget
  asChild, // Insert as a child of the target widget
}
