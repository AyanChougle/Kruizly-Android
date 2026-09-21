class VehicleModel {
  final int id;
  final String? carId;
  final String regNo;
  final String brand;
  final String model;
  final int year;
  final String category;
  final String transmission;
  final String fuel;
  final int seats;
  final int bags;
  final double priceDay;
  final double priceHour;
  final double driverPrice;
  final double securityDeposit;
  final int freeKm;
  final double extraKm;
  final String location;
  final bool isAvailable;
  final String status;
  final String? imageUrl;
  final List<String> gallery;
  final String? acquisitionType;
  final String? ownerName;
  final String? acquisitionDate;
  final bool? isActiveFleet;

  const VehicleModel({
    required this.id,
    this.carId,
    required this.regNo,
    required this.brand,
    required this.model,
    required this.year,
    required this.category,
    required this.transmission,
    required this.fuel,
    required this.seats,
    required this.bags,
    required this.priceDay,
    required this.priceHour,
    required this.driverPrice,
    required this.securityDeposit,
    required this.freeKm,
    required this.extraKm,
    required this.location,
    required this.isAvailable,
    required this.status,
    this.imageUrl,
    this.gallery = const [],
    this.acquisitionType,
    this.ownerName,
    this.acquisitionDate,
    this.isActiveFleet,
  });

  String get fullName => '$brand $model';
  String get title => fullName;
  String get registrationNumber => regNo;
  double get driverPriceHour => driverPrice > 0 ? driverPrice / 24.0 : 83.33;

  String get categoryDisplay {
    switch (category.toLowerCase()) {
      case 'suv':
        return 'SUV';
      case 'mpv':
        return 'MPV / 7-Seater';
      case 'luxury':
        return 'Luxury';
      case 'sedan':
        return 'Premium Sedan';
      default:
        return 'Economy Hatchback';
    }
  }

  factory VehicleModel.fromJson(Map<String, dynamic> json) {
    List<String> parsedGallery = [];
    if (json['gallery'] is List) {
      parsedGallery = (json['gallery'] as List).map((e) => e.toString()).toList();
    }

    final priceDay = json['priceDay'] is num
        ? (json['priceDay'] as num).toDouble()
        : double.tryParse((json['price_day'] ?? json['priceDay'] ?? 0).toString()) ?? 0.0;

    final priceHour = json['priceHour'] is num
        ? (json['priceHour'] as num).toDouble()
        : double.tryParse((json['price_hour'] ?? json['priceHour'] ?? (priceDay / 24)).toString()) ?? (priceDay / 24);

    return VehicleModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      carId: json['carId']?.toString() ?? json['car_id']?.toString(),
      regNo: (json['regNo'] ?? json['reg_no'] ?? '').toString(),
      brand: (json['brand'] ?? '').toString(),
      model: (json['model'] ?? '').toString(),
      year: json['year'] is int ? json['year'] : int.tryParse(json['year'].toString()) ?? 2026,
      category: (json['category'] ?? 'economy').toString(),
      transmission: (json['transmission'] ?? 'Manual').toString(),
      fuel: (json['fuel'] ?? 'Petrol').toString(),
      seats: json['seats'] is int ? json['seats'] : int.tryParse(json['seats'].toString()) ?? 5,
      bags: json['bags'] is int ? json['bags'] : int.tryParse(json['bags'].toString()) ?? 2,
      priceDay: priceDay,
      priceHour: priceHour,
      driverPrice: json['driverPrice'] is num
          ? (json['driverPrice'] as num).toDouble()
          : double.tryParse((json['driver_price'] ?? 2000).toString()) ?? 2000.0,
      securityDeposit: json['securityDeposit'] is num
          ? (json['securityDeposit'] as num).toDouble()
          : double.tryParse((json['security_deposit'] ?? 3000).toString()) ?? 3000.0,
      freeKm: json['freeKm'] is int ? json['freeKm'] : int.tryParse((json['free_km'] ?? 250).toString()) ?? 250,
      extraKm: json['extraKm'] is num
          ? (json['extraKm'] as num).toDouble()
          : double.tryParse((json['extra_km'] ?? 15).toString()) ?? 15.0,
      location: (json['hub'] ?? json['location'] ?? 'Gavson Business Park, Ghansoli').toString(),
      isAvailable: json['available'] == 1 ||
          json['available'] == true ||
          json['isAvailable'] == true ||
          json['is_available'] == true ||
          json['is_available'] == 1,
      status: (json['status'] ?? 'available').toString(),
      imageUrl: json['imageUrl']?.toString() ?? json['image']?.toString(),
      gallery: parsedGallery,
      acquisitionType: (json['acquisitionType'] ?? json['acquisition_type'])?.toString(),
      ownerName: (json['ownerName'] ?? json['owner_name'])?.toString(),
      acquisitionDate: (json['acquisitionDate'] ?? json['acquisition_date'])?.toString(),
      isActiveFleet: json['isActiveFleet'] == true || json['is_active_fleet'] == true || json['isActiveFleet'] == 1,
    );
  }

  VehicleModel copyWith({
    int? id,
    String? carId,
    String? regNo,
    String? brand,
    String? model,
    int? year,
    String? category,
    String? transmission,
    String? fuel,
    int? seats,
    int? bags,
    double? priceDay,
    double? priceHour,
    double? driverPrice,
    double? securityDeposit,
    int? freeKm,
    double? extraKm,
    String? location,
    bool? isAvailable,
    String? status,
    String? imageUrl,
    List<String>? gallery,
    String? acquisitionType,
    String? ownerName,
    String? acquisitionDate,
    bool? isActiveFleet,
  }) {
    return VehicleModel(
      id: id ?? this.id,
      carId: carId ?? this.carId,
      regNo: regNo ?? this.regNo,
      brand: brand ?? this.brand,
      model: model ?? this.model,
      year: year ?? this.year,
      category: category ?? this.category,
      transmission: transmission ?? this.transmission,
      fuel: fuel ?? this.fuel,
      seats: seats ?? this.seats,
      bags: bags ?? this.bags,
      priceDay: priceDay ?? this.priceDay,
      priceHour: priceHour ?? this.priceHour,
      driverPrice: driverPrice ?? this.driverPrice,
      securityDeposit: securityDeposit ?? this.securityDeposit,
      freeKm: freeKm ?? this.freeKm,
      extraKm: extraKm ?? this.extraKm,
      location: location ?? this.location,
      isAvailable: isAvailable ?? this.isAvailable,
      status: status ?? this.status,
      imageUrl: imageUrl ?? this.imageUrl,
      gallery: gallery ?? this.gallery,
      acquisitionType: acquisitionType ?? this.acquisitionType,
      ownerName: ownerName ?? this.ownerName,
      acquisitionDate: acquisitionDate ?? this.acquisitionDate,
      isActiveFleet: isActiveFleet ?? this.isActiveFleet,
    );
  }
}
