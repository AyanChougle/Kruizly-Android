class PartnerCarModel {
  final String carId;
  final String brand;
  final String model;
  final int year;
  final String regNo;
  final String transmission;
  final String fuel;
  final String city;
  final double expectedPrice;
  final String status;
  final String? rejectionReason;
  final List<String> photos;

  const PartnerCarModel({
    required this.carId,
    required this.brand,
    required this.model,
    required this.year,
    required this.regNo,
    required this.transmission,
    required this.fuel,
    required this.city,
    required this.expectedPrice,
    required this.status,
    this.rejectionReason,
    this.photos = const [],
  });

  factory PartnerCarModel.fromJson(Map<String, dynamic> json) {
    List<String> parsedPhotos = [];
    if (json['''photos'''] is List) {
      parsedPhotos = (json['''photos'''] as List).map((e) => e.toString()).toList();
    }

    return PartnerCarModel(
      carId: (json['''carId'''] ?? json['''car_id'''] ?? json['''id'''] ?? '''''').toString(),
      brand: (json['''brand'''] ?? '''''').toString(),
      model: (json['''model'''] ?? '''''').toString(),
      year: json['''year'''] is int ? json['''year'''] : int.tryParse(json['''year'''].toString()) ?? 2026,
      regNo: (json['''regNo'''] ?? json['''reg_no'''] ?? '''''').toString(),
      transmission: (json['''transmission'''] ?? '''Automatic''').toString(),
      fuel: (json['''fuel'''] ?? '''Petrol''').toString(),
      city: (json['''city'''] ?? '''Navi Mumbai''').toString(),
      expectedPrice: json['''expectedPrice'''] is num
          ? (json['''expectedPrice'''] as num).toDouble()
          : double.tryParse((json['''expected_price'''] ?? 0).toString()) ?? 0.0,
      status: (json['''status'''] ?? '''pending_approval''').toString(),
      rejectionReason: json['''rejectionReason''']?.toString() ?? json['''rejection_reason''']?.toString(),
      photos: parsedPhotos,
    );
  }
}
