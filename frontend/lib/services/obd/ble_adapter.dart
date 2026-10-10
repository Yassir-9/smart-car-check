enum BleAdapterStatus { unknown, unavailable, unauthorized, poweredOff, ready }

enum BleDeviceConnectionState {
  disconnected,
  connecting,
  connected,
  disconnecting,
}

class BlePeripheral {
  const BlePeripheral({
    required this.id,
    required this.name,
    required this.rssi,
    this.advertisedServices = const <String>[],
  });

  final String id;
  final String name;
  final int rssi;
  final List<String> advertisedServices;
}

class BleGattCharacteristic {
  const BleGattCharacteristic({
    required this.serviceUuid,
    required this.characteristicUuid,
    this.canRead = false,
    this.canWrite = false,
    this.canWriteWithoutResponse = false,
    this.canNotify = false,
    this.canIndicate = false,
  });

  final String serviceUuid;
  final String characteristicUuid;
  final bool canRead;
  final bool canWrite;
  final bool canWriteWithoutResponse;
  final bool canNotify;
  final bool canIndicate;
}

abstract class BleAdapter {
  BleAdapterStatus get status;
  Stream<BleAdapterStatus> get statusStream;
  Stream<BlePeripheral> scan({required Duration timeout});
  Future<void> stopScan();
  Stream<BleDeviceConnectionState> connect(
    String deviceId, {
    required Duration timeout,
  });
  Future<void> disconnect(String deviceId);
  Future<List<BleGattCharacteristic>> discoverCharacteristics(String deviceId);
  Stream<List<int>> subscribe(
    String deviceId,
    BleGattCharacteristic characteristic,
  );
  Future<List<int>> read(
    String deviceId,
    BleGattCharacteristic characteristic,
  );
  Future<void> write(
    String deviceId,
    BleGattCharacteristic characteristic,
    List<int> value, {
    required bool withResponse,
  });
  Future<void> dispose();
}
