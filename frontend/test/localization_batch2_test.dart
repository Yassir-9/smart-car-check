import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:car_ai_diagnosis/l10n/app_localizations.dart';
import 'package:car_ai_diagnosis/l10n/app_localizations_ar.dart';
import 'package:car_ai_diagnosis/l10n/app_localizations_en.dart';
import 'package:car_ai_diagnosis/models/car_model.dart';
import 'package:car_ai_diagnosis/models/diagnosis_input.dart';
import 'package:car_ai_diagnosis/screens/diagnosis_result_screen.dart';
import 'package:car_ai_diagnosis/screens/repair_review_result_screen.dart';

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

void main() {
  test('diagnosis payload carries only a supported selected locale', () {
    final draft = DiagnosisDraft(
      initialSources: {DiagnosisMethod.symptoms},
    );
    final base = <String, Object?>{
      'car': <String, Object?>{'id': 'car-1'},
      'symptoms': 'vibration while idling',
      'obdCodes': <String>[],
      'imageBytes': null,
      'imageMime': 'image/jpeg',
    };

    Map<String, dynamic> payload(String? locale) => draft.buildPayload(
          car: base['car']! as Map<String, dynamic>,
          symptoms: base['symptoms']! as String,
          obdCodes: base['obdCodes']! as List<String>,
          imageBytes: base['imageBytes'] as Uint8List?,
          imageMime: base['imageMime']! as String,
          locale: locale,
        );

    expect(payload('ar')['locale'], 'ar');
    expect(payload('en')['locale'], 'en');
    expect(payload('fr').containsKey('locale'), isFalse);
    expect(payload(null).containsKey('locale'), isFalse);
  });

  test('Batch 2 Arabic and English resources expose matching core content', () {
    final ar = AppLocalizationsAr();
    final en = AppLocalizationsEn();

    expect(ar.diagnosisTitle, 'فحص السيارة');
    expect(en.diagnosisTitle, 'Vehicle diagnosis');
    expect(ar.beforeYouPayTitle, 'قبل ما تدفع');
    expect(en.beforeYouPayTitle, 'Before You Pay');
    expect(ar.quoteReviewTitle, isNotEmpty);
    expect(en.quoteReviewTitle, isNotEmpty);
    expect(en.freeDiagnosisLimitReached,
        isNot(contains(RegExp(r'[\u0600-\u06FF]'))));
  });

  test('target screens contain no visible hard-coded Arabic string literals',
      () {
    const files = [
      'lib/screens/diagnosis_wizard_screen.dart',
      'lib/screens/diagnosis_result_screen.dart',
      'lib/screens/before_you_pay_screen.dart',
      'lib/screens/repair_review_result_screen.dart',
    ];
    final arabicLiteral = RegExp(r'''['"][^'"]*[\u0600-\u06FF][^'"]*['"]''');
    final allowedCompatibilityLiterals = {'عالية', 'متوسطة'};

    for (final path in files) {
      final source = File(path).readAsStringSync();
      final matches = arabicLiteral
          .allMatches(source)
          .map((match) => match.group(0)!)
          .where(
              (literal) => !allowedCompatibilityLiterals.any(literal.contains))
          .where((literal) => !literal.contains('[,،\\n]'))
          .toList();
      expect(matches, isEmpty,
          reason: '$path has untranslated literals: $matches');
    }
  });

  testWidgets('diagnosis result renders English LTR without overflow',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final car =
        CarModel(id: 'car-1', brand: 'Nissan', model: 'Maxima', year: 2016);
    await tester.pumpWidget(localizedApp(
      locale: const Locale('en'),
      home: DiagnosisResultScreen(
        car: car,
        symptoms: 'Vibration while idling',
        result: const {
          'title': 'Possible ignition issue',
          'summary': 'A direct inspection is recommended.',
          'severity': 'medium',
          'confidence_score': 70,
          'can_drive': true,
          'drive_advice': 'Drive carefully and arrange an inspection.',
          'likely_causes': ['Possible ignition issue'],
          'recommended_checks': ['Inspect ignition components'],
          'possible_parts': [],
          'next_step': 'Book a qualified inspection',
          'obd_codes': [],
        },
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Diagnosis result'), findsOneWidget);
    expect(find.text('نتيجة الفحص'), findsNothing);
    expect(
        tester
            .widget<Directionality>(find.byType(Directionality).first)
            .textDirection,
        TextDirection.ltr);
    expect(tester.takeException(), isNull);
  });

  testWidgets('repair review renders English LTR labels without overflow',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final car =
        CarModel(id: 'car-1', brand: 'Nissan', model: 'Maxima', year: 2016);
    const result = {
      'status': 'verify',
      'analysis_complete': true,
      'summary': 'Needs test evidence before approval.',
      'aligned_evidence': [],
      'evidence_needed': ['Documented measurement'],
      'technician_questions': ['Which test confirmed the fault?'],
      'recommended_checks': ['Request the test result'],
      'parts': [],
      'price': {'note': 'Insufficient market data'},
      'safety': {'critical': false, 'advice': ''},
    };
    await tester.pumpWidget(localizedApp(
      locale: const Locale('en'),
      home: RepairReviewResultScreen(result: result, car: car),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Workshop quote review'), findsOneWidget);
    expect(find.text('مراجعة عرض الورشة'), findsNothing);
    expect(
        tester
            .widget<Directionality>(find.byType(Directionality).first)
            .textDirection,
        TextDirection.ltr);
    expect(tester.takeException(), isNull);
  });
}
