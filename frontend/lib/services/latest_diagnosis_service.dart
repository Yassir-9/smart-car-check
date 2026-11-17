import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/car_model.dart';

/// The newest saved diagnosis of one car, as shown in the home "latest check".
class LatestDiagnosis {
  const LatestDiagnosis({required this.title, required this.date});
  final String title;
  final DateTime date;
}

/// Reads the diagnosis history (the same source as the History screen:
/// GET /api/history) and picks the newest entry of the given car.
///
/// The home card used to read only Firestore `vehicle_issues`, which the app
/// fills when a diagnosis is saved on this device; the history list comes from
/// the server. Diagnoses missing from `vehicle_issues` therefore showed in the
/// History tab but "No previous checks" on the home screen.
class LatestDiagnosisService {
  static Future<List<dynamic>> Function() historyLoader = _loadHistory;

  static Future<List<dynamic>> _loadHistory() async {
    final token = await FirebaseAuth.instance.currentUser?.getIdToken();
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/api/history?limit=30'),
      headers: {'Authorization': 'Bearer $token'},
    ).timeout(const Duration(seconds: 12));
    if (response.statusCode != 200) return const [];
    final data = jsonDecode(utf8.decode(response.bodyBytes));
    final items = data is List ? data : (data is Map ? data['items'] : null);
    return items is List ? items : const [];
  }

  /// Null when there is none, or when the history cannot be loaded.
  static Future<LatestDiagnosis?> forCar(CarModel car) async {
    try {
      return pickLatest(await historyLoader(), car);
    } catch (_) {
      return null;
    }
  }

  static bool _sameCar(Map car, CarModel active) {
    final id = car['id']?.toString();
    if (id != null && id.isNotEmpty) return id == active.id;
    return car['brand']?.toString() == active.brand &&
        car['model']?.toString() == active.model &&
        car['year']?.toString() == active.year.toString();
  }

  static LatestDiagnosis? pickLatest(List<dynamic> items, CarModel car) {
    LatestDiagnosis? best;
    for (final item in items) {
      if (item is! Map) continue;
      final itemCar = item['car'];
      if (itemCar is! Map || !_sameCar(itemCar, car)) continue;
      final date = DateTime.tryParse(item['timestamp']?.toString() ?? '');
      if (date == null) continue;
      final result = item['result'];
      final title = (result is Map ? result['possible_issue'] : null)
              ?.toString()
              .trim() ??
          '';
      if (title.isEmpty) continue;
      if (best == null || date.isAfter(best.date)) {
        best = LatestDiagnosis(title: title, date: date);
      }
    }
    return best;
  }
}
