import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:car_ai_diagnosis/main.dart';

void main() {
  testWidgets('App builds without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(
      CarAiApp(authStateChanges: Stream<User?>.value(null)),
    );
    await tester.pump();

    expect(find.byType(CarAiApp), findsOneWidget);
  });

  testWidgets('MaterialApp always uses ThemeMode.light', (tester) async {
    await tester.pumpWidget(
      CarAiApp(authStateChanges: Stream<User?>.value(null)),
    );
    await tester.pump();

    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.themeMode, ThemeMode.light);
    expect(kForcedThemeMode, ThemeMode.light);
  });

  testWidgets('light theme is used even when the system is dark',
      (tester) async {
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    await tester.pumpWidget(
      CarAiApp(authStateChanges: Stream<User?>.value(null)),
    );
    await tester.pump();

    final context = tester.element(find.byType(Scaffold).first);
    expect(Theme.of(context).brightness, Brightness.light);
  });
}
