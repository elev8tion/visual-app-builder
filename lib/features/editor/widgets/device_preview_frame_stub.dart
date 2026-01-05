import 'package:flutter/material.dart';

/// Stub implementation for non-web platforms
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

/// Stub widget for non-web platforms
class DevicePreviewFrame extends StatelessWidget {
  final String? previewUrl;
  final DeviceType deviceType;
  final double scale;
  final bool showDeviceFrame;
  final void Function(String widgetId)? onWidgetSelected;
  final VoidCallback? onPreviewLoaded;
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
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF1E1E1E),
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.desktop_mac, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Preview not available',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
            SizedBox(height: 8),
            Text(
              'Device preview is only available on web',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
