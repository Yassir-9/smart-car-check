import '../../models/obd_scan_result.dart';

class ObdDevice {
  const ObdDevice({required this.id, required this.name, this.signalStrength});

  /// Transport-private identifier. It must never be persisted as session data.
  final String id;
  final String name;
  final int? signalStrength;
}

enum ObdConnectionState { disconnected, connecting, connected, disconnecting }

class ObdCapabilities {
  const ObdCapabilities({
    this.classicAvailable = false,
    this.bleAvailable = false,
    this.wifiAvailable = false,
  });

  final bool classicAvailable;
  final bool bleAvailable;
  final bool wifiAvailable;

  bool get hasAnyTransport => classicAvailable || bleAvailable || wifiAvailable;

  bool supports(ObdTransportType type) => switch (type) {
        ObdTransportType.androidClassic => classicAvailable,
        ObdTransportType.ble => bleAvailable,
        ObdTransportType.wifi => wifiAvailable,
        ObdTransportType.unsupported => false,
      };
}

abstract class ObdTransport {
  ObdTransportType get type;
  String get displayName;
  bool get isConnected;
  ObdDevice? get connectedDevice;
  Stream<List<int>> get input;
  Stream<List<ObdDevice>> get discoveredDevices;
  Stream<ObdConnectionState> get connectionState;

  Future<bool> isAvailable();
  Future<List<ObdDevice>> discoverDevices();
  Future<void> stopDiscovery();
  Future<void> connect(ObdDevice device);
  Future<void> disconnect();
  Future<void> write(String command);
  Future<void> dispose();
}
