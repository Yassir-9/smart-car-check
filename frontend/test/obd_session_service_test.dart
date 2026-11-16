import 'package:car_ai_diagnosis/models/obd_scan_result.dart';
import 'package:car_ai_diagnosis/services/obd_session_service.dart';
import 'package:flutter_test/flutter_test.dart';

ObdScanResult scan({String? vehicleId, required DateTime at, List<String> codes = const ['P0300']}) =>
    ObdScanResult(
      codes: codes,
      transportType: ObdTransportType.ble,
      timestamp: at,
      vehicleId: vehicleId,
    );

void main() {
  final t0 = DateTime(2026, 11, 16, 12, 0);

  setUp(ObdSessionService.clear);

  test('codes are used for the same car within 30 minutes', () {
    ObdSessionService.save(scan(vehicleId: 'car-a', at: t0));
    final now = t0.add(const Duration(minutes: 29, seconds: 59));
    expect(ObdSessionService.codesFor('car-a', now: now), ['P0300']);
    expect(ObdSessionService.scanFor('car-a', now: now), isNotNull);
    expect(ObdSessionService.problemFor('car-a', now: now), isNull);
  });

  test('codes expire at 30 minutes', () {
    ObdSessionService.save(scan(vehicleId: 'car-a', at: t0));
    final now = t0.add(const Duration(minutes: 30));
    expect(ObdSessionService.codesFor('car-a', now: now), isEmpty);
    expect(ObdSessionService.problemFor('car-a', now: now), ObdScanProblem.expired);
  });

  test('codes of another car are never returned', () {
    ObdSessionService.save(scan(vehicleId: 'car-a', at: t0));
    expect(ObdSessionService.codesFor('car-b', now: t0), isEmpty);
    expect(ObdSessionService.problemFor('car-b', now: t0), ObdScanProblem.otherVehicle);
  });

  test('a scan without a vehicle id, or no selected car, is not used', () {
    ObdSessionService.save(scan(vehicleId: null, at: t0));
    expect(ObdSessionService.codesFor('car-a', now: t0), isEmpty);
    ObdSessionService.save(scan(vehicleId: 'car-a', at: t0));
    expect(ObdSessionService.codesFor(null, now: t0), isEmpty);
  });

  test('changing car clears the saved scan, keeping the same car does not', () {
    ObdSessionService.save(scan(vehicleId: 'car-a', at: t0));
    ObdSessionService.clearIfOtherVehicle('car-a');
    expect(ObdSessionService.hasSavedData, isTrue);
    ObdSessionService.clearIfOtherVehicle('car-b');
    expect(ObdSessionService.hasSavedData, isFalse);
    expect(ObdSessionService.lastCodes, isEmpty);
  });

  test('ignoring hides the codes until a new scan is saved', () {
    ObdSessionService.save(scan(vehicleId: 'car-a', at: t0));
    ObdSessionService.ignore();
    expect(ObdSessionService.codesFor('car-a', now: t0), isEmpty);
    expect(ObdSessionService.problemFor('car-a', now: t0), isNull);
    ObdSessionService.save(scan(vehicleId: 'car-a', at: t0));
    expect(ObdSessionService.codesFor('car-a', now: t0), ['P0300']);
  });

  test('scan time is formatted day/month/year hour:minute', () {
    expect(formatObdScanTime(DateTime(2026, 1, 5, 9, 7)), '05/01/2026 09:07');
  });
}
