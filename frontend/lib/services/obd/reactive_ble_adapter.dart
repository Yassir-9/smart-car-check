import 'dart:async';

import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

import 'ble_adapter.dart';

class ReactiveBleAdapter implements BleAdapter {
  ReactiveBleAdapter({FlutterReactiveBle? client})
      : _client = client ?? FlutterReactiveBle();

  final FlutterReactiveBle _client;
  StreamSubscription<DiscoveredDevice>? _scanSubscription;
  final Map<String, StreamSubscription<ConnectionStateUpdate>>
      _connectionSubscriptions = {};
  final Map<String, StreamController<BleDeviceConnectionState>>
      _connectionControllers = {};

  @override
  BleAdapterStatus get status => _mapStatus(_client.status);

  @override
  Stream<BleAdapterStatus> get statusStream =>
      _client.statusStream.map(_mapStatus).distinct();

  @override
  Stream<BlePeripheral> scan({required Duration timeout}) {
    final controller = StreamController<BlePeripheral>();
    _scanSubscription?.cancel();
    _scanSubscription = _client.scanForDevices(
      withServices: const [],
      scanMode: ScanMode.lowLatency,
      requireLocationServicesEnabled: false,
    ).listen(
      (device) => controller.add(BlePeripheral(
        id: device.id,
        name: device.name,
        rssi: device.rssi,
        advertisedServices:
            device.serviceUuids.map((uuid) => uuid.toString()).toList(),
      )),
      onError: controller.addError,
      onDone: controller.close,
    );
    Future<void>.delayed(timeout, () async {
      await stopScan();
      if (!controller.isClosed) await controller.close();
    });
    return controller.stream;
  }

  @override
  Future<void> stopScan() async {
    await _scanSubscription?.cancel();
    _scanSubscription = null;
  }

  @override
  Stream<BleDeviceConnectionState> connect(
    String deviceId, {
    required Duration timeout,
  }) {
    final controller = StreamController<BleDeviceConnectionState>.broadcast();
    _connectionControllers[deviceId] = controller;
    _connectionSubscriptions[deviceId]?.cancel();
    _connectionSubscriptions[deviceId] = _client
        .connectToDevice(id: deviceId, connectionTimeout: timeout)
        .listen(
          (update) => controller.add(_mapConnection(update.connectionState)),
          onError: controller.addError,
          onDone: controller.close,
        );
    return controller.stream;
  }

  @override
  Future<void> disconnect(String deviceId) async {
    await _connectionSubscriptions.remove(deviceId)?.cancel();
    final controller = _connectionControllers.remove(deviceId);
    if (controller != null && !controller.isClosed) {
      controller.add(BleDeviceConnectionState.disconnected);
      await controller.close();
    }
  }

  @override
  Future<List<BleGattCharacteristic>> discoverCharacteristics(
      String deviceId) async {
    await _client.discoverAllServices(deviceId);
    final services = await _client.getDiscoveredServices(deviceId);
    return [
      for (final service in services)
        for (final characteristic in service.characteristics)
          BleGattCharacteristic(
            serviceUuid: service.id.toString(),
            characteristicUuid: characteristic.id.toString(),
            canRead: characteristic.isReadable,
            canWrite: characteristic.isWritableWithResponse,
            canWriteWithoutResponse: characteristic.isWritableWithoutResponse,
            canNotify: characteristic.isNotifiable,
            canIndicate: characteristic.isIndicatable,
          ),
    ];
  }

  QualifiedCharacteristic _qualified(
    String deviceId,
    BleGattCharacteristic characteristic,
  ) =>
      QualifiedCharacteristic(
        deviceId: deviceId,
        serviceId: Uuid.parse(characteristic.serviceUuid),
        characteristicId: Uuid.parse(characteristic.characteristicUuid),
      );

  @override
  Stream<List<int>> subscribe(
    String deviceId,
    BleGattCharacteristic characteristic,
  ) =>
      _client.subscribeToCharacteristic(_qualified(deviceId, characteristic));

  @override
  Future<List<int>> read(
    String deviceId,
    BleGattCharacteristic characteristic,
  ) =>
      _client.readCharacteristic(_qualified(deviceId, characteristic));

  @override
  Future<void> write(
    String deviceId,
    BleGattCharacteristic characteristic,
    List<int> value, {
    required bool withResponse,
  }) {
    final qualified = _qualified(deviceId, characteristic);
    if (withResponse) {
      return _client.writeCharacteristicWithResponse(
        qualified,
        value: value,
      );
    }
    return _client.writeCharacteristicWithoutResponse(
      qualified,
      value: value,
    );
  }

  @override
  Future<void> dispose() async {
    await stopScan();
    for (final subscription in _connectionSubscriptions.values) {
      await subscription.cancel();
    }
    _connectionSubscriptions.clear();
    for (final controller in _connectionControllers.values) {
      if (!controller.isClosed) await controller.close();
    }
    _connectionControllers.clear();
    await _client.deinitialize();
  }

  BleAdapterStatus _mapStatus(BleStatus status) => switch (status) {
        BleStatus.ready => BleAdapterStatus.ready,
        BleStatus.poweredOff => BleAdapterStatus.poweredOff,
        BleStatus.unauthorized => BleAdapterStatus.unauthorized,
        BleStatus.unsupported => BleAdapterStatus.unavailable,
        BleStatus.locationServicesDisabled ||
        BleStatus.unknown =>
          BleAdapterStatus.unknown,
      };

  BleDeviceConnectionState _mapConnection(DeviceConnectionState state) =>
      switch (state) {
        DeviceConnectionState.connecting => BleDeviceConnectionState.connecting,
        DeviceConnectionState.connected => BleDeviceConnectionState.connected,
        DeviceConnectionState.disconnecting =>
          BleDeviceConnectionState.disconnecting,
        DeviceConnectionState.disconnected =>
          BleDeviceConnectionState.disconnected,
      };
}
