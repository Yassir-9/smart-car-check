import 'package:flutter_test/flutter_test.dart';
import 'package:car_ai_diagnosis/models/car_timeline_event.dart';
import 'package:car_ai_diagnosis/services/car_timeline_service.dart';

void main() {
  test('merges seven sources, sorts, and deduplicates by type and relation',
      () {
    final now = DateTime.now();
    CarTimelineEvent e(CarTimelineEventType t, String id, int days) =>
        CarTimelineService.event(
            id: id,
            vehicleId: 'v',
            type: t,
            date: now.add(Duration(days: days)),
            title: t.name,
            summary: '',
            status: 'ok',
            relatedRecordId: id);
    final events = CarTimelineService.merge(diagnoses: [
      e(CarTimelineEventType.diagnosis, 'd', 1)
    ], obdScans: [
      e(CarTimelineEventType.obdScan, 'o', 2)
    ], repairReviews: [
      e(CarTimelineEventType.repairReview, 'rr', 3)
    ], repairs: [
      e(CarTimelineEventType.repair, 'r', 4)
    ], verifications: [
      e(CarTimelineEventType.repairVerification, 'vfy', 5)
    ], maintenance: [
      e(CarTimelineEventType.maintenance, 'm', 6)
    ], returnedIssues: [
      e(CarTimelineEventType.issueReturned, 'ret', 7),
      e(CarTimelineEventType.issueReturned, 'ret', 6)
    ]);
    expect(events.length, 7);
    expect(events.first.relatedRecordId, 'ret');
  });
}
