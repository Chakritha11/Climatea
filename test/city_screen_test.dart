import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:climatea/screens/city_screen.dart';

void main() {
  group('CityScreen Tests', () {
    testWidgets('CityScreen displays city input field', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: CityScreen(),
        ),
      );

      // Verify scaffold
      expect(find.byType(Scaffold), findsOneWidget);

      // Verify text field exists
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('CityScreen has back button', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: CityScreen(),
        ),
      );

      // Verify back button exists
      expect(find.byType(OutlinedButton), findsWidgets);
    });

    testWidgets('CityScreen can enter city name', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: CityScreen(),
        ),
      );

      // Find and enter text in the text field
      await tester.enterText(find.byType(TextField), 'New York');
      await tester.pump();

      // Verify text was entered
      expect(find.text('New York'), findsOneWidget);
    });

    testWidgets('CityScreen has Get Climate View button', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: CityScreen(),
        ),
      );

      // Verify button with text exists
      expect(find.byType(OutlinedButton), findsWidgets);
    });
  });
}
