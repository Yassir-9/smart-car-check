import 'dart:async';

import 'package:flutter_blue_classic/flutter_blue_classic.dart';

import '../../models/obd_scan_result.dart';
import 'obd_transport.dart';

class AndroidClassicObdTransport implements ObdTransport {
  AndroidClassicObdTransport({FlutterBlueClassic? bluetooth})
      : _bluetooth = bluetooth ?? FlutterBlueClassic(usesFineLocation: true);

  final FlutterBlueClassic _bluetooth;
  BluetoothConnection? _connection;
  ObdDevice? _connectedDevice;
  StreamSubscription<List<int>>? _inputSubscription;
  final StreamController<List<int>> _inputController =
      StreamController<List<int>>.broadcast();
  final StreamController<List<ObdDevice>> _devicesController =
      StreamController<List<ObdDevice>>.broadcast();
  final StreamController<ObdConnectionState> _connectionController =
      StreamController<ObdConnectionState>.broadcast();

  @override
  ObdTransportType get type => ObdTransportType.androidClassic;
  @override
  String get displayName => 'Bluetooth Classic';
  @override
  bool get isConnected => _connection?.isConnected ?? false;
  @override
  ObdDevice? get connectedDevice => _connectedDevice;
  @override
  Stream<List<int>> get input => _inputController.stream;
  @override
  Stream<List<ObdDevice>> get discoveredDevices => _devicesController.stream;
  @override
  Stream<ObdConnectionState> get connectionState =>
      _connectionController.stream;

  @override
  Future<bool> isAvailable() async => _bluetooth.isSupported;

  @override
  Future<List<ObdDevice>> discoverDevices() async {
    final devices = await _bluetooth.bondedDevices ?? const <BluetoothDevice>[];
    final results = devices
        .map((device) => ObdDevice(
              id: device.address,
              name: device.name ?? 'جهاز غير معروف',
            ))
        .toList(growable: false);
    _devicesController.add(results);
    return results;
  }

  @override
  Future<void> stopDiscovery() async {}

  @override
  Future<void> connect(ObdDevice device) async {
    await disconnect();
    _connectionController.add(ObdConnectionState.connecting);
    final connection = await _bluetooth.connect(device.id);
    if (connection == null || !connection.isConnected) {
      throw StateError('فشل الاتصال بالجهاز');
    }
    _connection = connection;
    _connectedDevice = device;
    _connectionController.add(ObdConnectionState.connected);
    _inputSubscription = connection.input?.listen(
      (data) => _inputController.add(data),
      onError: _inputController.addError,
    );
  }

  @override
  Future<void> write(String command) async {
    final connection = _connection;
    if (connection == null || !connection.isConnected) {
      throw StateError('لا يوجد جهاز OBD متصل');
    }
    connection.writeString(command);
  }

  @override
  Future<void> disconnect() async {
    if (_connection != null) {
      _connectionController.add(ObdConnectionState.disconnecting);
    }
    await _inputSubscription?.cancel();
    _inputSubscription = null;
    _connection?.dispose();
    _connection = null;
    _connectedDevice = null;
    _connectionController.add(ObdConnectionState.disconnected);
  }

  @override
  Future<void> dispose() async {
    await disconnect();
    await _inputController.close();
    await _devicesController.close();
    await _connectionController.close();
  }
}
