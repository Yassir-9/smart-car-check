class MaintenanceRecord {
  final String id;
  final String carId;
  final String workType;
  final String? workshop;
  final DateTime date;
  final String? cost;
  final String? notes;
  final String? invoiceImageBase64;
  final String? category;
  final String? mileageAtService;
  final String? partNumber;

  MaintenanceRecord({
    required this.id,
    required this.carId,
    required this.workType,
    this.workshop,
    required this.date,
    this.cost,
    this.notes,
    this.invoiceImageBase64,
    this.category,
    this.mileageAtService,
    this.partNumber,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'carId': carId,
        'workType': workType,
        'workshop': workshop,
        'date': date.toIso8601String(),
        'cost': cost,
        'notes': notes,
        'invoiceImageBase64': invoiceImageBase64,
        'category': category,
        'mileageAtService': mileageAtService,
        'partNumber': partNumber,
      };

  factory MaintenanceRecord.fromJson(Map<String, dynamic> json) {
    return MaintenanceRecord(
      id: json['id'] as String,
      carId: json['carId'] as String? ?? '',
      workType: json['workType'] as String? ?? '',
      workshop: json['workshop'] as String?,
      date: DateTime.parse(json['date'] as String),
      cost: json['cost'] as String?,
      notes: json['notes'] as String?,
      invoiceImageBase64: json['invoiceImageBase64'] as String?,
      category: json['category'] as String?,
      mileageAtService: json['mileageAtService'] as String?,
      partNumber: json['partNumber'] as String?,
    );
  }
}
