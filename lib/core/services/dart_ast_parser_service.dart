import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import '../models/widget_selection.dart';

/// Dart AST Parser Service
///
/// Uses Dart's official analyzer package to extract widget trees from Flutter code.
/// This provides accurate widget hierarchy, line numbers, and property extraction.
class DartAstParserService {
  static DartAstParserService? _instance;
  static DartAstParserService get instance => _instance ??= DartAstParserService._();
  DartAstParserService._();

  /// Parse Dart file and extract complete widget tree
  Future<WidgetTreeNode?> parseWidgetTree(String dartCode, String filePath) async {
    try {
      final parseResult = parseString(content: dartCode, path: filePath);

      if (parseResult.errors.isNotEmpty) {
        for (final error in parseResult.errors) {
          print('Parse error in $filePath: ${error.message}');
        }
      }

      final compilationUnit = parseResult.unit;
      final visitor = _WidgetExtractorVisitor(dartCode, parseResult.lineInfo);
      visitor.visitCompilationUnit(compilationUnit);

      if (visitor.widgets.isEmpty) {
        return WidgetTreeNode(
          name: 'Root',
          type: WidgetType.root,
          line: 0,
          properties: {},
          children: [],
        );
      }

      final rootWidgets = _buildWidgetHierarchy(visitor.widgets);

      return WidgetTreeNode(
        name: 'Root',
        type: WidgetType.root,
        line: 0,
        properties: {'filePath': filePath},
        children: rootWidgets,
      );
    } catch (e) {
      print('Error parsing widget tree: $e');
      return WidgetTreeNode(
        name: 'Root',
        type: WidgetType.root,
        line: 0,
        properties: {'error': e.toString()},
        children: [],
      );
    }
  }

  /// Find widget at specific line number
  WidgetSelection? findWidgetAtLine(String dartCode, int lineNumber, String filePath) {
    try {
      final parseResult = parseString(content: dartCode);
      final visitor = _WidgetExtractorVisitor(dartCode, parseResult.lineInfo);
      visitor.visitCompilationUnit(parseResult.unit);

      for (final widget in visitor.widgets) {
        if (widget.line == lineNumber) {
          return WidgetSelection(
            widgetType: widget.name,
            widgetId: '${widget.name}_${widget.line}',
            filePath: filePath,
            lineNumber: widget.line,
            endLineNumber: widget.endLine,
            properties: widget.properties,
            sourceCode: widget.sourceCode ?? '',
          );
        }

        if (widget.endLine != null &&
            lineNumber >= widget.line &&
            lineNumber <= widget.endLine!) {
          return WidgetSelection(
            widgetType: widget.name,
            widgetId: '${widget.name}_${widget.line}',
            filePath: filePath,
            lineNumber: widget.line,
            endLineNumber: widget.endLine,
            properties: widget.properties,
            sourceCode: widget.sourceCode ?? '',
          );
        }
      }

      return null;
    } catch (e) {
      print('Error finding widget at line $lineNumber: $e');
      return null;
    }
  }

  /// Extract all properties from a widget constructor
  Map<String, dynamic> extractWidgetProperties(String dartCode, WidgetSelection widget) {
    try {
      final parseResult = parseString(content: dartCode);
      final visitor = _WidgetExtractorVisitor(dartCode, parseResult.lineInfo);
      visitor.visitCompilationUnit(parseResult.unit);

      for (final w in visitor.widgets) {
        if (w.line == widget.lineNumber && w.name == widget.widgetType) {
          return w.properties;
        }
      }

      return widget.properties;
    } catch (e) {
      print('Error extracting properties: $e');
      return widget.properties;
    }
  }

  /// Get widget type classification
  WidgetType classifyWidget(String widgetName) {
    const layoutWidgets = {
      'Container', 'Row', 'Column', 'Stack', 'Positioned', 'Align', 'Center',
      'Padding', 'SizedBox', 'Expanded', 'Flexible', 'Wrap', 'ListView',
      'GridView', 'CustomScrollView', 'SingleChildScrollView', 'Card',
      'Scaffold', 'AppBar', 'Drawer', 'BottomNavigationBar', 'TabBar',
    };

    const inputWidgets = {
      'TextField', 'TextFormField', 'Checkbox', 'Radio', 'Switch', 'Slider',
      'DropdownButton', 'DropdownButtonFormField', 'DatePicker', 'TimePicker',
      'Form', 'FormField', 'RawKeyboardListener', 'GestureDetector',
      'InkWell', 'ElevatedButton', 'TextButton', 'OutlinedButton', 'IconButton',
      'FloatingActionButton',
    };

    const displayWidgets = {
      'Text', 'RichText', 'Icon', 'Image', 'CircleAvatar', 'Chip', 'Divider',
      'LinearProgressIndicator', 'CircularProgressIndicator', 'Placeholder',
      'Spacer', 'Opacity', 'AnimatedOpacity', 'FadeTransition',
    };

    const appWidgets = {
      'MaterialApp', 'CupertinoApp', 'WidgetsApp',
    };

    if (appWidgets.contains(widgetName)) {
      return WidgetType.app;
    } else if (layoutWidgets.contains(widgetName)) {
      return WidgetType.layout;
    } else if (inputWidgets.contains(widgetName)) {
      return WidgetType.input;
    } else if (displayWidgets.contains(widgetName)) {
      return WidgetType.display;
    } else {
      return WidgetType.component;
    }
  }

  /// Build hierarchical widget structure from flat list
  List<WidgetTreeNode> _buildWidgetHierarchy(List<_WidgetInfo> widgets) {
    if (widgets.isEmpty) return [];

    final sortedWidgets = List<_WidgetInfo>.from(widgets)
      ..sort((a, b) {
        final lineCompare = a.line.compareTo(b.line);
        if (lineCompare != 0) return lineCompare;
        return (b.nestingLevel ?? 0).compareTo(a.nestingLevel ?? 0);
      });

    final rootWidgets = <WidgetTreeNode>[];
    final widgetStack = <_WidgetInfo>[];

    for (final widget in sortedWidgets) {
      final node = WidgetTreeNode(
        name: widget.name,
        type: classifyWidget(widget.name),
        line: widget.line,
        endLine: widget.endLine,
        properties: widget.properties,
        sourceCode: widget.sourceCode,
        nestingLevel: widget.nestingLevel,
        children: [],
      );

      while (widgetStack.isNotEmpty) {
        final parent = widgetStack.last;
        final parentNesting = parent.nestingLevel ?? 0;
        final currentNesting = widget.nestingLevel ?? 0;

        if (currentNesting > parentNesting &&
            widget.line > parent.line &&
            (parent.endLine == null || widget.line <= parent.endLine!)) {
          parent.childNodes.add(node);
          break;
        } else {
          widgetStack.removeLast();
        }
      }

      if (widgetStack.isEmpty) {
        rootWidgets.add(node);
      }

      widgetStack.add(widget..childNodes.add(node));
    }

    return rootWidgets;
  }
}

/// Internal visitor class to extract widgets from AST
class _WidgetExtractorVisitor extends RecursiveAstVisitor<void> {
  final String sourceCode;
  final dynamic lineInfo;
  final List<_WidgetInfo> widgets = [];
  int _currentNestingLevel = 0;

  _WidgetExtractorVisitor(this.sourceCode, this.lineInfo);

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    final typeName = node.constructorName.type;
    String widgetName = '';

    try {
      widgetName = typeName.toString().split('<').first.trim();
    } catch (e) {
      return;
    }

    if (widgetName.isNotEmpty && widgetName[0] == widgetName[0].toUpperCase()) {
      if (lineInfo != null) {
        final startLine = lineInfo.getLocation(node.offset).lineNumber;
        final endLine = lineInfo.getLocation(node.end).lineNumber;

        final properties = _extractProperties(node);
        final sourceSnippet = _getSourceSnippet(node.offset, node.end);

        final widgetInfo = _WidgetInfo(
          name: widgetName,
          line: startLine,
          endLine: endLine,
          properties: properties,
          nestingLevel: _currentNestingLevel,
          sourceCode: sourceSnippet,
        );

        widgets.add(widgetInfo);
      }
    }

    _currentNestingLevel++;
    super.visitInstanceCreationExpression(node);
    _currentNestingLevel--;
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    final methodName = node.methodName.name;

    if (node.target == null &&
        methodName.isNotEmpty &&
        methodName[0] == methodName[0].toUpperCase()) {
      if (lineInfo != null) {
        final startLine = lineInfo.getLocation(node.offset).lineNumber;
        final endLine = lineInfo.getLocation(node.end).lineNumber;

        final properties = _extractPropertiesFromMethodInvocation(node);
        final sourceSnippet = _getSourceSnippet(node.offset, node.end);

        widgets.add(_WidgetInfo(
          name: methodName,
          line: startLine,
          endLine: endLine,
          properties: properties,
          nestingLevel: _currentNestingLevel,
          sourceCode: sourceSnippet,
        ));
      }
    } else if (node.target != null) {
      final target = node.target;
      final targetStr = target.toString();

      if (targetStr.isNotEmpty && targetStr[0] == targetStr[0].toUpperCase()) {
        final widgetName = '$targetStr.${node.methodName.name}';
        if (lineInfo != null) {
          final startLine = lineInfo.getLocation(node.offset).lineNumber;
          final endLine = lineInfo.getLocation(node.end).lineNumber;

          final properties = _extractPropertiesFromMethodInvocation(node);
          final sourceSnippet = _getSourceSnippet(node.offset, node.end);

          widgets.add(_WidgetInfo(
            name: widgetName,
            line: startLine,
            endLine: endLine,
            properties: properties,
            nestingLevel: _currentNestingLevel,
            sourceCode: sourceSnippet,
          ));
        }
      }
    }

    super.visitMethodInvocation(node);
  }

  Map<String, dynamic> _extractProperties(InstanceCreationExpression node) {
    final properties = <String, dynamic>{};

    final args = node.argumentList.arguments;
    for (final arg in args) {
      if (arg is NamedExpression) {
        final name = arg.name.label.name;
        final value = _extractValue(arg.expression);
        properties[name] = value;
      }
    }

    return properties;
  }

  Map<String, dynamic> _extractPropertiesFromMethodInvocation(MethodInvocation node) {
    final properties = <String, dynamic>{};

    final args = node.argumentList.arguments;
    for (final arg in args) {
      if (arg is NamedExpression) {
        final name = arg.name.label.name;
        final value = _extractValue(arg.expression);
        properties[name] = value;
      }
    }

    return properties;
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
    } else if (expr is ListLiteral) {
      return expr.elements.map((e) {
        if (e is Expression) return _extractValue(e);
        return e.toString();
      }).toList();
    } else if (expr is PrefixedIdentifier) {
      return '${expr.prefix}.${expr.identifier}';
    } else if (expr is PropertyAccess) {
      return '${expr.target}.${expr.propertyName}';
    } else if (expr is MethodInvocation) {
      final target = expr.target;
      final method = expr.methodName.name;
      final args = expr.argumentList.arguments.map((a) => _extractValue(a)).join(', ');
      return target != null ? '$target.$method($args)' : '$method($args)';
    } else if (expr is InstanceCreationExpression) {
      final name = expr.constructorName.type.toString().split('<').first;
      return '<$name>';
    } else if (expr is FunctionExpression) {
      return '<Function>';
    } else if (expr is ConditionalExpression) {
      return '<Conditional>';
    }

    return expr.toString();
  }

  String _getSourceSnippet(int start, int end) {
    try {
      if (start >= 0 && end <= sourceCode.length) {
        final snippet = sourceCode.substring(start, end);
        return snippet.length > 200 ? '${snippet.substring(0, 200)}...' : snippet;
      }
    } catch (e) {
      // Ignore
    }
    return '';
  }
}

/// Internal widget information container
class _WidgetInfo {
  final String name;
  final int line;
  final int? endLine;
  final Map<String, dynamic> properties;
  final int? nestingLevel;
  final String? sourceCode;
  final List<WidgetTreeNode> childNodes = [];

  _WidgetInfo({
    required this.name,
    required this.line,
    this.endLine,
    required this.properties,
    this.nestingLevel,
    this.sourceCode,
  });

  @override
  String toString() => 'WidgetInfo($name at line $line, nesting: $nestingLevel)';
}
