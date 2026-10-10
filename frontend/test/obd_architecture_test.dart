import 'package:car_ai_diagnosis/models/obd_scan_result.dart';
import 'package:car_ai_diagnosis/services/obd/obd_transport.dart';
import 'package:car_ai_diagnosis/services/obd/obd_transport_factory.dart';
import 'package:car_ai_diagnosis/services/obd/unsupported_obd_transport.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ObdCapabilities', () {
    test('reports no transport when every capability is disabled', () {
      const capabilities = ObdCapabilities();
      expect(capabilities.hasAnyTransport, isFalse);
      expect(capabilities.supports(ObdTransportType.ble), isFalse);
    });

    test('supports enabled transports independently of platform', () {
      const capabilities = ObdCapabilities(
        bleAvailable: true,
        wifiAvailable: true,
      );
      expect(capabilities.hasAnyTransport, isTrue);
      expect(capabilities.supports(ObdTransportType.ble), isTrue);
      expect(capabilities.supports(ObdTransportType.wifi), isTrue);
      expect(capabilities.supports(ObdTransportType.androidClassic), isFalse);
    });
  });

  group('ObdTransportFactory', () {
    test('returns unsupported transport when no capability is available', () {
      final factory =
          ObdTransportFactory(capabilities: const ObdCapabilities());
      expect(factory.create(), isA<UnsupportedObdTransport>());
    });

    test('uses injected driver for an enabled capability', () {
      final fake = _FakeTransport(ObdTransportType.ble);
      final factory = ObdTransportFactory(
        capabilities: const ObdCapabilities(bleAvailable: true),
        bleBuilder: () => fake,
      );
      expect(factory.create(), same(fake));
    });

    test('does not create a requested unavailable driver', () {
      final factory = ObdTransportFactory(
        capabilities: const ObdCapabilities(wifiAvailable: true),
      );
      expect(
          factory.create(ObdTransportType.ble), isA<UnsupportedObdTransport>());
    });

    test('exposes Classic and BLE together when both are available', () {
      final factory = ObdTransportFactory(
        capabilities: const ObdCapabilities(
          classicAvailable: true,
          bleAvailable: true,
        ),
      );
      expect(
        factory.availableTypes(factory.capabilities),
        [ObdTransportType.androidClassic, ObdTransportType.ble],
      );
    });

    test('detects adapter capability through injected drivers', () async {
      final factory = ObdTransportFactory(
        capabilities: const ObdCapabilities(
          classicAvailable: true,
          bleAvailable: true,
        ),
        classicBuilder: () => _FakeTransport(
          ObdTransportType.androidClassic,
          available: true,
        ),
        bleBuilder: () =>
            _FakeTransport(ObdTransportType.ble, available: false),
      );
      final detected = await factory.detectCapabilities();
      expect(detected.classicAvailable, isTrue);
      expect(detected.bleAvailable, isFalse);
    });
  });

  test('unsupported transport fails safely without hardware', () async {
    const transport = UnsupportedObdTransport();
    expect(await transport.isAvailable(), isFalse);
    expect(transport.input, emitsDone);
    await expectLater(
      transport.discoverDevices(),
      throwsA(isA<ObdUnsupportedException>()),
    );
  });

  test('ObdScanResult serializes without a hardware address', () {
    final timestamp = DateTime.utc(2026, 8, 23, 12);
    final result = ObdScanResult(
      codes: const ['P0133'],
      deviceName: 'ELM327',
      transportType: ObdTransportType.androidClassic,
      vehicleId: 'car-1',
      timestamp: timestamp,
      connectionMetadata: const {'transmissionEcu': 'available'},
    );
    final json = result.toJson();
    final restored = ObdScanResult.fromJson(json);

    expect(restored.codes, ['P0133']);
    expect(restored.deviceName, 'ELM327');
    expect(restored.transportType, ObdTransportType.androidClassic);
    expect(restored.vehicleId, 'car-1');
    expect(restored.timestamp, timestamp);
    expect(json.keys, isNot(contains('address')));
    expect(json.keys, isNot(contains('macAddress')));
  });
}

class _FakeTransport implements ObdTransport {
  _FakeTransport(this.type, {this.available = true});
  @override
  final ObdTransportType type;
  final bool available;
  @override
  ObdDevice? get connectedDevice => null;
  @override
  String get displayName => 'fake';
  @override
  Stream<List<int>> get input => const Stream.empty();
  @override
  Stream<List<ObdDevice>> get discoveredDevices => const Stream.empty();
  @override
  Stream<ObdConnectionState> get connectionState => const Stream.empty();
  @override
  bool get isConnected => false;
  @override
  Future<void> connect(ObdDevice device) async {}
  @override
  Future<void> disconnect() async {}
  @override
  Future<List<ObdDevice>> discoverDevices() async => const [];
  @override
  Future<void> stopDiscovery() async {}
  @override
  Future<void> dispose() async {}
  @override
  Future<bool> isAvailable() async => available;
  @override
  Future<void> write(String command) async {}
}
