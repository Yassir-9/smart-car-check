import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:car_ai_diagnosis/l10n/app_localizations.dart';
import 'package:car_ai_diagnosis/screens/account_privacy_screen.dart';

Widget localizedApp(Locale locale) => MaterialApp(
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const AccountPrivacyScreen(),
    );

void main() {
  testWidgets('account privacy screen renders in Arabic RTL', (tester) async {
    await tester.pumpWidget(localizedApp(const Locale('ar')));
    expect(find.text('الخصوصية والحساب'), findsOneWidget);
    expect(find.text('أفهم ذلك، احذف حسابي'), findsOneWidget);
    expect(Directionality.of(tester.element(find.text('الخصوصية والحساب'))),
        TextDirection.rtl);
  });

  testWidgets('account privacy screen renders in English LTR', (tester) async {
    await tester.pumpWidget(localizedApp(const Locale('en')));
    expect(find.text('Privacy and account'), findsOneWidget);
    expect(find.text('I understand, delete my account'), findsOneWidget);
    expect(Directionality.of(tester.element(find.text('Privacy and account'))),
        TextDirection.ltr);
  });

  test('public privacy and deletion pages are bilingual and actionable', () {
    final privacy = File('../docs/privacy-policy.html').readAsStringSync();
    final deletion = File('../docs/delete-account.html').readAsStringSync();
    expect(privacy, contains('Firebase Authentication'));
    expect(privacy, contains('Google Gemini'));
    expect(privacy, contains('Moyasar'));
    expect(privacy, contains('حذف الحساب'));
    expect(deletion, contains('Smart Car Check account'));
    expect(deletion, contains('mailto:tv.4735@gmail.com'));
    expect(deletion, contains('طلب حذف حساب'));
  });
}
