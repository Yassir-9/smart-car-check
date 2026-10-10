import 'dart:async';

import 'package:car_ai_diagnosis/models/obd_scan_result.dart';
import 'package:car_ai_diagnosis/services/obd/elm327_protocol.dart';
import 'package:car_ai_diagnosis/services/obd/obd_scanner_service.dart';
import 'package:car_ai_diagnosis/services/obd/obd_transport.dart';
import 'package:car_ai_diagnosis/services/obd_session_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Classic ELM327 scan path remains compatible end to end', () async {
    final transport = _FakeClassicTransport();
    final protocol = Elm327Protocol(
      transport,
      resetDelay: Duration.zero,
      commandDelay: Duration.zero,
      responseDelay: const Duration(milliseconds: 1),
    );
    final scanner = ObdScannerService(transport: transport, protocol: protocol);

    final devices = await scanner.discoverDevices();
    expect(devices.single.name, 'ELM327 Classic');
    await scanner.connect(devices.single);
    final result = await scanner.scan(vehicleId: 'classic-car');
    ObdSessionService.save(result.result);

    expect(transport.commands, containsAll(['ATZ\r', 'ATE0\r', '03\r']));
    expect(result.result.codes, ['P0133']);
    expect(result.result.transportType, ObdTransportType.androidClassic);
    expect(ObdSessionService.lastCodes, ['P0133']);
    expect(ObdSessionService.lastResult?.vehicleId, 'classic-car');
    await scanner.dispose();
    ObdSessionService.clear();
  });
}

class _FakeClassicTransport implements ObdTransport {
  final _input = StreamController<List<int>>.broadcast();
  final commands = <String>[];
  ObdDevice? _device;
  String _header = '7E0';

  @override
  ObdTransportType get type => ObdTransportType.androidClassic;
  @override
  String get displayName => 'Bluetooth Classic';
  @override
  bool get isConnected => _device != null;
  @override
  ObdDevice? get connectedDevice => _device;
  @override
  Stream<List<int>> get input => _input.stream;
  @override
  Stream<List<ObdDevice>> get discoveredDevices => const Stream.empty();
  @override
  Stream<ObdConnectionState> get connectionState => const Stream.empty();
  @override
  Future<bool> isAvailable() async => true;
  @override
  Future<List<ObdDevice>> discoverDevices() async => const [
        ObdDevice(id: 'private-id', name: 'ELM327 Classic'),
      ];
  @override
  Future<void> stopDiscovery() async {}
  @override
  Future<void> connect(ObdDevice device) async => _device = device;
  @override
  Future<void> disconnect() async => _device = null;
  @override
  Future<void> write(String command) async {
    commands.add(command);
    if (command.startsWith('ATSH')) _header = command.substring(4).trim();
    if (command == '03\r') {
      final response = _header == '7E0' ? '43 01 33 00 00\r>' : 'NO DATA\r>';
      scheduleMicrotask(() => _input.add(response.codeUnits));
    }
  }

  @override
  Future<void> dispose() => _input.close();
}
