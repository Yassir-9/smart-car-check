import 'dart:io';

import 'package:car_ai_diagnosis/l10n/app_localizations.dart';
import 'package:car_ai_diagnosis/l10n/app_localizations_ar.dart';
import 'package:car_ai_diagnosis/l10n/app_localizations_en.dart';
import 'package:car_ai_diagnosis/screens/add_part_screen.dart';
import 'package:car_ai_diagnosis/screens/cart_screen.dart';
import 'package:car_ai_diagnosis/services/cart_service.dart';
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
  setUp(CartService.clear);

  test('Batch 4 catalogs expose matching marketplace, Plus, and PDF labels',
      () {
    final ar = AppLocalizationsAr();
    final en = AppLocalizationsEn();
    expect(ar.marketplaceTitle, 'سوق قطع الغيار');
    expect(en.marketplaceTitle, 'Parts marketplace');
    expect(ar.subscription, 'الاشتراك');
    expect(en.subscription, 'Subscription');
    expect(en.pdfSeverity, 'Severity');
    expect(ar.sarShort, 'ر.س');
    expect(en.sarShort, 'SAR');
  });

  test('target UI and PDF source contains no visible hard-coded Arabic', () {
    const files = [
      'lib/screens/parts_screen.dart',
      'lib/screens/cart_screen.dart',
      'lib/screens/add_part_screen.dart',
      'lib/screens/seller_dashboard_screen.dart',
      'lib/screens/subscription_screen.dart',
      'lib/services/pdf_service.dart',
    ];
    final visibleArabic = RegExp(
        r'''(?:Text|SnackBar|labelText:|hintText:|tooltip:|title:)\s*\(?\s*(?:const\s+)?['"][^'"]*[\u0600-\u06FF][^'"]*['"]''');
    for (final path in files) {
      final source = File(path).readAsStringSync();
      expect(visibleArabic.allMatches(source), isEmpty,
          reason: '$path contains visible hard-coded Arabic');
    }
  });

  test('web metadata identifies both Arabic and English product audiences', () {
    final index = File('web/index.html').readAsStringSync();
    final manifest = File('web/manifest.json').readAsStringSync();
    expect(index, contains('Smart Car Check'));
    expect(index, contains('فحص السيارة الذكي'));
    expect(manifest, contains('AI vehicle diagnosis'));
  });

  testWidgets('empty cart renders Arabic RTL and English LTR', (tester) async {
    await tester.pumpWidget(
        localizedApp(locale: const Locale('ar'), home: const CartScreen()));
    expect(find.text('السلة فارغة حالياً'), findsOneWidget);
    expect(Directionality.of(tester.element(find.text('سلة المشتريات'))),
        TextDirection.rtl);

    await tester.pumpWidget(
        localizedApp(locale: const Locale('en'), home: const CartScreen()));
    await tester.pump();
    expect(find.text('Your cart is empty'), findsOneWidget);
    expect(Directionality.of(tester.element(find.text('Shopping cart'))),
        TextDirection.ltr);
  });

  testWidgets('add-part form is usable in English at narrow width',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
        localizedApp(locale: const Locale('en'), home: const AddPartScreen()));
    await tester.pump();
    expect(find.text('List a part for sale'), findsOneWidget);
    expect(find.text('Part name'), findsOneWidget);
    expect(find.text('New'), findsOneWidget);
    expect(find.text('Used'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
