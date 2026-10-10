import '../models/obd_scan_result.dart';

class ObdSessionService {
  static ObdScanResult? _lastResult;

  static ObdScanResult? get lastResult => _lastResult;
  static List<String> get lastCodes => _lastResult?.codes ?? const <String>[];
  static String? get lastDeviceName => _lastResult?.deviceName;
  static DateTime? get lastScanTime => _lastResult?.timestamp;

  static void save(ObdScanResult result) {
    _lastResult = result;
  }

  static void clear() {
    _lastResult = null;
  }

  static bool get hasSavedData => _lastResult != null;
}
