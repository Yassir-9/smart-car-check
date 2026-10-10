enum VehicleIssueStatus {
  newIssue,
  monitoring,
  repairNeeded,
  repaired,
  closed,
  returned
}

extension VehicleIssueStatusValue on VehicleIssueStatus {
  String get value => switch (this) {
        VehicleIssueStatus.newIssue => 'new',
        VehicleIssueStatus.monitoring => 'monitoring',
        VehicleIssueStatus.repairNeeded => 'repair_needed',
        VehicleIssueStatus.repaired => 'repaired',
        VehicleIssueStatus.closed => 'closed',
        VehicleIssueStatus.returned => 'returned',
      };
}

class IssueLifecycle {
  static VehicleIssueStatus afterVerification({
    required VehicleIssueStatus current,
    required bool successful,
    required bool userConfirmedClosed,
    required bool returned,
  }) {
    if (returned) return VehicleIssueStatus.returned;
    if (successful && userConfirmedClosed) return VehicleIssueStatus.closed;
    if (successful) return VehicleIssueStatus.repaired;
    return current == VehicleIssueStatus.closed
        ? VehicleIssueStatus.returned
        : current;
  }
}

class VehicleIssue {
  final String id;
  final String carId;
  final String title;
  final List<String> obdCodes;
  final String status;
  final DateTime date;
  final int? mileage;
  final String? notes;
  final bool returnedAfterRepair;

  const VehicleIssue(
      {required this.id,
      required this.carId,
      required this.title,
      required this.obdCodes,
      required this.status,
      required this.date,
      this.mileage,
      this.notes,
      this.returnedAfterRepair = false});
  factory VehicleIssue.fromJson(Map<String, dynamic> json) => VehicleIssue(
        id: json['id'].toString(),
        carId: json['carId'].toString(),
        title: json['title'] ?? '',
        obdCodes: List<String>.from(json['obdCodes'] ?? const []),
        status: json['status'] ?? 'new',
        date: DateTime.tryParse(json['date'] ?? '') ?? DateTime.now(),
        mileage: json['mileage'] as int?,
        notes: json['notes'],
        returnedAfterRepair: json['returnedAfterRepair'] == true,
      );
}
