import 'package:car_ai_diagnosis/models/obd_scan_result.dart';
import 'package:car_ai_diagnosis/services/obd/elm327_protocol.dart';
import 'package:car_ai_diagnosis/services/obd/obd_transport.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Elm327Protocol protocol;

  setUp(() {
    protocol = Elm327Protocol(_FakeTransport());
  });

  test('parses standard mode 03 DTC bytes', () {
    expect(protocol.parseDtcResponse('43 01 33 02 10 00 00\r>'),
        <String>['P0133', 'P0210']);
  });

  test('parses lowercase and ignores adapter noise', () {
    expect(protocol.parseDtcResponse('SEARCHING...\r43 40 01 c1 23\r>'),
        <String>['C0001', 'U0123']);
  });

  test('returns empty list for no mode 03 response', () {
    expect(protocol.parseDtcResponse('NO DATA\r>'), isEmpty);
  });

  test('parses all response blocks and generic code families', () {
    expect(protocol.parseDtcResponse('7E8 43 01 00 02 10\r7E9 43 40 01 C0 01'),
        containsAll(<String>['P0100', 'P0210', 'C0001', 'U0001']));
  });

  test('parses pending and permanent response markers', () {
    expect(protocol.parseDtcResponse('47 01 00 4A 02 10'),
        containsAll(<String>['P0100', 'P0210']));
  });

  test('preserves P0700 and P17xx payloads', () {
    expect(protocol.parseDtcResponse('43 07 00 17 00'),
        containsAll(<String>['P0700', 'P1700']));
  });

  test('reassembles ISO-TP first and consecutive frames', () {
    expect(protocol.parseDtcResponse('7E8 10 08 43 01 00 02 10 03 00\r7E8 21 00 00'),
        containsAll(<String>['P0100', 'P0210', 'P0300']));
  });

  test('ignores malformed ISO-TP responder while retaining valid responder', () {
    expect(protocol.parseDtcResponse('7E8 10 08 43 01 00\r7E8 22 00\r7E9 03 43 01 33'),
        contains('P0133'));
  });
}

class _FakeTransport implements ObdTransport {
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
  ObdTransportType get type => ObdTransportType.unsupported;
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
  Future<bool> isAvailable() async => false;
  @override
  Future<void> write(String command) async {}
}
