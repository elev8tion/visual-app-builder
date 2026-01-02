import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:visual_app_builder/main.dart';

void main() {
  testWidgets('App renders without error', (WidgetTester tester) async {
    // Set a desktop-like size
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1.0;

    await tester.pumpWidget(const VisualAppBuilderApp());
    await tester.pumpAndSettle();

    // Verify that the app renders
    expect(find.text('Visual Builder'), findsOneWidget);
    
    // Reset size
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  });
}
