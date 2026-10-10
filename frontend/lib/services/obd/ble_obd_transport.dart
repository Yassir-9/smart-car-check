import 'dart:async';
import 'dart:convert';

import '../../models/obd_scan_result.dart';
import 'ble_adapter.dart';
import 'ble_characteristic_selector.dart';
import 'obd_transport.dart';
import 'reactive_ble_adapter.dart';

class BleObdTransport implements ObdTransport {
  BleObdTransport({
    BleAdapter? adapter,
    BleCharacteristicSelector? selector,
    this.scanTimeout = const Duration(seconds: 8),
    this.connectionTimeout = const Duration(seconds: 12),
  })  : _adapter = adapter ?? ReactiveBleAdapter(),
        _selector = selector ?? BleCharacteristicSelector();

  final BleAdapter _adapter;
  final BleCharacteristicSelector _selector;
  final Duration scanTimeout;
  final Duration connectionTimeout;
  final _inputController = StreamController<List<int>>.broadcast();
  final _devicesController = StreamController<List<ObdDevice>>.broadcast();
  final _connectionController =
      StreamController<ObdConnectionState>.broadcast();
  final _diagnosticsController = StreamController<String>.broadcast();
  final Map<String, ObdDevice> _devices = {};
  StreamSubscription<BlePeripheral>? _scanSubscription;
  StreamSubscription<BleDeviceConnectionState>? _connectionSubscription;
  StreamSubscription<List<int>>? _notificationSubscription;
  ObdDevice? _connectedDevice;
  BleCharacteristicPair? _characteristics;
  bool _connected = false;

  @override
  ObdTransportType get type => ObdTransportType.ble;
  @override
  String get displayName => 'Bluetooth LE';
  @override
  bool get isConnected => _connected;
  @override
  ObdDevice? get connectedDevice => _connectedDevice;
  @override
  Stream<List<int>> get input => _inputController.stream;
  @override
  Stream<List<ObdDevice>> get discoveredDevices => _devicesController.stream;
  @override
  Stream<ObdConnectionState> get connectionState =>
      _connectionController.stream;
  Stream<String> get diagnostics => _diagnosticsController.stream;

  @override
  Future<bool> isAvailable() async {
    if (_adapter.status == BleAdapterStatus.ready) return true;
    try {
      final status = await _adapter.statusStream
          .firstWhere((value) => value != BleAdapterStatus.unknown)
          .timeout(const Duration(seconds: 3));
      return status == BleAdapterStatus.ready;
    } on TimeoutException {
      return false;
    }
  }

  @override
  Future<List<ObdDevice>> discoverDevices() async {
    if (!await isAvailable()) {
      throw StateError('Bluetooth LE غير متاح أو لم تُمنح صلاحيته.');
    }
    _devices.clear();
    final complete = Completer<void>();
    await _scanSubscription?.cancel();
    _scanSubscription = _adapter.scan(timeout: scanTimeout).listen(
      (peripheral) {
        final device = ObdDevice(
          id: peripheral.id,
          name: peripheral.name.trim().isEmpty
              ? 'جهاز BLE بدون اسم'
              : peripheral.name,
          signalStrength: peripheral.rssi,
        );
        _devices[device.id] = device;
        _devicesController.add(_devices.values.toList(growable: false));
      },
      onError: complete.completeError,
      onDone: complete.complete,
    );
    await complete.future.timeout(scanTimeout + const Duration(seconds: 1),
        onTimeout: () async => stopDiscovery());
    return _devices.values.toList(growable: false);
  }

  @override
  Future<void> stopDiscovery() async {
    await _scanSubscription?.cancel();
    _scanSubscription = null;
    await _adapter.stopScan();
  }

  @override
  Future<void> connect(ObdDevice device) async {
    await stopDiscovery();
    await disconnect();
    _connectionController.add(ObdConnectionState.connecting);
    final ready = Completer<void>();
    _connectionSubscription = _adapter
        .connect(device.id, timeout: connectionTimeout)
        .listen((state) async {
      switch (state) {
        case BleDeviceConnectionState.connected:
          _connected = true;
          _connectedDevice = device;
          _connectionController.add(ObdConnectionState.connected);
          if (!ready.isCompleted) ready.complete();
        case BleDeviceConnectionState.disconnected:
          _connected = false;
          _connectedDevice = null;
          _characteristics = null;
          _connectionController.add(ObdConnectionState.disconnected);
          if (!ready.isCompleted) {
            ready.completeError(StateError('تعذر الاتصال بجهاز BLE.'));
          }
        case BleDeviceConnectionState.connecting:
          _connectionController.add(ObdConnectionState.connecting);
        case BleDeviceConnectionState.disconnecting:
          _connectionController.add(ObdConnectionState.disconnecting);
      }
    }, onError: (Object error) {
      if (!ready.isCompleted) ready.completeError(error);
      _connectionController.addError(error);
    });
    try {
      await ready.future.timeout(connectionTimeout);
      final discovered = await _adapter
          .discoverCharacteristics(device.id)
          .timeout(connectionTimeout);
      _characteristics = _selector.select(discovered);
      _diagnosticsController.add(
          'BLE profile selected: ${_characteristics!.profileName}; characteristics: ${discovered.length}');
      final receive = _characteristics!.receive;
      if (receive.canNotify || receive.canIndicate) {
        _notificationSubscription = _adapter
            .subscribe(device.id, receive)
            .listen(_inputController.add, onError: _inputController.addError);
      }
    } catch (_) {
      await disconnect();
      rethrow;
    }
  }

  @override
  Future<void> write(String command) async {
    final device = _connectedDevice;
    final characteristics = _characteristics;
    if (!_connected || device == null || characteristics == null) {
      throw StateError('لا يوجد جهاز BLE OBD متصل');
    }
    final write = characteristics.write;
    await _adapter
        .write(
          device.id,
          write,
          ascii.encode(command),
          withResponse: write.canWrite,
        )
        .timeout(connectionTimeout);
    final receive = characteristics.receive;
    if (!receive.canNotify && !receive.canIndicate && receive.canRead) {
      final value =
          await _adapter.read(device.id, receive).timeout(connectionTimeout);
      if (value.isNotEmpty) _inputController.add(value);
    }
  }

  @override
  Future<void> disconnect() async {
    final deviceId = _connectedDevice?.id;
    await _notificationSubscription?.cancel();
    _notificationSubscription = null;
    await _connectionSubscription?.cancel();
    _connectionSubscription = null;
    if (deviceId != null) await _adapter.disconnect(deviceId);
    _connected = false;
    _connectedDevice = null;
    _characteristics = null;
    _connectionController.add(ObdConnectionState.disconnected);
  }

  @override
  Future<void> dispose() async {
    await stopDiscovery();
    await disconnect();
    await _adapter.dispose();
    await _inputController.close();
    await _devicesController.close();
    await _connectionController.close();
    await _diagnosticsController.close();
  }
}
