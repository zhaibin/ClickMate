// ClickMate Widget Test
// 
// Basic smoke test to verify the app launches successfully

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:clickmate/main.dart';

void main() {
  testWidgets('App launches successfully', (WidgetTester tester) async {
    // Build the app and trigger a frame
    await tester.pumpWidget(const MyApp());
    
    // Wait for async initialization
    await tester.pumpAndSettle();
    
    // Verify that the app launches without errors
    // The app should contain some basic UI elements
    expect(find.byType(MaterialApp), findsOneWidget);
  });

  testWidgets('App has required UI elements', (WidgetTester tester) async {
    // Build the app
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();
    
    // Verify that basic UI elements exist
    // This is a smoke test to ensure the app structure is intact
    expect(find.byType(Scaffold), findsWidgets);
  });
}
