class CarModel {
  final String id;
  final String brand;
  final String model;
  final int year;

  CarModel({
    required this.id,
    required this.brand,
    required this.model,
    required this.year,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'brand': brand,
        'model': model,
        'year': year,
      };

  factory CarModel.fromJson(Map<String, dynamic> json) => CarModel(
        id: json['id'].toString(),
        brand: json['brand'] ?? '',
        model: json['model'] ?? '',
        year: json['year'] is int
            ? json['year']
            : int.tryParse(json['year'].toString()) ?? 0,
      );

  String get label => '$brand $model - $year';
}
