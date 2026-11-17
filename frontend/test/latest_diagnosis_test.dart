import 'package:car_ai_diagnosis/models/car_model.dart';
import 'package:car_ai_diagnosis/services/latest_diagnosis_service.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> entry(String id, Map<String, dynamic> car, String ts, String? issue) => {
      'id': id,
      'car': car,
      'timestamp': ts,
      'result': {'possible_issue': issue},
    };

void main() {
  final land = CarModel(id: 'c1', brand: 'Toyota', model: 'Land Cruiser', year: 2019);
  final sunny = CarModel(id: 'c2', brand: 'Nissan', model: 'Sunny', year: 2022);

  test('picks the newest diagnosis of the active car, matching by car id', () {
    final items = [
      entry('1', {'id': 'c2', 'brand': 'Nissan'}, '2026-11-17T10:00:00Z', 'Sunny issue'),
      entry('2', {'id': 'c1', 'brand': 'Toyota'}, '2026-11-16T09:42:00Z', 'older'),
      entry('3', {'id': 'c1', 'brand': 'Toyota'}, '2026-11-16T10:19:00Z', 'اهتزاز المحرك'),
    ];
    final latest = LatestDiagnosisService.pickLatest(items, land)!;
    expect(latest.title, 'اهتزاز المحرك');
    expect(latest.date, DateTime.parse('2026-11-16T10:19:00Z'));
    expect(LatestDiagnosisService.pickLatest(items, sunny)!.title, 'Sunny issue');
  });

  test('older entries without a car id match by brand, model and year', () {
    final items = [
      entry('1', {'brand': 'Toyota', 'model': 'Land Cruiser', 'year': 2019}, '2026-10-13T00:20:00Z', 'legacy'),
    ];
    expect(LatestDiagnosisService.pickLatest(items, land)!.title, 'legacy');
    expect(LatestDiagnosisService.pickLatest(items, sunny), isNull);
  });

  test('no history, another car only, or unusable entries give null', () {
    expect(LatestDiagnosisService.pickLatest(const [], land), isNull);
    expect(
        LatestDiagnosisService.pickLatest([
          entry('1', {'id': 'c2'}, '2026-11-17T10:00:00Z', 'x'),
          entry('2', {'id': 'c1'}, 'not a date', 'x'),
          entry('3', {'id': 'c1'}, '2026-11-17T10:00:00Z', '  '),
          entry('4', {'id': 'c1'}, '2026-11-17T10:00:00Z', null),
          'garbage',
          {'car': 'no', 'result': 1},
        ], land),
        isNull);
  });

  test('forCar swallows a failing history request', () async {
    final previous = LatestDiagnosisService.historyLoader;
    LatestDiagnosisService.historyLoader = () async => throw Exception('offline');
    addTearDown(() => LatestDiagnosisService.historyLoader = previous);
    expect(await LatestDiagnosisService.forCar(land), isNull);
    LatestDiagnosisService.historyLoader = () async => [
          entry('1', {'id': 'c1'}, '2026-11-16T10:19:00Z', 'ok')
        ];
    expect((await LatestDiagnosisService.forCar(land))!.title, 'ok');
  });
}
