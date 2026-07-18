import '../models/car_model.dart';
import '../models/maintenance_record.dart';
import '../models/maintenance_reminder.dart';

class HealthScoreService {
  static int calculate({
    required CarModel car,
    required List<MaintenanceRecord> records,
    required List<MaintenanceReminder> overdueReminders,
  }) {
    int score = 100;
    final now = DateTime.now();

    final docs = [car.insuranceExpiry, car.registrationExpiry, car.inspectionExpiry];
    for (final doc in docs) {
      if (doc == null) continue;
      if (doc.isBefore(now)) {
        score -= 15;
      } else if (doc.difference(now).inDays <= 30) {
        score -= 7;
      }
    }

    if (records.isEmpty) {
      score -= 25;
    } else {
      final lastService = records
          .map((r) => r.date)
          .reduce((a, b) => a.isAfter(b) ? a : b);
      final monthsSince = now.difference(lastService).inDays / 30;
      if (monthsSince > 12) {
        score -= 20;
      } else if (monthsSince > 6) {
        score -= 10;
      }
    }

    final overdueCount = overdueReminders.length;
    score -= (overdueCount * 8).clamp(0, 24);

    return score.clamp(0, 100);
  }

  static String label(int score) {
    if (score >= 85) return 'ممتازة';
    if (score >= 65) return 'جيدة';
    if (score >= 40) return 'تحتاج انتباه';
    return 'تحتاج صيانة عاجلة';
  }
}
