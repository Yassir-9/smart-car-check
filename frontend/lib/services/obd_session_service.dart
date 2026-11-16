import '../models/obd_scan_result.dart';

class ObdSessionService {
  /// A scan older than this is not sent with a diagnosis.
  static const Duration maxScanAge = Duration(minutes: 30);

  static ObdScanResult? _lastResult;
  static bool _ignored = false;

  static ObdScanResult? get lastResult => _lastResult;
  static String? get lastDeviceName => _lastResult?.deviceName;
  static DateTime? get lastScanTime => _lastResult?.timestamp;

  /// Raw codes of the last scan, whatever car or age. Prefer [codesFor] for
  /// anything that is sent to the diagnosis.
  static List<String> get lastCodes => _lastResult?.codes ?? const <String>[];

  static bool get ignored => _ignored;

  static void save(ObdScanResult result) {
    _lastResult = result;
    _ignored = false;
  }

  static void clear() {
    _lastResult = null;
    _ignored = false;
  }

  /// The user chose not to use the saved codes for the current diagnosis.
  static void ignore() => _ignored = true;

  /// Drops the saved scan when it belongs to another car (or to no known car).
  static void clearIfOtherVehicle(String? vehicleId) {
    final scan = _lastResult;
    if (scan != null && (vehicleId == null || scan.vehicleId != vehicleId)) {
      clear();
    }
  }

  static bool isFresh(ObdScanResult scan, {DateTime? now}) =>
      (now ?? DateTime.now()).difference(scan.timestamp) < maxScanAge;

  static ObdScanResult? _usable(String? vehicleId, DateTime? now) {
    final scan = _lastResult;
    if (scan == null || _ignored || vehicleId == null) return null;
    if (scan.vehicleId != vehicleId) return null;
    return isFresh(scan, now: now) ? scan : null;
  }

  /// The scan that may be used for [vehicleId]: same car, under 30 minutes old
  /// and not ignored. Otherwise null.
  static ObdScanResult? scanFor(String? vehicleId, {DateTime? now}) =>
      _usable(vehicleId, now);

  /// Codes that may be sent for [vehicleId] (empty when no usable scan).
  static List<String> codesFor(String? vehicleId, {DateTime? now}) =>
      _usable(vehicleId, now)?.codes ?? const <String>[];

  /// Why a saved scan cannot be used, or null when it is usable / absent / ignored.
  static ObdScanProblem? problemFor(String? vehicleId, {DateTime? now}) {
    final scan = _lastResult;
    if (scan == null || _ignored) return null;
    if (vehicleId == null || scan.vehicleId != vehicleId) {
      return ObdScanProblem.otherVehicle;
    }
    return isFresh(scan, now: now) ? null : ObdScanProblem.expired;
  }

  static bool get hasSavedData => _lastResult != null;
}

/// "16/11/2026 14:05" – same digits in Arabic and English UI.
String formatObdScanTime(DateTime time) {
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(time.day)}/${two(time.month)}/${time.year} '
      '${two(time.hour)}:${two(time.minute)}';
}

enum ObdScanProblem { otherVehicle, expired }
