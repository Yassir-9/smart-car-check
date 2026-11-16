import 'package:car_ai_diagnosis/config/feature_flags.dart';
import 'package:car_ai_diagnosis/l10n/app_localizations.dart';
import 'package:car_ai_diagnosis/l10n/app_localizations_ar.dart';
import 'package:car_ai_diagnosis/models/car_model.dart';
import 'package:car_ai_diagnosis/screens/diagnosis_result_screen.dart';
import 'package:car_ai_diagnosis/services/part_search_service.dart';
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

Map<String, dynamic> resultWith(List<String> parts) => {
      'title': 'Possible ignition issue',
      'summary': 'A direct inspection is recommended.',
      'severity': 'medium',
      'confidence_score': 70,
      'can_drive': true,
      'drive_advice': 'Drive carefully.',
      'likely_causes': ['Worn parts'],
      'recommended_checks': ['Inspect ignition components'],
      'possible_parts': parts,
      'next_step': 'Book a qualified inspection',
      'obd_codes': [],
    };

final car = CarModel(
    id: 'car-1',
    brand: 'Nissan',
    model: 'Maxima',
    year: 2016,
    vin: '1HGCM82633A004352',
    engineType: 'V6');

Future<void> pumpResult(WidgetTester tester, Locale locale, List<String> parts) async {
  await tester.binding.setSurfaceSize(const Size(390, 1600));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(localizedApp(
      locale: locale,
      home: DiagnosisResultScreen(
          car: car, symptoms: 'noise', result: resultWith(parts))));
  await tester.pumpAndSettle();
}

void main() {
  final launched = <Uri>[];
  late Future<List<PartStore>?> Function() originalLoader;
  late Future<bool> Function(Uri) originalLauncher;

  setUp(() {
    launched.clear();
    originalLoader = PartSearchService.storesLoader;
    originalLauncher = PartSearchService.launcher;
    PartSearchService.launcher = (uri) async {
      launched.add(uri);
      return true;
    };
  });
  tearDown(() {
    PartSearchService.storesLoader = originalLoader;
    PartSearchService.launcher = originalLauncher;
  });

  test('the parts guide is on in the app by default and independent of the marketplace', () {
    expect(FeatureFlags.partsGuideEnabled, isTrue);
    expect(FeatureFlags.marketplaceEnabled, isFalse);
  });

  testWidgets('Arabic: section title and one "find the part" button per part', (tester) async {
    final semantics = tester.ensureSemantics();
    await pumpResult(tester, const Locale('ar'), ['تيل فرامل', 'شمعات']);
    expect(find.text('قطع قد تكون مرتبطة'), findsOneWidget);
    expect(find.text('تيل فرامل'), findsOneWidget);
    expect(find.text('شمعات'), findsOneWidget);
    expect(find.text('ابحث عن القطعة'), findsNWidgets(2));
    expect(find.bySemanticsLabel('ابحث عن القطعة: تيل فرامل'), findsOneWidget);
    // the safety notice stays with the list
    expect(find.text(AppLocalizationsAr().doNotReplaceBeforeInspection), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('English: title, buttons and the section is hidden without parts', (tester) async {
    await pumpResult(tester, const Locale('en'), ['Brake pads']);
    expect(find.text('Parts that may be related'), findsOneWidget);
    expect(find.text('Find part'), findsOneWidget);
    await pumpResult(tester, const Locale('en'), []);
    expect(find.text('Parts that may be related'), findsNothing);
    expect(find.text('Find part'), findsNothing);
  });

  testWidgets('sheet lists the allowed stores with the marketing-link tag and disclosure; links carry only part/make/model/year', (tester) async {
    PartSearchService.storesLoader = () async =>
        [const PartStore('speero', 'SPEERO / سبيرو'), const PartStore('web', 'Google')];
    await pumpResult(tester, const Locale('en'), ['Brake pads']);
    await tester.tap(find.text('Find part'));
    await tester.pumpAndSettle();

    expect(find.text('SPEERO / سبيرو'), findsOneWidget);
    expect(find.text('Google'), findsOneWidget);
    expect(find.text('Marketing link'), findsNWidgets(2));
    expect(find.textContaining('may be marketing (affiliate) links'), findsOneWidget);
    expect(find.text('Nissan Maxima 2016 Brake pads'), findsOneWidget);

    await tester.tap(find.text('SPEERO / سبيرو'));
    await tester.pumpAndSettle();
    expect(launched, hasLength(1));
    final uri = launched.single;
    expect(uri.path, '/go/speero');
    expect(uri.queryParameters, {
      'part': 'Brake pads',
      'make': 'Nissan',
      'model': 'Maxima',
      'year': '2016',
    });
    // never the VIN, the engine type or any identifier
    expect(uri.toString(), isNot(contains('1HGCM82633A004352')));
    expect(uri.toString(), isNot(contains('V6')));
  });

  testWidgets('when /go answers 404 (feature off) the sheet falls back to a general web search instead of failing', (tester) async {
    PartSearchService.storesLoader = () async => null;
    await pumpResult(tester, const Locale('ar'), ['تيل فرامل']);
    await tester.tap(find.text('ابحث عن القطعة'));
    await tester.pumpAndSettle();

    expect(find.text('بحث عام على الويب'), findsOneWidget);
    expect(find.text('رابط تسويقي'), findsNothing);
    // the disclosure is always shown next to the buttons
    expect(find.textContaining('روابط تسويقية'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('بحث عام على الويب'));
    await tester.pumpAndSettle();
    final uri = launched.single;
    expect(uri.host, 'www.google.com');
    expect(uri.queryParameters['q'], 'Nissan Maxima 2016 تيل فرامل');
  });

  testWidgets('a store list that fails to load in time still shows the fallback', (tester) async {
    PartSearchService.storesLoader = () async => throw Exception('offline');
    await pumpResult(tester, const Locale('en'), ['Brake pads']);
    await tester.tap(find.text('Find part'));
    await tester.pumpAndSettle();
    // FutureBuilder surfaces the error as "no stores": fallback button still there
    expect(find.text('Search the web'), findsOneWidget);
  });

  test('store URLs and the search text never contain a VIN or user id', () {
    final uri = PartSearchService.storeUri('speero',
        part: 'Oil filter', make: 'Toyota', model: 'Camry', year: 2020);
    expect(uri.queryParameters.keys.toSet(), {'part', 'make', 'model', 'year'});
    expect(buildPartSearchQuery(part: 'Oil filter', make: 'Toyota', model: 'Camry', year: 2020),
        'Toyota Camry 2020 Oil filter');
  });
}
