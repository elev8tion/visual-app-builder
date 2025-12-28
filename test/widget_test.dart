import 'package:flutter_test/flutter_test.dart';
import 'package:visual_app_builder/main.dart';

void main() {
  testWidgets('App renders without error', (WidgetTester tester) async {
    await tester.pumpWidget(const VisualAppBuilderApp());
    await tester.pumpAndSettle();

    // Verify that the app renders
    expect(find.text('Visual Builder'), findsOneWidget);
  });
}
