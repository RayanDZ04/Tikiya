// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:flutter/material.dart';

import 'package:tikiya_web/app_theme.dart';
import 'package:tikiya_web/screens/home_screen.dart';

void main() {
  testWidgets('Home screen smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.build(),
        home: const HomeScreen(),
      ),
    );
    await tester.pump();

    expect(find.text('Se connecter'), findsOneWidget);
    expect(find.text("S'inscrire"), findsOneWidget);
  });
}
