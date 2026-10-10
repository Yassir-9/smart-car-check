enum AppPlan { free, plus }

enum AppEntitlement {
  basicDiagnosis,
  obdScan,
  repairRecording,
  basicRepairVerification,
  aiDiagnosisExpanded,
  beforeYouPay,
  aiRepairVerification,
  extendedVehicleHistory,
  advancedPdfReports
}

class EntitlementService {
  const EntitlementService(this.plan);
  final AppPlan plan;
  bool can(AppEntitlement entitlement) =>
      plan == AppPlan.plus ||
      {
        AppEntitlement.basicDiagnosis,
        AppEntitlement.obdScan,
        AppEntitlement.repairRecording,
        AppEntitlement.basicRepairVerification,
      }.contains(entitlement);
}
