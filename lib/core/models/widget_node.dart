import 'package:flutter/material.dart';

class WidgetNode {
  final String id;
  final String type;
  final String name;
  final Map<String, dynamic> properties;
  final List<WidgetNode> children;
  final String? parentId;
  final bool isExpanded;

  const WidgetNode({
    required this.id,
    required this.type,
    required this.name,
    this.properties = const {},
    this.children = const [],
    this.parentId,
    this.isExpanded = true,
  });

  WidgetNode copyWith({
    String? id,
    String? type,
    String? name,
    Map<String, dynamic>? properties,
    List<WidgetNode>? children,
    String? parentId,
    bool? isExpanded,
  }) {
    return WidgetNode(
      id: id ?? this.id,
      type: type ?? this.type,
      name: name ?? this.name,
      properties: properties ?? this.properties,
      children: children ?? this.children,
      parentId: parentId ?? this.parentId,
      isExpanded: isExpanded ?? this.isExpanded,
    );
  }

  IconData get icon {
    switch (type.toLowerCase()) {
      case 'scaffold':
        return Icons.phone_android;
      case 'appbar':
        return Icons.web_asset;
      case 'container':
        return Icons.crop_square;
      case 'column':
        return Icons.view_column;
      case 'row':
        return Icons.table_rows;
      case 'text':
        return Icons.text_fields;
      case 'button':
        return Icons.smart_button;
      case 'image':
        return Icons.image;
      case 'icon':
        return Icons.emoji_symbols;
      case 'listview':
        return Icons.list;
      case 'card':
        return Icons.credit_card;
      default:
        return Icons.widgets;
    }
  }
}

class FileNode {
  final String name;
  final String path;
  final bool isDirectory;
  final List<FileNode> children;
  final bool isExpanded;

  const FileNode({
    required this.name,
    required this.path,
    this.isDirectory = false,
    this.children = const [],
    this.isExpanded = false,
  });

  FileNode copyWith({
    String? name,
    String? path,
    bool? isDirectory,
    List<FileNode>? children,
    bool? isExpanded,
  }) {
    return FileNode(
      name: name ?? this.name,
      path: path ?? this.path,
      isDirectory: isDirectory ?? this.isDirectory,
      children: children ?? this.children,
      isExpanded: isExpanded ?? this.isExpanded,
    );
  }
}

class ChatMessage {
  final String id;
  final String content;
  final bool isUser;
  final DateTime timestamp;
  final List<String>? attachments;
  final bool isLoading;

  const ChatMessage({
    required this.id,
    required this.content,
    required this.isUser,
    required this.timestamp,
    this.attachments,
    this.isLoading = false,
  });
}

enum ViewMode { preview, code, split }

enum PanelType { widgetTree, properties, agent }
