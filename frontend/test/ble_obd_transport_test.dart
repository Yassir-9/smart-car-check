import 'dart:async';

import 'package:car_ai_diagnosis/models/obd_scan_result.dart';
import 'package:car_ai_diagnosis/services/obd/ble_adapter.dart';
import 'package:car_ai_diagnosis/services/obd/ble_characteristic_selector.dart';
import 'package:car_ai_diagnosis/services/obd/ble_obd_transport.dart';
import 'package:car_ai_diagnosis/services/obd/elm327_protocol.dart';
import 'package:car_ai_diagnosis/services/obd/obd_scanner_service.dart';
import 'package:car_ai_diagnosis/services/obd/obd_transport.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BLE characteristic selection', () {
    final selector = BleCharacteristicSelector();

    test('selects Nordic UART known profile', () {
      final pair = selector.select(const [
        BleGattCharacteristic(
          serviceUuid: '6e400001-b5a3-f393-e0a9-e50e24dcca9e',
          characteristicUuid: '6e400002-b5a3-f393-e0a9-e50e24dcca9e',
          canWriteWithoutResponse: true,
        ),
        BleGattCharacteristic(
          serviceUuid: '6e400001-b5a3-f393-e0a9-e50e24dcca9e',
          characteristicUuid: '6e400003-b5a3-f393-e0a9-e50e24dcca9e',
          canNotify: true,
        ),
      ]);
      expect(pair.profileName, 'Nordic UART');
      expect(pair.write.canWriteWithoutResponse, isTrue);
      expect(pair.receive.canNotify, isTrue);
    });

    test('uses a single generic duplex characteristic', () {
      final pair = selector.select(const [
        BleGattCharacteristic(
          serviceUuid: '1234',
          characteristicUuid: '5678',
          canWrite: true,
          canNotify: true,
        ),
      ]);
      expect(pair.write.characteristicUuid,
          '00005678-0000-1000-8000-00805f9b34fb');
      expect(pair.receive, same(pair.write));
    });

    test('rejects ambiguous fallback candidates', () {
      expect(
        () => selector.select(const [
          BleGattCharacteristic(
              serviceUuid: '1000', characteristicUuid: '1001', canWrite: true),
          BleGattCharacteristic(
              serviceUuid: '1000', characteristicUuid: '1002', canWrite: true),
          BleGattCharacteristic(
              serviceUuid: '1000', characteristicUuid: '1003', canNotify: true),
        ]),
        throwsA(isA<BleCharacteristicSelectionException>()
            .having((error) => error.ambiguous, 'ambiguous', isTrue)),
      );
    });
  });

  test('reports BLE capability from adapter status', () async {
    final adapter = FakeBleAdapter(status: BleAdapterStatus.ready);
    final transport = BleObdTransport(adapter: adapter);
    expect(await transport.isAvailable(), isTrue);
    await transport.dispose();
  });

  test('scans, emits discovered devices, and stops scan', () async {
    final adapter = FakeBleAdapter(
      scanDevices: const [
        BlePeripheral(id: 'ble-1', name: 'OBD BLE', rssi: -48)
      ],
    );
    final transport = BleObdTransport(adapter: adapter);
    final emitted = expectLater(
      transport.discoveredDevices,
      emits(predicate<List<ObdDevice>>(
          (items) => items.single.name == 'OBD BLE')),
    );
    final devices = await transport.discoverDevices();
    expect(devices.single.signalStrength, -48);
    await emitted;
    await transport.stopDiscovery();
    expect(adapter.stopScanCalls, greaterThanOrEqualTo(1));
    await transport.dispose();
  });

  test('connects, discovers services, writes, receives chunks, disconnects',
      () async {
    final adapter = FakeBleAdapter();
    final transport = BleObdTransport(adapter: adapter);
    await transport.connect(const ObdDevice(id: 'ble-1', name: 'OBD BLE'));
    expect(transport.isConnected, isTrue);
    final chunkExpectation = expectLater(transport.input, emits(<int>[52, 51]));
    await transport.write('ATZ\r');
    adapter.notifications.add(<int>[52, 51]);
    await chunkExpectation;
    expect(adapter.writes.single.command, 'ATZ\r');
    await transport.disconnect();
    expect(transport.isConnected, isFalse);
    expect(adapter.disconnectCalls, 1);
    await transport.dispose();
  });

  test('times out when BLE never reaches connected state', () async {
    final adapter = FakeBleAdapter(emitConnected: false);
    final transport = BleObdTransport(
      adapter: adapter,
      connectionTimeout: const Duration(milliseconds: 10),
    );
    await expectLater(
      transport.connect(const ObdDevice(id: 'ble-1', name: 'OBD BLE')),
      throwsA(isA<TimeoutException>()),
    );
    await transport.dispose();
  });

  test('reports an unexpected connection loss', () async {
    final adapter = FakeBleAdapter();
    final transport = BleObdTransport(adapter: adapter);
    await transport.connect(const ObdDevice(id: 'ble-1', name: 'OBD BLE'));
    final disconnected = expectLater(
      transport.connectionState,
      emits(ObdConnectionState.disconnected),
    );
    adapter.connections.add(BleDeviceConnectionState.disconnected);
    await disconnected;
    expect(transport.isConnected, isFalse);
    await transport.dispose();
  });

  test('BLE transport integrates with Elm327Protocol and scanner', () async {
    final adapter = FakeBleAdapter(respondToElmCommands: true);
    final transport = BleObdTransport(adapter: adapter);
    final protocol = Elm327Protocol(
      transport,
      resetDelay: Duration.zero,
      commandDelay: Duration.zero,
      responseDelay: const Duration(milliseconds: 1),
    );
    final scanner = ObdScannerService(transport: transport, protocol: protocol);
    await scanner.connect(const ObdDevice(id: 'ble-1', name: 'OBD BLE'));
    final summary = await scanner.scan(vehicleId: 'car-1');
    expect(summary.result.codes, contains('P0133'));
    expect(summary.result.transportType, ObdTransportType.ble);
    expect(summary.result.vehicleId, 'car-1');
    await scanner.dispose();
  });
}

class FakeBleAdapter implements BleAdapter {
  FakeBleAdapter({
    this.status = BleAdapterStatus.ready,
    this.scanDevices = const [],
    this.emitConnected = true,
    this.respondToElmCommands = false,
  });

  @override
  final BleAdapterStatus status;
  final List<BlePeripheral> scanDevices;
  final bool emitConnected;
  final bool respondToElmCommands;
  final connections = StreamController<BleDeviceConnectionState>.broadcast();
  final notifications = StreamController<List<int>>.broadcast();
  final writes = <({String command, bool withResponse})>[];
  int stopScanCalls = 0;
  int disconnectCalls = 0;
  String _header = '7E0';

  @override
  Stream<BleAdapterStatus> get statusStream => Stream.value(status);

  @override
  Stream<BlePeripheral> scan({required Duration timeout}) =>
      Stream.fromIterable(scanDevices);

  @override
  Future<void> stopScan() async => stopScanCalls++;

  @override
  Stream<BleDeviceConnectionState> connect(String deviceId,
      {required Duration timeout}) {
    if (emitConnected) {
      scheduleMicrotask(
          () => connections.add(BleDeviceConnectionState.connected));
    }
    return connections.stream;
  }

  @override
  Future<void> disconnect(String deviceId) async => disconnectCalls++;

  @override
  Future<List<BleGattCharacteristic>> discoverCharacteristics(
          String deviceId) async =>
      const [
        BleGattCharacteristic(
          serviceUuid: 'FFE0',
          characteristicUuid: 'FFE1',
          canWriteWithoutResponse: true,
          canNotify: true,
        ),
      ];

  @override
  Stream<List<int>> subscribe(
          String deviceId, BleGattCharacteristic characteristic) =>
      notifications.stream;

  @override
  Future<List<int>> read(
          String deviceId, BleGattCharacteristic characteristic) async =>
      const [];

  @override
  Future<void> write(
    String deviceId,
    BleGattCharacteristic characteristic,
    List<int> value, {
    required bool withResponse,
  }) async {
    final command = String.fromCharCodes(value);
    writes.add((command: command, withResponse: withResponse));
    if (!respondToElmCommands) return;
    if (command.startsWith('ATSH')) _header = command.substring(4).trim();
    if (command == '03\r') {
      final response = _header == '7E0' ? '43 01 33 00 00\r>' : 'NO DATA\r>';
      final split = response.length ~/ 2;
      scheduleMicrotask(() {
        notifications.add(response.substring(0, split).codeUnits);
        scheduleMicrotask(
            () => notifications.add(response.substring(split).codeUnits));
      });
    }
  }

  @override
  Future<void> dispose() async {
    await connections.close();
    await notifications.close();
  }
}
