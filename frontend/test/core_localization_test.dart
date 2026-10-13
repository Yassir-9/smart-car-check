import 'package:car_ai_diagnosis/l10n/app_localizations.dart';
import 'package:car_ai_diagnosis/l10n/app_localizations_ar.dart';
import 'package:car_ai_diagnosis/l10n/app_localizations_en.dart';
import 'package:car_ai_diagnosis/locale_notifier.dart';
import 'package:car_ai_diagnosis/screens/app_shell.dart';
import 'package:car_ai_diagnosis/screens/auth_screen.dart';
import 'package:car_ai_diagnosis/screens/onboarding_screen.dart';
import 'package:car_ai_diagnosis/screens/settings_screen.dart';
import 'package:car_ai_diagnosis/services/locale_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget localizedApp({required String languageCode, required Widget home}) {
  return MaterialApp(
    locale: Locale(languageCode),
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    home: home,
  );
}

Widget notifierApp(Widget home) {
  return ValueListenableBuilder<String>(
    valueListenable: localeNotifier,
    builder: (_, code, __) => localizedApp(languageCode: code, home: home),
  );
}

void expectNoUnexpectedArabic(WidgetTester tester) {
  final arabic = RegExp(r'[\u0600-\u06FF]');
  final unexpected = tester
      .widgetList<Text>(find.byType(Text))
      .map((widget) => widget.data)
      .whereType<String>()
      .where((text) => text != 'العربية' && arabic.hasMatch(text))
      .toList();
  expect(unexpected, isEmpty);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await localeNotifier.setLanguage('ar');
  });

  test('generated Arabic and English catalogs preserve technical terms', () {
    final ar = AppLocalizationsAr();
    final en = AppLocalizationsEn();
    expect(ar.navHome, 'الرئيسية');
    expect(en.navHome, 'Home');
    expect(ar.obdCheck, contains('OBD'));
    expect(en.obdCheck, contains('OBD'));
    expect(en.mileageKm(120000), '120000 km');
  });

  test('locale service and notifier restore the persisted language', () async {
    await LocaleService.setLanguage('en');
    expect(await LocaleService.getLanguage(), 'en');

    var stored = 'ar';
    final first = LocaleNotifier(
      loadLanguage: () async => stored,
      saveLanguage: (value) async => stored = value,
    );
    await first.initialized;
    await first.setLanguage('en');
    final recreated = LocaleNotifier(
      loadLanguage: () async => stored,
      saveLanguage: (value) async => stored = value,
    );
    await recreated.initialized;
    expect(recreated.value, 'en');
  });

  testWidgets('onboarding renders complete Arabic RTL and English LTR',
      (tester) async {
    await tester.pumpWidget(localizedApp(
      languageCode: 'ar',
      home: OnboardingScreen(onDone: () {}),
    ));
    expect(find.text('افهم مشكلة سيارتك'), findsOneWidget);
    expect(Directionality.of(tester.element(find.text('التالي'))),
        TextDirection.rtl);

    await tester.pumpWidget(localizedApp(
      languageCode: 'en',
      home: OnboardingScreen(onDone: () {}),
    ));
    await tester.pump();
    expect(find.text("Understand your car's problem"), findsOneWidget);
    expect(Directionality.of(tester.element(find.text('Next'))),
        TextDirection.ltr);
    expectNoUnexpectedArabic(tester);
  });

  testWidgets('authentication renders English without Arabic UI strings',
      (tester) async {
    await tester.pumpWidget(localizedApp(
      languageCode: 'en',
      home: const AuthScreen(),
    ));
    expect(find.text('Sign in with email'), findsOneWidget);
    expect(find.text('Sign in'), findsOneWidget);
    expectNoUnexpectedArabic(tester);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'settings dropdown changes language immediately and direction flips',
      (tester) async {
    await tester.pumpWidget(notifierApp(const SettingsScreen()));
    expect(find.text('الإعدادات'), findsOneWidget);

    await tester.tap(find.byType(DropdownButton<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('English').last);
    await tester.pumpAndSettle();

    expect(localeNotifier.value, 'en');
    expect(find.text('Settings'), findsOneWidget);
    expect(Directionality.of(tester.element(find.text('Settings'))),
        TextDirection.ltr);
    expectNoUnexpectedArabic(tester);
  });

  testWidgets('app shell navigation labels are localized in English',
      (tester) async {
    await tester.pumpWidget(localizedApp(
      languageCode: 'en',
      home: const AppShell(),
    ));
    await tester.pump();
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Diagnosis'), findsOneWidget);
    expect(find.text('My cars'), findsOneWidget);
    expect(find.text('History'), findsOneWidget);
  });

  testWidgets('core screens do not overflow at a narrow mobile size',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(localizedApp(
      languageCode: 'en',
      home: OnboardingScreen(onDone: () {}),
    ));
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(localizedApp(
      languageCode: 'en',
      home: const SettingsScreen(),
    ));
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}
