// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget propert

import 'package:flutter_test/flutter_test.dart';
import 'package:confidantsante/main.dart';

void main() {
  testWidgets('Splash screen smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const ConfidantSanteApp());
    expect(find.text('ConfidantSanté'), findsOneWidget);
  });
}