class PartListing {
  final String id;
  final String partName;
  final String carBrand;
  final String carModel;
  final String? price;
  final String sellerPhone;
  final String? notes;
  final String? ownerId;
  final String? oemNumber;
  final String? imageBase64;
  final String? condition;
  final String? partBrand;

  PartListing({
    required this.id,
    required this.partName,
    required this.carBrand,
    required this.carModel,
    this.price,
    required this.sellerPhone,
    this.notes,
    this.ownerId,
    this.oemNumber,
    this.imageBase64,
    this.condition,
    this.partBrand,
  });

  factory PartListing.fromJson(Map<String, dynamic> json) {
    return PartListing(
      id: json['id'].toString(),
      partName: json['partName'] ?? '',
      carBrand: json['carBrand'] ?? '',
      carModel: json['carModel'] ?? '',
      price: json['price']?.toString(),
      sellerPhone: json['sellerPhone'] ?? '',
      notes: json['notes'],
      ownerId: json['ownerId'],
      oemNumber: json['oemNumber'],
      imageBase64: json['imageBase64'],
      condition: json['condition'],
      partBrand: json['partBrand'],
    );
  }
}
