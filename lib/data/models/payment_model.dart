class PaymentModel {
  final int id;
  final String paymentId;
  final String bookingId;
  final String firebaseUid;
  final double amount;
  final String method;
  final String? utr;
  final String? screenshotUrl;
  final String status;
  final String? rejectionReason;
  final DateTime createdAt;

  const PaymentModel({
    required this.id,
    required this.paymentId,
    required this.bookingId,
    required this.firebaseUid,
    required this.amount,
    required this.method,
    this.utr,
    this.screenshotUrl,
    required this.status,
    this.rejectionReason,
    required this.createdAt,
  });

  bool get isVerified => status == '''verified''';
  bool get isPending => status == '''pending''';
  bool get isRejected => status == '''rejected''';

  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    return PaymentModel(
      id: json['''id'''] is int ? json['''id'''] : int.tryParse(json['''id'''].toString()) ?? 0,
      paymentId: (json['''paymentId'''] ?? json['''payment_id'''] ?? '''''').toString(),
      bookingId: (json['''bookingId'''] ?? json['''booking_id'''] ?? '''''').toString(),
      firebaseUid: (json['''firebaseUid'''] ?? json['''firebase_uid'''] ?? '''''').toString(),
      amount: json['''amount'''] is num
          ? (json['''amount'''] as num).toDouble()
          : double.tryParse((json['''amount'''] ?? 0).toString()) ?? 0.0,
      method: (json['''method'''] ?? '''upi''').toString(),
      utr: json['''utr''']?.toString() ?? json['''payment_ref''']?.toString(),
      screenshotUrl: json['''screenshotUrl''']?.toString() ?? json['''screenshot_url''']?.toString(),
      status: (json['''status'''] ?? '''pending''').toString(),
      rejectionReason: json['''rejectionReason''']?.toString() ?? json['''rejection_reason''']?.toString(),
      createdAt: json['''createdAt'''] != null || json['''created_at'''] != null
          ? DateTime.tryParse((json['''createdAt'''] ?? json['''created_at''']).toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
