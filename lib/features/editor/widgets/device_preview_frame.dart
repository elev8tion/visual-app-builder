import 'dart:async';
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';

/// Device frame sizes for simulation
enum DeviceType {
  iphone15Pro(390, 844, 'iPhone 15 Pro'),
  iphone15ProMax(430, 932, 'iPhone 15 Pro Max'),
  pixel7(412, 915, 'Pixel 7'),
  pixel7Pro(412, 892, 'Pixel 7 Pro'),
  ipadPro11(834, 1194, 'iPad Pro 11"'),
  ipadPro129(1024, 1366, 'iPad Pro 12.9"'),
  desktop(1280, 720, 'Desktop'),
  custom(0, 0, 'Custom');

  final double width;
  final double height;
  final String displayName;

  const DeviceType(this.width, this.height, this.displayName);
}

/// Widget that displays a Flutter Web preview in an IFrame
/// with device simulation frame
class DevicePreviewFrame extends StatefulWidget {
  /// The URL of the preview to display
  final String? previewUrl;

  /// Currently selected device type
  final DeviceType deviceType;

  /// Scale factor for the preview
  final double scale;

  /// Whether to show device frame
  final bool showDeviceFrame;

  /// Callback when a widget is selected in the preview
  final void Function(String widgetId)? onWidgetSelected;

  /// Callback when preview loads
  final VoidCallback? onPreviewLoaded;

  /// Callback when preview errors
  final void Function(String error)? onPreviewError;

  const DevicePreviewFrame({
    super.key,
    this.previewUrl,
    this.deviceType = DeviceType.iphone15Pro,
    this.scale = 1.0,
    this.showDeviceFrame = true,
    this.onWidgetSelected,
    this.onPreviewLoaded,
    this.onPreviewError,
  });

  @override
  State<DevicePreviewFrame> createState() => _DevicePreviewFrameState();
}

class _DevicePreviewFrameState extends State<DevicePreviewFrame> {
  static int _iframeCounter = 0;
  late String _viewType;
  html.IFrameElement? _iframe;
  StreamSubscription? _messageSubscription;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _viewType = 'preview-iframe-${_iframeCounter++}';
    _registerViewFactory();
    _setupMessageListener();
  }

  @override
  void didUpdateWidget(DevicePreviewFrame oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.previewUrl != widget.previewUrl) {
      _updateIframeSrc();
    }
  }

  @override
  void dispose() {
    _messageSubscription?.cancel();
    super.dispose();
  }

  void _registerViewFactory() {
    // ignore: undefined_prefixed_name
    ui_web.platformViewRegistry.registerViewFactory(
      _viewType,
      (int viewId) {
        _iframe = html.IFrameElement()
          ..style.border = 'none'
          ..style.width = '100%'
          ..style.height = '100%'
          ..style.backgroundColor = '#ffffff'
          ..allow = 'clipboard-read; clipboard-write'
          ..onLoad.listen((_) {
            setState(() => _isLoading = false);
            widget.onPreviewLoaded?.call();
          })
          ..onError.listen((event) {
            setState(() {
              _isLoading = false;
              _error = 'Failed to load preview';
            });
            widget.onPreviewError?.call('Failed to load preview');
          });

        if (widget.previewUrl != null) {
          _iframe!.src = widget.previewUrl;
        }

        return _iframe!;
      },
    );
  }

  void _setupMessageListener() {
    // Listen for postMessage from the preview IFrame
    _messageSubscription = html.window.onMessage.listen((event) {
      if (event.data is Map) {
        final data = event.data as Map;
        final type = data['type'];

        if (type == 'widgetSelected') {
          final widgetId = data['widgetId'] as String?;
          if (widgetId != null) {
            widget.onWidgetSelected?.call(widgetId);
          }
        } else if (type == 'previewReady') {
          widget.onPreviewLoaded?.call();
        } else if (type == 'previewError') {
          final error = data['error'] as String? ?? 'Unknown error';
          widget.onPreviewError?.call(error);
        }
      }
    });
  }

  void _updateIframeSrc() {
    if (_iframe != null && widget.previewUrl != null) {
      setState(() => _isLoading = true);
      _iframe!.src = widget.previewUrl;
    }
  }

  /// Send a message to the preview IFrame
  void sendMessage(Map<String, dynamic> message) {
    _iframe?.contentWindow?.postMessage(message, '*');
  }

  /// Request hot reload in the preview
  void hotReload() {
    sendMessage({'type': 'hotReload'});
  }

  /// Enable/disable widget selection mode in preview
  void setSelectionMode(bool enabled) {
    sendMessage({'type': 'setSelectionMode', 'enabled': enabled});
  }

  /// Highlight a specific widget in the preview
  void highlightWidget(String widgetId) {
    sendMessage({'type': 'highlightWidget', 'widgetId': widgetId});
  }

  /// Clear widget highlight
  void clearHighlight() {
    sendMessage({'type': 'clearHighlight'});
  }

  @override
  Widget build(BuildContext context) {
    final deviceWidth = widget.deviceType.width;
    final deviceHeight = widget.deviceType.height;

    Widget content;

    if (widget.previewUrl == null) {
      content = _buildEmptyState();
    } else if (_error != null) {
      content = _buildErrorState();
    } else {
      content = Stack(
        children: [
          HtmlElementView(viewType: _viewType),
          if (_isLoading) _buildLoadingOverlay(),
        ],
      );
    }

    // Wrap in device frame if enabled
    if (widget.showDeviceFrame && widget.deviceType != DeviceType.desktop) {
      return Center(
        child: Transform.scale(
          scale: widget.scale,
          child: _DeviceFrame(
            deviceType: widget.deviceType,
            child: SizedBox(
              width: deviceWidth,
              height: deviceHeight,
              child: content,
            ),
          ),
        ),
      );
    }

    return Center(
      child: Transform.scale(
        scale: widget.scale,
        child: SizedBox(
          width: deviceWidth > 0 ? deviceWidth : double.infinity,
          height: deviceHeight > 0 ? deviceHeight : double.infinity,
          child: content,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      color: const Color(0xFF1E1E1E),
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.phone_android, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No Preview Available',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
            SizedBox(height: 8),
            Text(
              'Build your project to see a preview',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Container(
      color: const Color(0xFF1E1E1E),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            const Text(
              'Preview Error',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? 'Unknown error',
              style: const TextStyle(color: Colors.grey, fontSize: 12),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _updateIframeSrc,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: const Color(0xFF1E1E1E).withOpacity(0.8),
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              'Loading Preview...',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}

/// Device frame widget that simulates device bezels
class _DeviceFrame extends StatelessWidget {
  final DeviceType deviceType;
  final Widget child;

  const _DeviceFrame({
    required this.deviceType,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final isIPhone = deviceType.displayName.contains('iPhone');
    final isIPad = deviceType.displayName.contains('iPad');

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(isIPad ? 24 : 44),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Notch/Dynamic Island for iPhones
          if (isIPhone)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              width: 120,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          // Screen
          ClipRRect(
            borderRadius: BorderRadius.circular(isIPad ? 12 : 32),
            child: child,
          ),
          // Home indicator
          if (isIPhone || isIPad)
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: 134,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.5),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
        ],
      ),
    );
  }
}
