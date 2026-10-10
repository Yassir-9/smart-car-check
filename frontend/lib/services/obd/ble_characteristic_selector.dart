import 'ble_adapter.dart';

class BleCharacteristicPair {
  const BleCharacteristicPair({
    required this.write,
    required this.receive,
    required this.profileName,
  });

  final BleGattCharacteristic write;
  final BleGattCharacteristic receive;
  final String profileName;
}

class BleCharacteristicSelectionException implements Exception {
  const BleCharacteristicSelectionException(this.message,
      {this.ambiguous = false});
  final String message;
  final bool ambiguous;
  @override
  String toString() => message;
}

class BleCharacteristicSelector {
  static const _nordicService = '6e400001-b5a3-f393-e0a9-e50e24dcca9e';
  static const _nordicWrite = '6e400002-b5a3-f393-e0a9-e50e24dcca9e';
  static const _nordicNotify = '6e400003-b5a3-f393-e0a9-e50e24dcca9e';

  BleCharacteristicPair select(List<BleGattCharacteristic> characteristics) {
    final normalized = characteristics.map(_normalized).toList();

    final nordic = _knownPair(
      normalized,
      service: _nordicService,
      writeUuid: _nordicWrite,
      receiveUuid: _nordicNotify,
      profile: 'Nordic UART',
    );
    if (nordic != null) return nordic;

    for (final profile in const [
      (
        '0000ffe0-0000-1000-8000-00805f9b34fb',
        '0000ffe1-0000-1000-8000-00805f9b34fb',
        'FFE0 UART'
      ),
      (
        '0000fff0-0000-1000-8000-00805f9b34fb',
        '0000fff1-0000-1000-8000-00805f9b34fb',
        'FFF0 UART'
      ),
    ]) {
      final sameCharacteristic = normalized.where((candidate) =>
          candidate.serviceUuid == profile.$1 &&
          candidate.characteristicUuid == profile.$2 &&
          _canWrite(candidate) &&
          _canReceive(candidate));
      if (sameCharacteristic.length == 1) {
        final characteristic = sameCharacteristic.single;
        return BleCharacteristicPair(
          write: characteristic,
          receive: characteristic,
          profileName: profile.$3,
        );
      }
    }

    final duplex = normalized
        .where((candidate) => _canWrite(candidate) && _canReceive(candidate))
        .toList();
    if (duplex.length == 1) {
      return BleCharacteristicPair(
        write: duplex.single,
        receive: duplex.single,
        profileName: 'Generic UART',
      );
    }

    final writeCandidates = normalized.where(_canWrite).toList();
    final receiveCandidates = normalized.where(_canReceive).toList();
    if (writeCandidates.length == 1 && receiveCandidates.length == 1) {
      return BleCharacteristicPair(
        write: writeCandidates.single,
        receive: receiveCandidates.single,
        profileName: 'Generic split UART',
      );
    }
    if (writeCandidates.isEmpty || receiveCandidates.isEmpty) {
      throw const BleCharacteristicSelectionException(
        'لم نجد قناة اتصال متوافقة في جهاز BLE.',
      );
    }
    throw const BleCharacteristicSelectionException(
      'وجدنا أكثر من قناة اتصال محتملة. يلزم اختيار Profile معروف للجهاز.',
      ambiguous: true,
    );
  }

  BleCharacteristicPair? _knownPair(
    List<BleGattCharacteristic> characteristics, {
    required String service,
    required String writeUuid,
    required String receiveUuid,
    required String profile,
  }) {
    final writes = characteristics.where((candidate) =>
        candidate.serviceUuid == service &&
        candidate.characteristicUuid == writeUuid &&
        _canWrite(candidate));
    final receives = characteristics.where((candidate) =>
        candidate.serviceUuid == service &&
        candidate.characteristicUuid == receiveUuid &&
        _canReceive(candidate));
    if (writes.length == 1 && receives.length == 1) {
      return BleCharacteristicPair(
        write: writes.single,
        receive: receives.single,
        profileName: profile,
      );
    }
    return null;
  }

  BleGattCharacteristic _normalized(BleGattCharacteristic value) =>
      BleGattCharacteristic(
        serviceUuid: _uuid(value.serviceUuid),
        characteristicUuid: _uuid(value.characteristicUuid),
        canRead: value.canRead,
        canWrite: value.canWrite,
        canWriteWithoutResponse: value.canWriteWithoutResponse,
        canNotify: value.canNotify,
        canIndicate: value.canIndicate,
      );

  String _uuid(String value) {
    final lower = value.toLowerCase();
    if (lower.length == 4) return '0000$lower-0000-1000-8000-00805f9b34fb';
    return lower;
  }

  bool _canWrite(BleGattCharacteristic value) =>
      value.canWrite || value.canWriteWithoutResponse;
  bool _canReceive(BleGattCharacteristic value) =>
      value.canNotify || value.canIndicate || value.canRead;
}
