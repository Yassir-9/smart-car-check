import 'package:car_ai_diagnosis/l10n/app_localizations.dart';
import 'package:car_ai_diagnosis/models/car_model.dart';
import 'package:car_ai_diagnosis/screens/diagnosis_result_screen.dart';
import 'package:car_ai_diagnosis/utils/bidi_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

String iso(String s) => '\u2068$s\u2069';

void main() {
  group('isolateLatinRuns', () {
    test('wraps English terms inside Arabic sentences (the reported example)', () {
      expect(
          isolateLatinRuns('مجموعة (Sway Bar Links/Bushings) متهالكة'),
          'مجموعة (${iso('Sway Bar Links/Bushings')}) متهالكة');
      expect(isolateLatinRuns('(Sway) ... Bar Links/Bushings)'),
          '(${iso('Sway')}) ... ${iso('Bar Links/Bushings')})');
    });

    test('handles several runs, codes and joiners', () {
      expect(isolateLatinRuns('فحص P0300 وحساس O2 sensor و ABS-sensor'),
          'فحص ${iso('P0300')} وحساس ${iso('O2 sensor')} و ${iso('ABS-sensor')}');
      expect(isolateLatinRuns('قطعة 04152-YZZA1 جديدة'),
          'قطعة ${iso('04152-YZZA1')} جديدة');
    });

    test('leaves Arabic-only text, numbers and empty text untouched', () {
      expect(isolateLatinRuns('فحص البواجي والكويلات'), 'فحص البواجي والكويلات');
      expect(isolateLatinRuns('عداد 120000 كم سنة 2019'), 'عداد 120000 كم سنة 2019');
      expect(isolateLatinRuns(''), '');
      expect(isolateLatinRuns('(٣) ... ،'), '(٣) ... ،');
    });

    test('is idempotent and does not eat trailing punctuation or spaces', () {
      const text = 'افحص Bushings، ثم Sway bar.';
      final once = isolateLatinRuns(text);
      expect(once, 'افحص ${iso('Bushings')}، ثم ${iso('Sway bar')}.');
      expect(isolateLatinRuns(once), once);
      expect(once.replaceAll('\u2068', '').replaceAll('\u2069', ''), text);
    });

    test('English text is wrapped by the function, but bidiText skips LTR contexts', () {
      expect(isolateLatinRuns('Brake pads'), iso('Brake pads'));
    });
  });

  group('bidiText in the diagnosis result', () {
    Widget app(Locale locale, Widget home) => MaterialApp(
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

    Widget screen() => DiagnosisResultScreen(
          car: CarModel(id: 'c', brand: 'Nissan', model: 'Maxima', year: 2016),
          symptoms: 'noise',
          result: const {
            'title': 'أصوات من (Sway Bar Links) الأمامية',
            'summary': 'قد يكون السبب (Sway Bar Links/Bushings) متآكلة.',
            'severity': 'medium',
            'confidence_score': 70,
            'can_drive': true,
            'drive_advice': 'قد القيادة بحذر مع فحص Struts.',
            'likely_causes': ['تآكل Ball joint'],
            'recommended_checks': ['افحص Control arm bushings'],
            'possible_parts': ['Sway Bar Links', 'شمعات'],
            'workshop_questions': ['هل فحصتم Tie rod ends؟'],
            'next_step': 'احجز فحصاً لدى فني (Alignment).',
            'obd_codes': [
              {'code': 'P0300', 'official_title': 'خلل Misfire عشوائي', 'meaning': 'مشكلة في Ignition', 'locally_verified': true}
            ],
          },
        );

    testWidgets('Arabic UI: every AI text field has its English runs isolated', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 2400));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(app(const Locale('ar'), screen()));
      await tester.pumpAndSettle();
      await tester.tap(find.text('اسأل ورشتك'));
      await tester.pumpAndSettle();

      final expected = <String>[
        'أصوات من (${iso('Sway Bar Links')}) الأمامية',
        'قد يكون السبب (${iso('Sway Bar Links/Bushings')}) متآكلة.',
        'قد القيادة بحذر مع فحص ${iso('Struts')}.',
        'تآكل ${iso('Ball joint')}',
        'افحص ${iso('Control arm bushings')}',
        iso('Sway Bar Links'),
        'هل فحصتم ${iso('Tie rod ends')}؟',
        'احجز فحصاً لدى فني (${iso('Alignment')}).',
        '${iso('P0300')} — خلل ${iso('Misfire')} عشوائي',
        'مشكلة في ${iso('Ignition')}',
      ];
      for (final text in expected) {
        expect(find.text(text), findsOneWidget, reason: text);
      }
      // the Arabic-only part name is untouched
      expect(find.text('شمعات'), findsOneWidget);
    });

    testWidgets('English UI is not changed (no invisible characters added)', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 2400));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(app(const Locale('en'), screen()));
      await tester.pumpAndSettle();
      expect(find.text('Sway Bar Links'), findsOneWidget);
      expect(find.text('P0300 — خلل Misfire عشوائي'), findsOneWidget);
      expect(find.textContaining('\u2068'), findsNothing);
    });
  });
}
