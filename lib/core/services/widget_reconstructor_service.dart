import 'package:flutter/material.dart';
import '../models/widget_selection.dart';

/// Widget Reconstructor Service
///
/// Converts WidgetTreeNode metadata into actual Flutter widgets
/// for real-time preview without screenshots or mocks.
class WidgetReconstructorService {
  static final WidgetReconstructorService _instance = WidgetReconstructorService._();
  static WidgetReconstructorService get instance => _instance;
  WidgetReconstructorService._();

  /// Reconstruct widget tree into live Flutter widgets
  Widget reconstructWidget(WidgetTreeNode node, {ThemeData? theme}) {
    theme ??= ThemeData.dark();

    switch (node.name) {
      case 'Root':
        return _buildRoot(node, theme);
      case 'MaterialApp':
      case 'MaterialApp.router':
        return _buildMaterialApp(node, theme);
      case 'CupertinoApp':
        return _buildMaterialApp(node, theme); // Use MaterialApp builder
      case 'Scaffold':
        return _buildScaffold(node, theme);
      case 'AppBar':
        return _buildAppBar(node, theme);
      case 'Container':
        return _buildContainer(node, theme);
      case 'Column':
        return _buildColumn(node, theme);
      case 'Row':
        return _buildRow(node, theme);
      case 'Text':
        return _buildText(node, theme);
      case 'Card':
        return _buildCard(node, theme);
      case 'ListView':
        return _buildListView(node, theme);
      case 'GridView':
        return _buildGridView(node, theme);
      case 'Stack':
        return _buildStack(node, theme);
      case 'Center':
        return _buildCenter(node, theme);
      case 'Padding':
        return _buildPadding(node, theme);
      case 'SizedBox':
        return _buildSizedBox(node, theme);
      case 'Expanded':
        return _buildExpanded(node, theme);
      case 'Flexible':
        return _buildFlexible(node, theme);
      case 'Align':
        return _buildAlign(node, theme);
      case 'ElevatedButton':
      case 'TextButton':
      case 'OutlinedButton':
        return _buildButton(node, theme);
      case 'TextField':
        return _buildTextField(node, theme);
      case 'Image':
        return _buildImage(node, theme);
      case 'Icon':
        return _buildIcon(node, theme);
      case 'Divider':
        return _buildDivider(node, theme);
      case 'CircularProgressIndicator':
        return _buildProgressIndicator(node, theme);
      case 'FloatingActionButton':
        return _buildFAB(node, theme);
      case 'ListTile':
        return _buildListTile(node, theme);
      case 'SafeArea':
        return _buildSafeArea(node, theme);
      case 'SingleChildScrollView':
        return _buildSingleChildScrollView(node, theme);
      case 'GestureDetector':
      case 'InkWell':
        return _buildGestureDetector(node, theme);
      // Wrapper widgets - just pass through to children
      case 'ProviderScope':
      case 'MultiProvider':
      case 'Provider':
      case 'BlocProvider':
      case 'RepositoryProvider':
      case 'Consumer':
      case 'Builder':
      case 'LayoutBuilder':
        return _buildPassThroughWidget(node, theme);
      default:
        return _buildUnknownWidget(node, theme);
    }
  }

  // Root builder
  Widget _buildRoot(WidgetTreeNode node, ThemeData theme) {
    if (node.children.isEmpty) {
      return Container(
        color: theme.scaffoldBackgroundColor,
        child: Center(
          child: Text(
            'No widgets to preview',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ),
      );
    }

    if (node.children.length == 1) {
      return reconstructWidget(node.children.first, theme: theme);
    }

    return Container(
      color: theme.scaffoldBackgroundColor,
      child: Column(
        children: node.children.map((child) {
          return Expanded(
            child: reconstructWidget(child, theme: theme),
          );
        }).toList(),
      ),
    );
  }

  // MaterialApp builder
  Widget _buildMaterialApp(WidgetTreeNode node, ThemeData theme) {
    final title = node.properties['title'] as String? ?? 'Flutter App';

    Widget? home;
    for (final child in node.children) {
      if (child.parameterName == 'home') {
        home = reconstructWidget(child, theme: theme);
        break;
      }
    }

    // Fallback if no explicit 'home' parameter found
    if (home == null && node.children.isNotEmpty) {
      home = reconstructWidget(node.children.first, theme: theme);
    }

    return MaterialApp(
      title: title,
      theme: theme,
      debugShowCheckedModeBanner: false,
      home: home ?? Container(),
    );
  }

  // Scaffold builder
  Widget _buildScaffold(WidgetTreeNode node, ThemeData theme) {
    Widget? appBar;
    Widget? body;
    Widget? floatingActionButton;
    Widget? bottomNavigationBar;
    Widget? drawer;

    for (final child in node.children) {
      switch (child.parameterName) {
        case 'appBar':
          appBar = reconstructWidget(child, theme: theme);
          break;
        case 'body':
          body = reconstructWidget(child, theme: theme);
          break;
        case 'floatingActionButton':
          floatingActionButton = reconstructWidget(child, theme: theme);
          break;
        case 'bottomNavigationBar':
          bottomNavigationBar = reconstructWidget(child, theme: theme);
          break;
        case 'drawer':
          drawer = reconstructWidget(child, theme: theme);
          break;
        default:
          // Positional child or unrecognized parameter
          // Fallback logic for legacy/unnamed children
          if (body == null && !_isKnownScaffoldSlot(child.parameterName)) {
            body = reconstructWidget(child, theme: theme);
          }
      }
    }

    return Scaffold(
      appBar: appBar is PreferredSizeWidget ? appBar : null,
      body: body ?? Container(),
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomNavigationBar,
      drawer: drawer,
    );
  }

  bool _isKnownScaffoldSlot(String? name) {
    return name == 'appBar' ||
        name == 'body' ||
        name == 'floatingActionButton' ||
        name == 'bottomNavigationBar' ||
        name == 'drawer' ||
        name == 'endDrawer' ||
        name == 'bottomSheet';
  }

  // AppBar builder
  Widget _buildAppBar(WidgetTreeNode node, ThemeData theme) {
    final title = node.properties['title'] as String? ?? 'App';
    final bgColor = _parseColor(node.properties['backgroundColor'], theme.colorScheme.primary);

    return AppBar(
      title: Text(title),
      backgroundColor: bgColor,
      foregroundColor: theme.colorScheme.onPrimary,
    );
  }

  // Container builder
  Widget _buildContainer(WidgetTreeNode node, ThemeData theme) {
    final width = node.properties['width'] as double?;
    final height = node.properties['height'] as double?;
    final color = _parseColor(node.properties['color'], null);
    final padding = _parseEdgeInsets(node.properties['padding']);
    final margin = _parseEdgeInsets(node.properties['margin']);
    final borderRadius = node.properties['borderRadius'] as double? ?? 0;

    Widget? child;
    if (node.children.isNotEmpty) {
      child = reconstructWidget(node.children.first, theme: theme);
    }

    return Container(
      width: width,
      height: height,
      padding: padding,
      margin: margin,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: child,
    );
  }

  // Column builder
  Widget _buildColumn(WidgetTreeNode node, ThemeData theme) {
    final mainAxisAlignment = _parseMainAxisAlignment(
      node.properties['mainAxisAlignment'],
    );
    final crossAxisAlignment = _parseCrossAxisAlignment(
      node.properties['crossAxisAlignment'],
    );

    return Column(
      mainAxisAlignment: mainAxisAlignment,
      crossAxisAlignment: crossAxisAlignment,
      children: node.children
          .map((child) => reconstructWidget(child, theme: theme))
          .toList(),
    );
  }

  // Row builder
  Widget _buildRow(WidgetTreeNode node, ThemeData theme) {
    final mainAxisAlignment = _parseMainAxisAlignment(
      node.properties['mainAxisAlignment'],
    );
    final crossAxisAlignment = _parseCrossAxisAlignment(
      node.properties['crossAxisAlignment'],
    );

    return Row(
      mainAxisAlignment: mainAxisAlignment,
      crossAxisAlignment: crossAxisAlignment,
      children: node.children
          .map((child) => reconstructWidget(child, theme: theme))
          .toList(),
    );
  }

  // Text builder
  Widget _buildText(WidgetTreeNode node, ThemeData theme) {
    final data = node.properties['data'] as String? ??
                 node.properties['text'] as String? ??
                 'Text';
    final fontSize = node.properties['fontSize'] as double? ?? 14.0;
    final fontWeight = _parseFontWeight(node.properties['fontWeight']);
    final color = _parseColor(node.properties['color'], theme.colorScheme.onSurface);

    return Text(
      data,
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
      ),
    );
  }

  // Card builder
  Widget _buildCard(WidgetTreeNode node, ThemeData theme) {
    final elevation = node.properties['elevation'] as double? ?? 4.0;

    Widget? child;
    if (node.children.isNotEmpty) {
      child = reconstructWidget(node.children.first, theme: theme);
    }

    return Card(
      elevation: elevation,
      child: child,
    );
  }

  // ListView builder
  Widget _buildListView(WidgetTreeNode node, ThemeData theme) {
    final itemCount = node.properties['itemCount'] as int? ?? node.children.length;

    if (node.children.isEmpty) {
      return ListView.builder(
        itemCount: itemCount > 0 ? itemCount : 5,
        itemBuilder: (context, index) {
          return ListTile(
            leading: Icon(Icons.circle, color: theme.colorScheme.primary),
            title: Text('Item ${index + 1}'),
            subtitle: const Text('List item description'),
          );
        },
      );
    }

    return ListView(
      children: node.children
          .map((child) => reconstructWidget(child, theme: theme))
          .toList(),
    );
  }

  // GridView builder
  Widget _buildGridView(WidgetTreeNode node, ThemeData theme) {
    final crossAxisCount = node.properties['crossAxisCount'] as int? ?? 2;

    if (node.children.isEmpty) {
      return GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          childAspectRatio: 1.0,
          crossAxisSpacing: 8.0,
          mainAxisSpacing: 8.0,
        ),
        itemCount: 6,
        itemBuilder: (context, index) {
          return Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                'Item ${index + 1}',
                style: TextStyle(
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
            ),
          );
        },
      );
    }

    return GridView.count(
      crossAxisCount: crossAxisCount,
      children: node.children
          .map((child) => reconstructWidget(child, theme: theme))
          .toList(),
    );
  }

  // Stack builder
  Widget _buildStack(WidgetTreeNode node, ThemeData theme) {
    return Stack(
      children: node.children
          .map((child) => reconstructWidget(child, theme: theme))
          .toList(),
    );
  }

  // Center builder
  Widget _buildCenter(WidgetTreeNode node, ThemeData theme) {
    Widget? child;
    if (node.children.isNotEmpty) {
      child = reconstructWidget(node.children.first, theme: theme);
    }

    return Center(child: child);
  }

  // Padding builder
  Widget _buildPadding(WidgetTreeNode node, ThemeData theme) {
    final padding = _parseEdgeInsets(node.properties['padding']) ??
                   const EdgeInsets.all(16.0);

    Widget? child;
    if (node.children.isNotEmpty) {
      child = reconstructWidget(node.children.first, theme: theme);
    }

    return Padding(
      padding: padding,
      child: child ?? Container(),
    );
  }

  // SizedBox builder
  Widget _buildSizedBox(WidgetTreeNode node, ThemeData theme) {
    final width = node.properties['width'] as double?;
    final height = node.properties['height'] as double?;

    Widget? child;
    if (node.children.isNotEmpty) {
      child = reconstructWidget(node.children.first, theme: theme);
    }

    return SizedBox(
      width: width,
      height: height,
      child: child,
    );
  }

  // Expanded builder
  Widget _buildExpanded(WidgetTreeNode node, ThemeData theme) {
    final flex = node.properties['flex'] as int? ?? 1;

    Widget? child;
    if (node.children.isNotEmpty) {
      child = reconstructWidget(node.children.first, theme: theme);
    }

    return Expanded(
      flex: flex,
      child: child ?? Container(),
    );
  }

  // Flexible builder
  Widget _buildFlexible(WidgetTreeNode node, ThemeData theme) {
    final flex = node.properties['flex'] as int? ?? 1;

    Widget? child;
    if (node.children.isNotEmpty) {
      child = reconstructWidget(node.children.first, theme: theme);
    }

    return Flexible(
      flex: flex,
      child: child ?? Container(),
    );
  }

  // Align builder
  Widget _buildAlign(WidgetTreeNode node, ThemeData theme) {
    final alignment = _parseAlignment(node.properties['alignment']) ??
                     Alignment.center;

    Widget? child;
    if (node.children.isNotEmpty) {
      child = reconstructWidget(node.children.first, theme: theme);
    }

    return Align(
      alignment: alignment,
      child: child ?? Container(),
    );
  }

  // Button builder
  Widget _buildButton(WidgetTreeNode node, ThemeData theme) {
    final text = node.properties['text'] as String? ?? 'Button';

    switch (node.name) {
      case 'ElevatedButton':
        return ElevatedButton(
          onPressed: () {},
          child: Text(text),
        );
      case 'TextButton':
        return TextButton(
          onPressed: () {},
          child: Text(text),
        );
      case 'OutlinedButton':
        return OutlinedButton(
          onPressed: () {},
          child: Text(text),
        );
      default:
        return ElevatedButton(
          onPressed: () {},
          child: Text(text),
        );
    }
  }

  // TextField builder
  Widget _buildTextField(WidgetTreeNode node, ThemeData theme) {
    final hintText = node.properties['hintText'] as String? ?? '';
    final labelText = node.properties['labelText'] as String?;

    return TextField(
      decoration: InputDecoration(
        hintText: hintText,
        labelText: labelText,
        border: const OutlineInputBorder(),
      ),
    );
  }

  // Image builder
  Widget _buildImage(WidgetTreeNode node, ThemeData theme) {
    final src = node.properties['src'] as String? ??
                node.properties['image'] as String?;

    if (src != null && src.startsWith('http')) {
      return Image.network(src, errorBuilder: (_, __, ___) {
        return Container(
          color: theme.colorScheme.surfaceContainerHighest,
          child: Icon(
            Icons.broken_image,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
          ),
        );
      });
    }

    return Container(
      color: theme.colorScheme.surfaceContainerHighest,
      child: Icon(
        Icons.image,
        color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
      ),
    );
  }

  // Icon builder
  Widget _buildIcon(WidgetTreeNode node, ThemeData theme) {
    final iconName = node.properties['icon'] as String? ?? 'star';
    final color = _parseColor(node.properties['color'], theme.colorScheme.primary);
    final size = node.properties['size'] as double? ?? 24.0;

    return Icon(
      _parseIconData(iconName),
      color: color,
      size: size,
    );
  }

  // Divider builder
  Widget _buildDivider(WidgetTreeNode node, ThemeData theme) {
    return const Divider();
  }

  // Progress Indicator builder
  Widget _buildProgressIndicator(WidgetTreeNode node, ThemeData theme) {
    return CircularProgressIndicator(
      color: theme.colorScheme.primary,
    );
  }

  // FAB builder
  Widget _buildFAB(WidgetTreeNode node, ThemeData theme) {
    final iconName = node.properties['icon'] as String? ?? 'add';

    return FloatingActionButton(
      onPressed: () {},
      child: Icon(_parseIconData(iconName)),
    );
  }

  // ListTile builder
  Widget _buildListTile(WidgetTreeNode node, ThemeData theme) {
    final titleText = node.properties['title'] as String?;
    final subtitleText = node.properties['subtitle'] as String?;

    Widget? leading;
    Widget? title;
    Widget? subtitle;
    Widget? trailing;

    for (final child in node.children) {
      switch (child.parameterName) {
        case 'leading':
          leading = reconstructWidget(child, theme: theme);
          break;
        case 'title':
          title = reconstructWidget(child, theme: theme);
          break;
        case 'subtitle':
          subtitle = reconstructWidget(child, theme: theme);
          break;
        case 'trailing':
          trailing = reconstructWidget(child, theme: theme);
          break;
      }
    }

    return ListTile(
      leading: leading,
      title: title ?? (titleText != null ? Text(titleText) : null),
      subtitle: subtitle ?? (subtitleText != null ? Text(subtitleText) : null),
      trailing: trailing,
    );
  }

  // SafeArea builder
  Widget _buildSafeArea(WidgetTreeNode node, ThemeData theme) {
    Widget? child;
    if (node.children.isNotEmpty) {
      child = reconstructWidget(node.children.first, theme: theme);
    }
    return SafeArea(child: child ?? const SizedBox.shrink());
  }

  // SingleChildScrollView builder
  Widget _buildSingleChildScrollView(WidgetTreeNode node, ThemeData theme) {
    Widget? child;
    if (node.children.isNotEmpty) {
      child = reconstructWidget(node.children.first, theme: theme);
    }
    return SingleChildScrollView(child: child);
  }

  // GestureDetector builder
  Widget _buildGestureDetector(WidgetTreeNode node, ThemeData theme) {
    Widget? child;
    if (node.children.isNotEmpty) {
      child = reconstructWidget(node.children.first, theme: theme);
    }

    if (node.name == 'InkWell') {
      return InkWell(onTap: () {}, child: child);
    }
    return GestureDetector(onTap: () {}, child: child);
  }

  // Pass-through widget builder - for wrapper widgets like Provider, BlocProvider, etc.
  Widget _buildPassThroughWidget(WidgetTreeNode node, ThemeData theme) {
    if (node.children.isEmpty) {
      return const SizedBox.shrink();
    }
    // If multiple children, wrap in a Column as a fallback
    if (node.children.length > 1) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: node.children
            .map((child) => reconstructWidget(child, theme: theme))
            .toList(),
      );
    }
    return reconstructWidget(node.children.first, theme: theme);
  }

  // Unknown widget builder - handles unrecognized widgets gracefully
  Widget _buildUnknownWidget(WidgetTreeNode node, ThemeData theme) {
    // Skip non-visual widgets (system calls, bindings, etc.)
    if (_isNonVisualWidget(node.name)) {
      if (node.children.isEmpty) return const SizedBox.shrink();
      
      if (node.children.length == 1) {
        return reconstructWidget(node.children.first, theme: theme);
      }
      
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: node.children
            .map((child) => reconstructWidget(child, theme: theme))
            .toList(),
      );
    }

    // For actual unknown widgets, show a compact indicator but still render children
    return Container(
      padding: const EdgeInsets.all(4),
      margin: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
          width: 0.5,
        ),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.widgets_outlined,
                color: theme.colorScheme.primary.withValues(alpha: 0.7),
                size: 10,
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  node.name,
                  style: TextStyle(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          if (node.children.isNotEmpty) ...[
            const SizedBox(height: 4),
            ...node.children.map((child) =>
              reconstructWidget(child, theme: theme)
            ),
          ],
        ],
      ),
    );
  }

  bool _isNonVisualWidget(String name) {
    const nonVisual = {
      'WidgetsFlutterBinding.ensureInitialized',
      'SystemChrome.setSystemUIOverlayStyle',
      'SystemChrome.setPreferredOrientations',
      'SystemUiOverlayStyle',
      'runApp',
      'WidgetsBinding',
    };
    return nonVisual.contains(name) || name.startsWith('SystemChrome.');
  }

  // Parse helpers
  Color? _parseColor(dynamic value, Color? defaultColor) {
    if (value == null) return defaultColor;
    if (value is Color) return value;
    if (value is String) {
      try {
        if (value.startsWith('#')) {
          return Color(int.parse(value.substring(1), radix: 16) + 0xFF000000);
        } else if (value.startsWith('0x')) {
          return Color(int.parse(value));
        }
      } catch (e) {
        return defaultColor;
      }
    }
    return defaultColor;
  }

  EdgeInsets? _parseEdgeInsets(dynamic value) {
    if (value == null) return null;
    if (value is EdgeInsets) return value;
    if (value is num) return EdgeInsets.all(value.toDouble());
    if (value is Map) {
      final left = (value['left'] ?? 0).toDouble();
      final top = (value['top'] ?? 0).toDouble();
      final right = (value['right'] ?? 0).toDouble();
      final bottom = (value['bottom'] ?? 0).toDouble();
      return EdgeInsets.fromLTRB(left, top, right, bottom);
    }
    return null;
  }

  MainAxisAlignment _parseMainAxisAlignment(dynamic value) {
    if (value == null) return MainAxisAlignment.start;
    if (value is MainAxisAlignment) return value;
    switch (value.toString()) {
      case 'center':
        return MainAxisAlignment.center;
      case 'end':
        return MainAxisAlignment.end;
      case 'spaceBetween':
        return MainAxisAlignment.spaceBetween;
      case 'spaceAround':
        return MainAxisAlignment.spaceAround;
      case 'spaceEvenly':
        return MainAxisAlignment.spaceEvenly;
      default:
        return MainAxisAlignment.start;
    }
  }

  CrossAxisAlignment _parseCrossAxisAlignment(dynamic value) {
    if (value == null) return CrossAxisAlignment.center;
    if (value is CrossAxisAlignment) return value;
    switch (value.toString()) {
      case 'start':
        return CrossAxisAlignment.start;
      case 'end':
        return CrossAxisAlignment.end;
      case 'stretch':
        return CrossAxisAlignment.stretch;
      default:
        return CrossAxisAlignment.center;
    }
  }

  FontWeight _parseFontWeight(dynamic value) {
    if (value == null) return FontWeight.normal;
    if (value is FontWeight) return value;
    switch (value.toString()) {
      case 'bold':
        return FontWeight.bold;
      case 'w100':
        return FontWeight.w100;
      case 'w200':
        return FontWeight.w200;
      case 'w300':
        return FontWeight.w300;
      case 'w500':
        return FontWeight.w500;
      case 'w600':
        return FontWeight.w600;
      case 'w700':
        return FontWeight.w700;
      case 'w800':
        return FontWeight.w800;
      case 'w900':
        return FontWeight.w900;
      default:
        return FontWeight.normal;
    }
  }

  Alignment? _parseAlignment(dynamic value) {
    if (value == null) return null;
    if (value is Alignment) return value;
    switch (value.toString()) {
      case 'topLeft':
        return Alignment.topLeft;
      case 'topCenter':
        return Alignment.topCenter;
      case 'topRight':
        return Alignment.topRight;
      case 'centerLeft':
        return Alignment.centerLeft;
      case 'centerRight':
        return Alignment.centerRight;
      case 'bottomLeft':
        return Alignment.bottomLeft;
      case 'bottomCenter':
        return Alignment.bottomCenter;
      case 'bottomRight':
        return Alignment.bottomRight;
      default:
        return Alignment.center;
    }
  }

  IconData _parseIconData(String iconName) {
    switch (iconName.toLowerCase()) {
      case 'home':
        return Icons.home;
      case 'star':
        return Icons.star;
      case 'favorite':
        return Icons.favorite;
      case 'settings':
        return Icons.settings;
      case 'search':
        return Icons.search;
      case 'menu':
        return Icons.menu;
      case 'add':
        return Icons.add;
      case 'edit':
        return Icons.edit;
      case 'delete':
        return Icons.delete;
      case 'close':
        return Icons.close;
      case 'check':
        return Icons.check;
      case 'arrow_back':
        return Icons.arrow_back;
      case 'arrow_forward':
        return Icons.arrow_forward;
      case 'person':
        return Icons.person;
      case 'email':
        return Icons.email;
      case 'phone':
        return Icons.phone;
      case 'widgets':
        return Icons.widgets;
      case 'code':
        return Icons.code;
      case 'visibility':
        return Icons.visibility;
      default:
        return Icons.circle;
    }
  }
}
