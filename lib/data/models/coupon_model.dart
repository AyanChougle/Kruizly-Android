class CouponModel {
  final int? id;
  final String code;
  final String discountType; // "flat" or "percent"
  final double discountValue;
  final double minOrder;
  final double? maxDiscount;
  final String label;
  final String description;
  final bool active;

  const CouponModel({
    this.id,
    required this.code,
    required this.discountType,
    required this.discountValue,
    required this.minOrder,
    this.maxDiscount,
    required this.label,
    required this.description,
    this.active = true,
  });

  String get type => discountType;
  double get value => discountValue;
  double get maxDiscountValue => maxDiscount ?? 0.0;
  bool get isActive => active;

  factory CouponModel.fromJson(Map<String, dynamic> json) {
    return CouponModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()),
      code: (json['code'] ?? '').toString(),
      discountType: (json['discountType'] ?? json['discount_type'] ?? 'flat').toString(),
      discountValue: json['discountValue'] is num
          ? (json['discountValue'] as num).toDouble()
          : double.tryParse((json['discount_value'] ?? json['val'] ?? 0).toString()) ?? 0.0,
      minOrder: json['minOrder'] is num
          ? (json['minOrder'] as num).toDouble()
          : double.tryParse((json['min_order'] ?? 0).toString()) ?? 0.0,
      maxDiscount: json['maxDiscount'] != null || json['max_discount'] != null
          ? double.tryParse((json['maxDiscount'] ?? json['max_discount']).toString())
          : null,
      label: (json['label'] ?? json['code'] ?? '').toString(),
      description: (json['description'] ?? 'Discount coupon').toString(),
      active: json['active'] == 1 || json['active'] == true,
    );
  }
}

class CouponValidationResult {
  final bool isValid;
  final String code;
  final double discountAmount;
  final double finalTotal;
  final String label;
  final String description;
  final CouponModel? coupon;

  const CouponValidationResult({
    required this.isValid,
    required this.code,
    required this.discountAmount,
    required this.finalTotal,
    required this.label,
    required this.description,
    this.coupon,
  });

  factory CouponValidationResult.fromJson(Map<String, dynamic> json) {
    return CouponValidationResult(
      isValid: json['valid'] == true || json['success'] == true,
      code: (json['code'] ?? '').toString(),
      discountAmount: json['discountAmount'] is num
          ? (json['discountAmount'] as num).toDouble()
          : double.tryParse((json['discount'] ?? 0).toString()) ?? 0.0,
      finalTotal: json['finalTotal'] is num
          ? (json['finalTotal'] as num).toDouble()
          : double.tryParse((json['finalTotal'] ?? 0).toString()) ?? 0.0,
      label: (json['label'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      coupon: json['coupon'] is Map<String, dynamic> ? CouponModel.fromJson(json['coupon']) : null,
    );
  }
}
