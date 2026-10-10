enum RepairVerificationState {
  success,
  improved,
  unresolved,
  returned,
  insufficientData
}

class RepairVerificationResult {
  const RepairVerificationResult({
    required this.state,
    required this.removedCodes,
    required this.remainingCodes,
    required this.newCodes,
    required this.summary,
    required this.needsWorkshopVisit,
  });
  final RepairVerificationState state;
  final List<String> removedCodes;
  final List<String> remainingCodes;
  final List<String> newCodes;
  final String summary;
  final bool needsWorkshopVisit;
}

class RepairVerificationRecord {
  const RepairVerificationRecord({required this.verificationId, required this.repairId, required this.vehicleId, required this.date, required this.oldObdCodes, required this.newObdCodes, required this.resultState, required this.summary, this.diagnosisId, this.mileage, this.imageMetadata, this.createdAt});
  final String verificationId, repairId, vehicleId, resultState, summary;
  final DateTime date;
  final List<String> oldObdCodes, newObdCodes;
  final String? diagnosisId, mileage;
  final Map<String, dynamic>? imageMetadata;
  final DateTime? createdAt;
  Map<String, dynamic> toJson() => {'verificationId': verificationId, 'repairId': repairId, 'vehicleId': vehicleId, 'diagnosisId': diagnosisId, 'date': date.toIso8601String(), 'mileage': mileage, 'oldObdCodes': oldObdCodes, 'newObdCodes': newObdCodes, 'resultState': resultState, 'summary': summary, 'imageMetadata': imageMetadata, 'createdAt': (createdAt ?? date).toIso8601String()};
  factory RepairVerificationRecord.fromJson(Map<String, dynamic> j) => RepairVerificationRecord(verificationId: '${j['verificationId'] ?? j['id']}', repairId: '${j['repairId'] ?? ''}', vehicleId: '${j['vehicleId'] ?? j['carId'] ?? ''}', diagnosisId: j['diagnosisId'] as String?, date: DateTime.tryParse('${j['date']}') ?? DateTime.now(), mileage: j['mileage']?.toString(), oldObdCodes: List<String>.from(j['oldObdCodes'] ?? const []), newObdCodes: List<String>.from(j['newObdCodes'] ?? const []), resultState: '${j['resultState'] ?? 'insufficientData'}', summary: '${j['summary'] ?? ''}', imageMetadata: j['imageMetadata'] as Map<String, dynamic>?, createdAt: DateTime.tryParse('${j['createdAt']}'));
}

class RepairVerificationLogic {
  static RepairVerificationResult compare({
    required List<String> beforeCodes,
    required List<String> afterCodes,
    String beforeSymptoms = '',
    String afterSymptoms = '',
    bool safetyCritical = false,
  }) {
    final before = beforeCodes.map((c) => c.toUpperCase()).toSet();
    final after = afterCodes.map((c) => c.toUpperCase()).toSet();
    final removed = before.difference(after).toList()..sort();
    final remaining = before.intersection(after).toList()..sort();
    final added = after.difference(before).toList()..sort();
    if (safetyCritical) {
      return RepairVerificationResult(
          state: RepairVerificationState.unresolved,
          removedCodes: removed,
          remainingCodes: remaining,
          newCodes: added,
          summary:
              'ما زالت هناك علامة سلامة حرجة؛ أوقف القيادة واطلب فحصًا مباشرًا.',
          needsWorkshopVisit: true);
    }
    if (added.isNotEmpty || remaining.isNotEmpty) {
      return RepairVerificationResult(
          state: before.isNotEmpty && remaining.isNotEmpty
              ? RepairVerificationState.returned
              : RepairVerificationState.unresolved,
          removedCodes: removed,
          remainingCodes: remaining,
          newCodes: added,
          summary: added.isNotEmpty
              ? 'ظهرت أكواد جديدة وتحتاج إلى فحص.'
              : 'ما زالت بعض الأكواد السابقة موجودة.',
          needsWorkshopVisit: true);
    }
    if (before.isNotEmpty && removed.length == before.length) {
      return RepairVerificationResult(
          state: RepairVerificationState.success,
          removedCodes: removed,
          remainingCodes: remaining,
          newCodes: added,
          summary:
              'اختفت أكواد الأعطال السابقة؛ يبدو الإصلاح ناجحًا مع متابعة الأعراض.',
          needsWorkshopVisit: false);
    }
    if (beforeSymptoms.trim().isNotEmpty &&
        afterSymptoms.trim().isNotEmpty &&
        beforeSymptoms.trim() != afterSymptoms.trim()) {
      return RepairVerificationResult(
          state: RepairVerificationState.improved,
          removedCodes: removed,
          remainingCodes: remaining,
          newCodes: added,
          summary: 'توجد مؤشرات تحسن في وصف الأعراض، ويُنصح بالمتابعة.',
          needsWorkshopVisit: false);
    }
    return RepairVerificationResult(
        state: RepairVerificationState.insufficientData,
        removedCodes: removed,
        remainingCodes: remaining,
        newCodes: added,
        summary: 'لا توجد معلومات كافية للحكم على نجاح الإصلاح.',
        needsWorkshopVisit: false);
  }
}
