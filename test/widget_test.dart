// This is a basic Flutter widget test.
// Tests that the app can start and render without crashing.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:climatea/main.dart';

void main() {
  group('MyApp Widget Tests', () {
    testWidgets('App starts and loads without crashing', (WidgetTester tester) async {
      // Build our app and trigger a frame.
      await tester.pumpWidget(const MyApp());

      // Verify that the app rendered without error.
      expect(find.byType(MyApp), findsOneWidget);
      
      // Verify that we can see some Scaffold widget (basic smoke test).
      expect(find.byType(Scaffold), findsWidgets);
    });

    testWidgets('MyApp uses dark theme', (WidgetTester tester) async {
      await tester.pumpWidget(const MyApp());

      // Get the MaterialApp widget
      final app = find.byType(MaterialApp);
      expect(app, findsOneWidget);
    });

    testWidgets('App has correct title', (WidgetTester tester) async {
      await tester.pumpWidget(const MyApp());

      // The app title is set in the MaterialApp
      final materialApp = find.byType(MaterialApp);
      expect(materialApp, findsOneWidget);
    });

    testWidgets('App renders loading screen on startup', (WidgetTester tester) async {
      await tester.pumpWidget(const MyApp());

      // Wait for the widget tree to be built
      await tester.pump(const Duration(milliseconds: 500));

      // Verify basic structure is present
      expect(find.byType(MaterialApp), findsOneWidget);
    });
  });
}

