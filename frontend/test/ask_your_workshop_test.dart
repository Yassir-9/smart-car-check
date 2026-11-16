import 'package:car_ai_diagnosis/l10n/app_localizations.dart';
import 'package:car_ai_diagnosis/models/car_model.dart';
import 'package:car_ai_diagnosis/screens/diagnosis_result_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

Widget localizedApp({required Locale locale, required Widget home}) =>
    MaterialApp(
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: home,
    );

Future<void> pumpWith(WidgetTester tester, Locale locale, Object? questions) async {
  await tester.binding.setSurfaceSize(const Size(390, 1600));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(localizedApp(
      locale: locale,
      home: DiagnosisResultScreen(
          car: CarModel(id: 'c', brand: 'Nissan', model: 'Maxima', year: 2016),
          symptoms: 'noise',
          result: {
            'title': 'Possible issue',
            'summary': 'Inspect.',
            'severity': 'medium',
            'confidence_score': 70,
            'can_drive': true,
            'drive_advice': 'Drive carefully.',
            'likely_causes': ['Worn parts'],
            'recommended_checks': ['Inspect ignition'],
            'possible_parts': [],
            'next_step': 'Book an inspection',
            'obd_codes': [],
            if (questions != null) 'workshop_questions': questions,
          })));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('English: collapsed "Ask your workshop" expands to the generated questions', (tester) async {
    await pumpWith(tester, const Locale('en'),
        ['Which test confirmed the cause?', 'Can I see the old part?']);
    expect(find.text('Ask your workshop'), findsOneWidget);
    // collapsed: questions are not visible yet
    expect(find.text('Which test confirmed the cause?'), findsNothing);
    await tester.tap(find.text('Ask your workshop'));
    await tester.pumpAndSettle();
    expect(find.text('Which test confirmed the cause?'), findsOneWidget);
    expect(find.text('Can I see the old part?'), findsOneWidget);
    // tapping again collapses it
    await tester.tap(find.text('Ask your workshop'));
    await tester.pumpAndSettle();
    expect(find.text('Which test confirmed the cause?'), findsNothing);
  });

  testWidgets('Arabic title and content', (tester) async {
    await pumpWith(tester, const Locale('ar'), ['ما الاختبار الذي أثبت السبب؟']);
    expect(find.text('اسأل ورشتك'), findsOneWidget);
    await tester.tap(find.text('اسأل ورشتك'));
    await tester.pumpAndSettle();
    expect(find.text('ما الاختبار الذي أثبت السبب؟'), findsOneWidget);
  });

  testWidgets('hidden when the questions are empty, missing or blank', (tester) async {
    for (final value in <Object?>[<String>[], null, ['  ', '']]) {
      await pumpWith(tester, const Locale('en'), value);
      expect(find.text('Ask your workshop'), findsNothing, reason: '$value');
    }
  });
}
