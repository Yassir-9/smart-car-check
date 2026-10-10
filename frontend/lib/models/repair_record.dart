class RepairRecord {
  const RepairRecord({
    required this.repairId,
    required this.vehicleId,
    required this.date,
    required this.partsReplaced,
    required this.workPerformed,
    required this.cost,
    this.diagnosisId,
    this.repairReviewId,
    this.obdScanId,
    this.mileage,
    this.workshopName,
    this.notes,
    this.invoiceMetadata,
    this.verificationStatus = 'pending',
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
  });
  final String repairId, vehicleId;
  final String? diagnosisId, repairReviewId, obdScanId, workshopName, notes;
  final DateTime date;
  final int? mileage;
  final List<String> partsReplaced, workPerformed;
  final double cost;
  final Map<String, dynamic>? invoiceMetadata;
  final String verificationStatus;
  final DateTime? createdAt, updatedAt, deletedAt;

  bool get isDeleted => deletedAt != null;
  Map<String, dynamic> toJson() => {
        'repairId': repairId,
        'vehicleId': vehicleId,
        'diagnosisId': diagnosisId,
        'repairReviewId': repairReviewId,
        'obdScanId': obdScanId,
        'date': date.toIso8601String(),
        'mileage': mileage,
        'partsReplaced': partsReplaced,
        'workPerformed': workPerformed,
        'cost': cost,
        'workshopName': workshopName,
        'notes': notes,
        'invoiceMetadata': invoiceMetadata,
        'verificationStatus': verificationStatus,
        'createdAt': (createdAt ?? date).toIso8601String(),
        'updatedAt': (updatedAt ?? date).toIso8601String(),
        'deletedAt': deletedAt?.toIso8601String(),
      };
  factory RepairRecord.fromJson(Map<String, dynamic> json) => RepairRecord(
        repairId: '${json['repairId'] ?? json['id']}',
        vehicleId: '${json['vehicleId'] ?? json['carId']}',
        diagnosisId: json['diagnosisId'] as String?,
        repairReviewId: json['repairReviewId'] as String?,
        obdScanId: json['obdScanId'] as String?,
        date: DateTime.tryParse('${json['date']}') ?? DateTime.now(),
        mileage: json['mileage'] is num
            ? (json['mileage'] as num).toInt()
            : int.tryParse('${json['mileage']}'),
        partsReplaced: List<String>.from(json['partsReplaced'] ?? const []),
        workPerformed: List<String>.from(json['workPerformed'] ?? const []),
        cost: (json['cost'] as num?)?.toDouble() ?? 0,
        workshopName: json['workshopName'] as String?,
        notes: json['notes'] as String?,
        invoiceMetadata: json['invoiceMetadata'] as Map<String, dynamic>?,
        verificationStatus: json['verificationStatus'] as String? ?? 'pending',
        createdAt: DateTime.tryParse('${json['createdAt']}'),
        updatedAt: DateTime.tryParse('${json['updatedAt']}'),
        deletedAt: DateTime.tryParse('${json['deletedAt']}'),
      );
  RepairRecord copyWith(
          {List<String>? partsReplaced,
          List<String>? workPerformed,
          double? cost,
          String? verificationStatus,
          DateTime? updatedAt,
          DateTime? deletedAt}) =>
      RepairRecord(
          repairId: repairId,
          vehicleId: vehicleId,
          diagnosisId: diagnosisId,
          repairReviewId: repairReviewId,
          obdScanId: obdScanId,
          date: date,
          mileage: mileage,
          partsReplaced: partsReplaced ?? this.partsReplaced,
          workPerformed: workPerformed ?? this.workPerformed,
          cost: cost ?? this.cost,
          workshopName: workshopName,
          notes: notes,
          invoiceMetadata: invoiceMetadata,
          verificationStatus: verificationStatus ?? this.verificationStatus,
          createdAt: createdAt,
          updatedAt: updatedAt ?? DateTime.now(),
          deletedAt: deletedAt ?? this.deletedAt);
}
