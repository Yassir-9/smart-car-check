enum CarTimelineEventType {
  diagnosis,
  obdScan,
  repairReview,
  repair,
  repairVerification,
  maintenance,
  issueReturned
}

class CarTimelineEvent {
  const CarTimelineEvent(
      {required this.id,
      required this.vehicleId,
      required this.type,
      required this.date,
      required this.title,
      required this.summary,
      required this.status,
      this.mileage,
      this.relatedRecordId,
      this.relatedRecordType});
  final String id, vehicleId, title, summary, status;
  final CarTimelineEventType type;
  final DateTime date;
  final int? mileage;
  final String? relatedRecordId, relatedRecordType;
  static List<CarTimelineEvent> sorted(List<CarTimelineEvent> events) =>
      [...events]..sort((a, b) => b.date.compareTo(a.date));
}
