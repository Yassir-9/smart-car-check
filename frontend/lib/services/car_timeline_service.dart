import '../models/car_timeline_event.dart';

class CarTimelineService {
  static List<CarTimelineEvent> merge({required List<CarTimelineEvent> diagnoses, required List<CarTimelineEvent> obdScans, required List<CarTimelineEvent> repairReviews, required List<CarTimelineEvent> repairs, required List<CarTimelineEvent> verifications, required List<CarTimelineEvent> maintenance, required List<CarTimelineEvent> returnedIssues}) {
    final seen = <String>{};
    final all = [...diagnoses, ...obdScans, ...repairReviews, ...repairs, ...verifications, ...maintenance, ...returnedIssues];
    return all.where((e) => seen.add('${e.type.name}:${e.relatedRecordId ?? e.id}')).toList()..sort((a, b) => b.date.compareTo(a.date));
  }

  static CarTimelineEvent event({required String id, required String vehicleId, required CarTimelineEventType type, required DateTime date, required String title, required String summary, required String status, int? mileage, String? relatedRecordId, String? relatedRecordType}) => CarTimelineEvent(id: id, vehicleId: vehicleId, type: type, date: date, title: title, summary: summary, status: status, mileage: mileage, relatedRecordId: relatedRecordId, relatedRecordType: relatedRecordType);
}
