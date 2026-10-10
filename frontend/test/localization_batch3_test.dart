import 'dart:io';

import 'package:car_ai_diagnosis/l10n/app_localizations.dart';
import 'package:car_ai_diagnosis/l10n/app_localizations_ar.dart';
import 'package:car_ai_diagnosis/l10n/app_localizations_en.dart';
import 'package:car_ai_diagnosis/models/car_model.dart';
import 'package:car_ai_diagnosis/screens/repair_verification_screen.dart';
import 'package:car_ai_diagnosis/screens/workshop_mode_screen.dart';
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

void main() {
  final car =
      CarModel(id: 'car-1', brand: 'Nissan', model: 'Maxima', year: 2016);

  test('Batch 3 Arabic and English catalogs preserve DTCs and units', () {
    final ar = AppLocalizationsAr();
    final en = AppLocalizationsEn();

    expect(ar.vehicleRecordTitle, 'سجل السيارة');
    expect(en.vehicleRecordTitle, 'Vehicle health record');
    expect(ar.obdConnectTitle, contains('OBD-II'));
    expect(en.obdConnectTitle, contains('OBD-II'));
    expect(ar.currentObdCodesHint, contains('P0133 P0300'));
    expect(en.currentObdCodesHint, contains('P0133 P0300'));
    expect(ar.kmShort, 'كم');
    expect(en.kmShort, 'km');
  });

  test('target screens have no visible hard-coded Arabic UI literals', () {
    const files = [
      'lib/screens/cars_screen.dart',
      'lib/screens/car_health_record_screen.dart',
      'lib/screens/maintenance_screen.dart',
      'lib/screens/maintenance_history_screen.dart',
      'lib/screens/add_maintenance_record_screen.dart',
      'lib/screens/obd_connect_screen.dart',
      'lib/screens/dtc_reference_screen.dart',
      'lib/screens/workshop_mode_screen.dart',
      'lib/screens/repair_record_screen.dart',
      'lib/screens/repair_verification_screen.dart',
    ];
    final visibleArabic = RegExp(
        r'''(?:Text|SnackBar|labelText:|hintText:|tooltip:|title:)\s*\(?\s*(?:const\s+)?['"][^'"]*[\u0600-\u06FF][^'"]*['"]''');

    for (final path in files) {
      final source = File(path).readAsStringSync();
      expect(visibleArabic.allMatches(source).toList(), isEmpty,
          reason: '$path still contains visible Arabic UI text');
    }
  });

  test('OBD acquisition commands and transcript fields remain intact', () {
    final source =
        File('lib/screens/obd_connect_screen.dart').readAsStringSync();
    expect(source, contains("'HEADER: \${entry['requestHeader'] ?? ''}'"));
    expect(source, contains("'COMMAND: \${entry['command'] ?? ''}'"));
    expect(source, contains("'RAW: \${entry['raw'] ?? ''}'"));
    expect(source, contains("'RESPONDERS: \${entry['responders']"));
    expect(source, contains("'PARSED: \${entry['codes'] ?? ''}'"));
    expect(source, contains('kDebugMode && _scanner != null'));
  });

  testWidgets('workshop mode renders Arabic RTL and English LTR',
      (tester) async {
    await tester.pumpWidget(localizedApp(
      locale: const Locale('ar'),
      home: WorkshopModeScreen(
        car: car,
        symptoms: 'اهتزاز بسيط',
        codes: const ['P0300'],
        checks: const [],
      ),
    ));
    expect(find.text('وضع الورشة'), findsOneWidget);
    expect(Directionality.of(tester.element(find.text('وضع الورشة'))),
        TextDirection.rtl);

    await tester.pumpWidget(localizedApp(
      locale: const Locale('en'),
      home: WorkshopModeScreen(
        car: car,
        symptoms: 'Light vibration',
        codes: const ['P0300'],
        checks: const [],
      ),
    ));
    await tester.pump();
    expect(find.text('Workshop mode'), findsOneWidget);
    expect(Directionality.of(tester.element(find.text('Workshop mode'))),
        TextDirection.ltr);
    expect(find.text('P0300'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('repair verification is usable in English at narrow width',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(localizedApp(
      locale: const Locale('en'),
      home: RepairVerificationScreen(
        car: car,
        beforeCodes: const ['P0300'],
        beforeSymptoms: 'Light vibration',
      ),
    ));
    await tester.pump();

    expect(find.text('Repair verification'), findsOneWidget);
    expect(find.text('Current OBD codes (optional)'), findsOneWidget);
    expect(Directionality.of(tester.element(find.text('Repair verification'))),
        TextDirection.ltr);
    expect(tester.takeException(), isNull);
  });
}
