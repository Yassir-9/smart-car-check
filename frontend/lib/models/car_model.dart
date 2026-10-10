class CarModel {
  final String id;
  final String brand;
  final String model;
  final int year;
  final int? currentMileage;
  final String? vin;
  final String? engineType;
  final String? transmissionType;
  final DateTime? insuranceExpiry;
  final DateTime? registrationExpiry;
  final DateTime? inspectionExpiry;

  CarModel({
    required this.id,
    required this.brand,
    required this.model,
    required this.year,
    this.currentMileage,
    this.vin,
    this.engineType,
    this.transmissionType,
    this.insuranceExpiry,
    this.registrationExpiry,
    this.inspectionExpiry,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'brand': brand,
        'model': model,
        'year': year,
        'currentMileage': currentMileage,
        'vin': vin,
        'engineType': engineType,
        'transmissionType': transmissionType,
        'insuranceExpiry': insuranceExpiry?.toIso8601String(),
        'registrationExpiry': registrationExpiry?.toIso8601String(),
        'inspectionExpiry': inspectionExpiry?.toIso8601String(),
      };

  factory CarModel.fromJson(Map<String, dynamic> json) => CarModel(
        id: json['id'].toString(),
        brand: json['brand'] ?? '',
        model: json['model'] ?? '',
        year: json['year'] is int
            ? json['year']
            : int.tryParse(json['year'].toString()) ?? 0,
        currentMileage: json['currentMileage'] is int
            ? json['currentMileage']
            : int.tryParse(json['currentMileage']?.toString() ?? ''),
        vin: json['vin'],
        engineType: json['engineType'],
        transmissionType: json['transmissionType'],
        insuranceExpiry: json['insuranceExpiry'] != null
            ? DateTime.tryParse(json['insuranceExpiry'])
            : null,
        registrationExpiry: json['registrationExpiry'] != null
            ? DateTime.tryParse(json['registrationExpiry'])
            : null,
        inspectionExpiry: json['inspectionExpiry'] != null
            ? DateTime.tryParse(json['inspectionExpiry'])
            : null,
      );

  String get label => '$brand $model - $year';
}
