class DiagnosisSessionService {
  static Map<String, dynamic>? lastResult;
  static String? lastDescription;

  static void save(Map<String, dynamic> result, String description) {
    lastResult = result;
    lastDescription = description;
  }

  static void clear() {
    lastResult = null;
    lastDescription = null;
  }

  static bool get hasSavedResult => lastResult != null;
}
