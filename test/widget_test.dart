// This is a basic Flutter widget test.
// Tests that the app can start and render without crashing.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:climatea/main.dart';

void main() {
  testWidgets('App starts and loads without crashing', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify that the app rendered without error.
    expect(find.byType(MyApp), findsOneWidget);
    
    // Verify that we can see some Scaffold widget (basic smoke test).
    expect(find.byType(Scaffold), findsWidgets);
  });
}
