import 'package:flutter_test/flutter_test.dart';
import 'package:car_ai_diagnosis/models/repair_record.dart';
import 'package:car_ai_diagnosis/models/car_timeline_event.dart';
import 'package:car_ai_diagnosis/services/entitlement_service.dart';

void main() {
  test('repair record round trips structured fields and soft delete', () {
    final record = RepairRecord(
        repairId: 'r1',
        vehicleId: 'v1',
        date: DateTime(2026, 1, 1),
        partsReplaced: const ['فلتر'],
        workPerformed: const ['تغيير'],
        cost: 100);
    final restored = RepairRecord.fromJson(
        record.copyWith(deletedAt: DateTime(2026, 1, 2)).toJson());
    expect(restored.partsReplaced, ['فلتر']);
    expect(restored.isDeleted, isTrue);
  });
  test('timeline events sort newest first', () {
    final old = CarTimelineEvent(
        id: '1',
        vehicleId: 'v',
        type: CarTimelineEventType.diagnosis,
        date: DateTime(2026, 1),
        title: 'قديم',
        summary: '',
        status: 'new');
    final newer = CarTimelineEvent(
        id: '2',
        vehicleId: 'v',
        type: CarTimelineEventType.repair,
        date: DateTime(2026, 2),
        title: 'حديث',
        summary: '',
        status: 'repaired');
    expect(CarTimelineEvent.sorted([old, newer]).first.id, '2');
  });
  test('entitlements keep free basics and plus additions centralized', () {
    expect(
        const EntitlementService(AppPlan.free)
            .can(AppEntitlement.repairRecording),
        isTrue);
    expect(
        const EntitlementService(AppPlan.free)
            .can(AppEntitlement.aiRepairVerification),
        isFalse);
    expect(
        const EntitlementService(AppPlan.plus)
            .can(AppEntitlement.aiRepairVerification),
        isTrue);
  });
}
