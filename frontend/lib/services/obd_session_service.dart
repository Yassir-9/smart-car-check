class ObdSessionService {
  static List<String> lastCodes = [];
  static String? lastDeviceName;
  static DateTime? lastScanTime;

  static void save(List<String> codes, String? deviceName) {
    lastCodes = codes;
    lastDeviceName = deviceName;
    lastScanTime = DateTime.now();
  }

  static void clear() {
    lastCodes = [];
    lastDeviceName = null;
    lastScanTime = null;
  }

  static bool get hasSavedData => lastCodes.isNotEmpty;
}
