import 'package:flutter_test/flutter_test.dart';
import 'package:car_ai_diagnosis/models/vehicle_issue.dart';
import 'package:car_ai_diagnosis/models/repair_verification.dart';

void main() {
  test('issue closes only after successful verification and user confirmation',
      () {
    expect(
        IssueLifecycle.afterVerification(
            current: VehicleIssueStatus.repaired,
            successful: true,
            userConfirmedClosed: false,
            returned: false),
        VehicleIssueStatus.repaired);
    expect(
        IssueLifecycle.afterVerification(
            current: VehicleIssueStatus.repaired,
            successful: true,
            userConfirmedClosed: true,
            returned: false),
        VehicleIssueStatus.closed);
    expect(
        IssueLifecycle.afterVerification(
            current: VehicleIssueStatus.closed,
            successful: false,
            userConfirmedClosed: false,
            returned: true),
        VehicleIssueStatus.returned);
  });
  test('removed OBD code is a deterministic success signal', () {
    final result =
        RepairVerificationLogic.compare(beforeCodes: ['P0133'], afterCodes: []);
    expect(result.state, RepairVerificationState.success);
    expect(result.removedCodes, ['P0133']);
  });
  test('remaining code is unresolved and new code is reported', () {
    final result = RepairVerificationLogic.compare(
        beforeCodes: ['P0133'], afterCodes: ['P0133', 'P0300']);
    expect(result.state, RepairVerificationState.returned);
    expect(result.newCodes, ['P0300']);
    expect(result.needsWorkshopVisit, isTrue);
  });
  test(
      'no technical data with changed symptoms is improvement, otherwise insufficient',
      () {
    expect(
        RepairVerificationLogic.compare(
                beforeCodes: const [],
                afterCodes: const [],
                beforeSymptoms: 'رجة',
                afterSymptoms: 'تحسن')
            .state,
        RepairVerificationState.improved);
    expect(
        RepairVerificationLogic.compare(
            beforeCodes: const [], afterCodes: const []).state,
        RepairVerificationState.insufficientData);
  });
  test('safety critical signal overrides all other outcomes', () {
    final result = RepairVerificationLogic.compare(
        beforeCodes: ['P0133'], afterCodes: [], safetyCritical: true);
    expect(result.state, RepairVerificationState.unresolved);
    expect(result.needsWorkshopVisit, isTrue);
  });
}
