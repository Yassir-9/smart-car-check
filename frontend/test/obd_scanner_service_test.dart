import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:car_ai_diagnosis/models/obd_scan_result.dart';
import 'package:car_ai_diagnosis/services/obd/elm327_protocol.dart';
import 'package:car_ai_diagnosis/services/obd/obd_scanner_service.dart';
import 'package:car_ai_diagnosis/services/obd/obd_transport.dart';

void main() {
  test('scanner preserves codes and statuses across generic modes', () async {
    final transport = _FakeTransport();
    final protocol = Elm327Protocol(transport, resetDelay: Duration.zero, commandDelay: Duration(milliseconds: 1), responseDelay: Duration(milliseconds: 50));
    final scanner = ObdScannerService(transport: transport, protocol: protocol);
    await protocol.initialize();
    final result = await scanner.scan();
    expect(result.result.codes, containsAll(<String>['P0300', 'P0420', 'P0700', 'P1700']));
    expect(result.result.codes.toSet().length, result.result.codes.length);
    final p0300 = result.result.dtcs.firstWhere((d) => d.code == 'P0300');
    expect(p0300.statuses, containsAll(<String>['stored', 'pending']));
    expect(p0300.responderHeader, isNotNull);
  });
}

class _FakeTransport implements ObdTransport {
  final _controller = StreamController<List<int>>();
  String _header = '7E0';
  @override Stream<List<int>> get input => _controller.stream;
  @override bool get isConnected => true;
  @override ObdDevice? get connectedDevice => const ObdDevice(id: 'fake', name: 'fake');
  @override ObdTransportType get type => ObdTransportType.unsupported;
  @override String get displayName => 'fake';
  @override Stream<List<ObdDevice>> get discoveredDevices => const Stream.empty();
  @override Stream<ObdConnectionState> get connectionState => const Stream.empty();
  @override Future<bool> isAvailable() async => true;
  @override Future<List<ObdDevice>> discoverDevices() async => const [];
  @override Future<void> stopDiscovery() async {}
  @override Future<void> connect(ObdDevice device) async {}
  @override Future<void> disconnect() async {}
  @override Future<void> dispose() async => _controller.close();
  @override Future<void> write(String command) async {
    if (command.startsWith('ATSH')) _header = command.substring(4, 7);
    String response = '';
    if (command.startsWith('0100')) response = '7E8\r7E9\r>';
    if (command.startsWith('03')) response = _header == '7E0' ? '43 03 00 04 20 00 00\r>' : '43 07 00 17 00 00\r>';
    if (command.startsWith('07')) response = _header == '7E0' ? '47 03 00 00 00\r>' : '47 01 00 00 00\r>';
    if (command.startsWith('0A')) response = 'NO DATA\r>';
    // ignore transcript in production; test trace only
    // ignore: avoid_print
    print('HEADER=$_header COMMAND=${command.trim()} RESPONSE=$response');
    if (response.isNotEmpty) _controller.add(response.codeUnits);
  }
}
