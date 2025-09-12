// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

import 'package:motion_sensor_app/main.dart';

void main() {
  testWidgets('MotionSensorApp builds without errors', (WidgetTester tester) async {
    // Build the app
    await tester.pumpWidget(const MotionSensorApp());

    // Let the widget tree settle
    await tester.pumpAndSettle();

    // Basic sanity checks
    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.byType(Scaffold), findsWidgets); // at least one scaffold present
    // Optional: check for at least one Button (less brittle than exact label)
    expect(find.byType(ElevatedButton).hitTestable(), findsWidgets);
    
    // Ensure no uncaught exceptions were thrown during build
    expect(tester.takeException(), isNull);
  });
}
