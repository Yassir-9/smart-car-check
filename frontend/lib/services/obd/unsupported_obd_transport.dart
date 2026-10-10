import '../../models/obd_scan_result.dart';
import 'obd_transport.dart';

class ObdUnsupportedException implements Exception {
  const ObdUnsupportedException(this.message);
  final String message;

  @override
  String toString() => message;
}

class UnsupportedObdTransport implements ObdTransport {
  const UnsupportedObdTransport({
    this.reason = 'الفحص المباشر عبر OBD غير متاح على هذا الجهاز حاليًا',
    this.transportType = ObdTransportType.unsupported,
  });

  final String reason;
  final ObdTransportType transportType;

  @override
  ObdTransportType get type => transportType;
  @override
  String get displayName => 'غير متاح';
  @override
  bool get isConnected => false;
  @override
  ObdDevice? get connectedDevice => null;
  @override
  Stream<List<int>> get input => const Stream<List<int>>.empty();
  @override
  Stream<List<ObdDevice>> get discoveredDevices =>
      const Stream<List<ObdDevice>>.empty();
  @override
  Stream<ObdConnectionState> get connectionState =>
      const Stream<ObdConnectionState>.empty();
  @override
  Future<bool> isAvailable() async => false;
  @override
  Future<List<ObdDevice>> discoverDevices() => Future.error(
        ObdUnsupportedException(reason),
      );
  @override
  Future<void> stopDiscovery() async {}
  @override
  Future<void> connect(ObdDevice device) => Future.error(
        ObdUnsupportedException(reason),
      );
  @override
  Future<void> write(String command) => Future.error(
        ObdUnsupportedException(reason),
      );
  @override
  Future<void> disconnect() async {}
  @override
  Future<void> dispose() async {}
}

class WifiObdTransport extends UnsupportedObdTransport {
  const WifiObdTransport()
      : super(
          reason: 'دعم OBD عبر Wi-Fi غير مفعّل حاليًا',
          transportType: ObdTransportType.wifi,
        );
}
