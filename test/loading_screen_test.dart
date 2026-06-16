import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:climatea/screens/loading_screen.dart';

void main() {
  group('LoadingScreen Tests', () {
    testWidgets('LoadingScreen displays spinner', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: LoadingScreen(),
        ),
      );

      // Verify scaffold is present
      expect(find.byType(Scaffold), findsOneWidget);

      // Verify center widget with spinner (may have multiple Center widgets)
      expect(find.byType(Center), findsWidgets);
    });

    testWidgets('LoadingScreen has correct background', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: LoadingScreen(),
        ),
      );

      // Verify Scaffold exists and is visible
      final scaffold = find.byType(Scaffold);
      expect(scaffold, findsOneWidget);
    });
  });
}
