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

    // Basic sanity checks - more flexible approach
    expect(find.byType(MaterialApp), findsOneWidget);
    
    // Check that the app builds without throwing exceptions
    expect(tester.takeException(), isNull);
    
    // Optional: Check for common widget types that should be present
    // instead of specific button types
    expect(find.byType(Scaffold), findsAtLeast(1));
    
    // Look for any interactive elements instead of specific buttons
    expect(find.byType(GestureDetector).hitTestable() | 
           find.byType(InkWell).hitTestable() |
           find.byType(TextButton).hitTestable() |
           find.byType(ElevatedButton).hitTestable(), 
           findsAtLeast(1));
  });
}