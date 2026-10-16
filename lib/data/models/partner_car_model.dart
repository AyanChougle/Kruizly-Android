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
  final String? payoutModel;
  final String? payoutModelLabel;
  final double fixedMonthlyAmount;
  final String? userName;
  final String? userPhone;
  final String? userEmail;
  final String? createdAt;
  final String? imageUrl;

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
    this.payoutModel,
    this.payoutModelLabel,
    this.fixedMonthlyAmount = 0.0,
    this.userName,
    this.userPhone,
    this.userEmail,
    this.createdAt,
    this.imageUrl,
  });

  String get fullName => '$brand $model'.trim();
  bool get isFixedMonthly =>
      payoutModel == 'fixed_monthly' || (payoutModel ?? '').contains('fixed');

  factory PartnerCarModel.fromJson(Map<String, dynamic> json) {
    List<String> parsedPhotos = [];
    if (json['photos'] is List) {
      parsedPhotos = (json['photos'] as List).map((e) => e.toString()).toList();
    }

    final isFixed = json['payoutModel'] == 'fixed_monthly' ||
        json['isFixedMonthly'] == true ||
        (json['payoutModel']?.toString() ?? '').contains('fixed');

    return PartnerCarModel(
      carId: (json['carId'] ?? json['car_id'] ?? json['id'] ?? '').toString(),
      brand: (json['brand'] ?? '').toString(),
      model: (json['model'] ?? '').toString(),
      year: json['year'] is int
          ? json['year']
          : int.tryParse(json['year']?.toString() ?? '') ?? 2026,
      regNo: (json['regNo'] ?? json['reg_no'] ?? json['regNumber'] ?? '').toString(),
      transmission: (json['transmission'] ?? 'Automatic').toString(),
      fuel: (json['fuel'] ?? 'Petrol').toString(),
      city: (json['city'] ?? json['location'] ?? 'Navi Mumbai').toString(),
      expectedPrice: json['expectedPrice'] is num
          ? (json['expectedPrice'] as num).toDouble()
          : double.tryParse((json['expected_price'] ?? 0).toString()) ?? 0.0,
      status: (json['status'] ?? 'approved').toString(),
      rejectionReason:
          json['rejectionReason']?.toString() ?? json['rejection_reason']?.toString(),
      photos: parsedPhotos,
      payoutModel: (json['payoutModel'] ?? (isFixed ? 'fixed_monthly' : 'revenue_share')).toString(),
      payoutModelLabel: (json['payoutModelLabel'] ??
              (isFixed ? 'Fixed Monthly Retainer' : '60% Revenue Share'))
          .toString(),
      fixedMonthlyAmount: json['fixedMonthlyAmount'] is num
          ? (json['fixedMonthlyAmount'] as num).toDouble()
          : double.tryParse((json['fixed_monthly_amount'] ?? 0).toString()) ?? 0.0,
      userName: json['userName']?.toString() ?? json['ownerName']?.toString(),
      userPhone: json['userPhone']?.toString(),
      userEmail: json['userEmail']?.toString(),
      createdAt: json['createdAt']?.toString() ?? json['created_at']?.toString(),
      imageUrl: json['imageUrl']?.toString(),
    );
  }
}
