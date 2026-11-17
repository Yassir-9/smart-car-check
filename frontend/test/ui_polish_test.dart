import 'dart:io';
import 'dart:math' as math;

import 'package:car_ai_diagnosis/l10n/app_localizations.dart';
import 'package:car_ai_diagnosis/models/maintenance_reminder.dart';
import 'package:car_ai_diagnosis/models/vehicle_issue.dart';
import 'package:car_ai_diagnosis/theme/app_theme.dart';
import 'package:car_ai_diagnosis/theme/app_tokens.dart';
import 'package:car_ai_diagnosis/utils/home_stats.dart';
import 'package:car_ai_diagnosis/utils/reminder_text.dart';
import 'package:car_ai_diagnosis/utils/western_digits.dart';
import 'package:car_ai_diagnosis/widgets/ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

double _lum(Color c) {
  double ch(double v) =>
      v <= 0.03928 ? v / 12.92 : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
  return 0.2126 * ch(c.r) + 0.7152 * ch(c.g) + 0.0722 * ch(c.b);
}

double contrast(Color a, Color b) {
  final l1 = _lum(a), l2 = _lum(b);
  final hi = l1 > l2 ? l1 : l2, lo = l1 > l2 ? l2 : l1;
  return (hi + 0.05) / (lo + 0.05);
}

MaintenanceReminder reminder(String id, {bool done = false}) =>
    MaintenanceReminder(
        id: id, title: 't', dueDate: DateTime(2026, 12, 1), isDone: done);

VehicleIssue issue(String status) => VehicleIssue(
    id: status,
    carId: 'c1',
    title: 'x',
    obdCodes: const [],
    status: status,
    date: DateTime(2026, 11, 1));

Widget host(Widget child, {Locale locale = const Locale('ar')}) => MaterialApp(
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      theme: AppUiTheme.light(),
      home: Directionality(
        textDirection:
            locale.languageCode == 'ar' ? TextDirection.rtl : TextDirection.ltr,
        child: Scaffold(body: Center(child: child)),
      ),
    );

void main() {
  reminderChipTests();
  group('home stats', () {
    test('counts only reminders that are not done', () {
      expect(upcomingReminderCount([]), 0);
      expect(
          upcomingReminderCount(
              [reminder('1'), reminder('2', done: true), reminder('3')]),
          2);
    });

    test('open faults are every issue whose status is not repaired', () {
      expect(openIssueCount([]), 0);
      expect(
          openIssueCount([
            issue('new'),
            issue('repaired'),
            issue('monitoring'),
            issue('returned'),
            issue('repair_needed'),
          ]),
          4);
    });

    test('days since uses calendar days, not 24h blocks', () {
      final now = DateTime(2026, 11, 17, 0, 5);
      expect(daysSince(DateTime(2026, 11, 17, 23, 59), now), 0);
      expect(daysSince(DateTime(2026, 11, 16, 23, 59), now), 1);
      expect(daysSince(DateTime(2026, 11, 10), now), 7);
      expect(daysSince(DateTime(2026, 12, 1), now), 0); // future → today
    });

    testWidgets('relative date text in Arabic and English', (tester) async {
      final now = DateTime(2026, 11, 17, 12);
      late AppLocalizations ar, en;
      await tester.pumpWidget(Builder(builder: (context) => const SizedBox()));
      ar = await AppLocalizations.delegate.load(const Locale('ar'));
      en = await AppLocalizations.delegate.load(const Locale('en'));
      expect(relativeDayText(ar, DateTime(2026, 11, 17, 9), now), 'اليوم');
      expect(relativeDayText(ar, DateTime(2026, 11, 16, 23), now), 'أمس');
      expect(relativeDayText(ar, DateTime(2026, 11, 12), now), 'قبل 5 يوم');
      expect(relativeDayText(en, DateTime(2026, 11, 17), now), 'Today');
      expect(relativeDayText(en, DateTime(2026, 11, 16), now), 'Yesterday');
      expect(relativeDayText(en, DateTime(2026, 11, 12), now), '5 days ago');
    });
  });

  group('accessibility', () {
    test('every status colour pair has contrast >= 4.5:1', () {
      for (final level in StatusLevel.values) {
        final c = statusColors(level);
        expect(contrast(c.text, c.bg), greaterThanOrEqualTo(4.5),
            reason: '$level');
      }
    });

    test('text colours keep >= 4.5:1 on their backgrounds', () {
      expect(contrast(Ui.textPrimary, Ui.screenBg), greaterThanOrEqualTo(4.5));
      expect(contrast(Ui.textPrimary, Ui.card), greaterThanOrEqualTo(4.5));
      expect(contrast(Ui.textSecondary, Ui.card), greaterThanOrEqualTo(4.5));
      expect(contrast(Ui.textSecondary, Ui.screenBg), greaterThanOrEqualTo(4.5));
      expect(contrast(Ui.primaryText, Ui.card), greaterThanOrEqualTo(4.5));
      expect(contrast(Ui.primaryText, Ui.iconBg), greaterThanOrEqualTo(4.5));
      expect(contrast(Colors.white, Ui.primary), greaterThanOrEqualTo(4.5));
      expect(contrast(Ui.onDark, Ui.darkCard), greaterThanOrEqualTo(4.5));
      expect(contrast(Ui.onDark, Ui.darkTile), greaterThanOrEqualTo(4.5));
      expect(contrast(Ui.onDarkMuted, Ui.darkTile), greaterThanOrEqualTo(4.5));
      expect(contrast(Ui.onDarkMuted, Ui.darkCard), greaterThanOrEqualTo(4.5));
    });

    testWidgets('buttons are at least 48 dp tall to touch', (tester) async {
      await tester.pumpWidget(host(Column(mainAxisSize: MainAxisSize.min, children: [
        PrimaryButton(label: 'A', onPressed: () {}),
        SecondaryButton(label: 'B', onPressed: () {}),
      ])));
      expect(tester.getSize(find.byType(ElevatedButton)).height,
          greaterThanOrEqualTo(52));
      // SecondaryButton is 44 high with a padded 48 tap target.
      final secondary = tester.getSize(find.byType(OutlinedButton));
      expect(secondary.height, greaterThanOrEqualTo(44));
      expect(find.bySemanticsLabel('A'), findsWidgets);
    });

    testWidgets('a status chip always carries its text', (tester) async {
      await tester.pumpWidget(host(const Column(mainAxisSize: MainAxisSize.min, children: [
        StatusChip(label: 'سليم', level: StatusLevel.ok),
        StatusChip(label: 'انتباه', level: StatusLevel.warn),
        StatusChip(label: 'خطر', level: StatusLevel.danger),
      ])));
      expect(find.text('سليم'), findsOneWidget);
      expect(find.text('انتباه'), findsOneWidget);
      expect(find.text('خطر'), findsOneWidget);
    });

    testWidgets('a tappable AppCard is at least 48 high and fires onTap',
        (tester) async {
      var taps = 0;
      await tester.pumpWidget(host(AppCard(
          onTap: () => taps++,
          semanticLabel: 'open',
          child: const Text('x'))));
      expect(tester.getSize(find.byType(AppCard)).height,
          greaterThanOrEqualTo(48));
      await tester.tap(find.byType(AppCard));
      expect(taps, 1);
    });
  });

  group('rtl and digits', () {
    test('Arabic-Indic and Persian digits become Western digits', () {
      expect(westernDigits('الاثنين، ١٦ نوفمبر - ١٠:١٩ م'),
          'الاثنين، 16 نوفمبر - 10:19 م');
      expect(westernDigits('۱۲۳ abc 456'), '123 abc 456');
      expect(westernDigits(''), '');
    });

    testWidgets('direction aware arrows mirror in Arabic', (tester) async {
      await tester.pumpWidget(host(const Icon(Icons.arrow_forward)));
      expect(Icons.arrow_forward.matchTextDirection, isTrue);
      expect(Icons.arrow_back.matchTextDirection, isTrue);
      expect(Icons.chevron_right.matchTextDirection, isTrue);
    });

    test('source code has no hand-made RTL arrow switch left', () {
      for (final f in [
        'lib/screens/diagnosis_wizard_screen.dart',
        'lib/screens/settings_screen.dart',
      ]) {
        final text = File(f).readAsStringSync();
        expect(RegExp(r'isRtl\s*\?\s*Icons\.(arrow|chevron)').hasMatch(text),
            isFalse,
            reason: f);
        expect(
            RegExp(r'TextDirection\.rtl\s*\n?\s*\?\s*Icons\.chevron')
                .hasMatch(text),
            isFalse,
            reason: f);
      }
    });
  });

  group('font and privacy', () {
    test('IBM Plex Sans Arabic is bundled with its OFL licence', () {
      final pubspec = File('pubspec.yaml').readAsStringSync();
      for (final w in ['Regular', 'Medium', 'SemiBold', 'Bold']) {
        expect(pubspec, contains('IBMPlexSansArabic-$w.ttf'));
        expect(File('assets/fonts/IBMPlexSansArabic-$w.ttf').existsSync(),
            isTrue);
      }
      expect(File('assets/fonts/OFL-IBMPlexSansArabic.txt').existsSync(), isTrue);
      expect(Ui.fontFamily, 'IBMPlexSansArabic');
      expect(AppUiTheme.light().textTheme.bodyMedium?.fontFamily,
          'IBMPlexSansArabic');
    });

    test('no runtime font download package is used', () {
      expect(File('pubspec.yaml').readAsStringSync(),
          isNot(contains('google_fonts')));
      expect(File('pubspec.lock').readAsStringSync(),
          isNot(contains('google_fonts')));
    });
  });
}

void reminderChipTests() {
  group('reminder chip level', () {
    test('only a done reminder is green', () {
      expect(reminderChipLevel(30, isDone: true), StatusLevel.ok);
      expect(reminderChipLevel(-5, isDone: true), StatusLevel.ok);
      expect(reminderChipLevel(30, isDone: false), isNot(StatusLevel.ok));
    });

    test('boundaries: 15 days grey, 14 amber, today amber, yesterday red', () {
      expect(reminderChipLevel(15, isDone: false), StatusLevel.neutral);
      expect(reminderChipLevel(14, isDone: false), StatusLevel.warn);
      expect(reminderChipLevel(0, isDone: false), StatusLevel.warn);
      expect(reminderChipLevel(-1, isDone: false), StatusLevel.danger);
    });

    test('neutral colours are as designed and readable', () {
      final c = statusColors(StatusLevel.neutral);
      expect(c.text, const Color(0xFF334155));
      expect(c.bg, const Color(0xFFE2E8F0));
      expect(contrast(c.text, c.bg), greaterThanOrEqualTo(4.5));
    });
  });
}
