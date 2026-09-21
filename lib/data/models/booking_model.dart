class BookingModel {
  final int id;
  final String bookingId;
  final String bookingNumber;
  final String? firebaseUid;
  final String userName;
  final String userEmail;
  final String? userPhone;
  final String vehicleReg;
  final String vehicleName;
  final String vehicleCategory;
  final DateTime pickupDate;
  final DateTime dropDate;
  final String duration;
  final int days;
  final int hours;
  final bool withDriver;
  final double baseAmount;
  final double totalAmount;
  final double finalAmount;
  final double advanceAmount;
  final double remainingBalance;
  final double securityDeposit;
  final String? couponCode;
  final double couponDiscount;
  final String paymentPlan;
  final String paymentStatus;
  final String status;
  final String? paymentRef;
  final String? paymentScreenshotUrl;
  final String location;
  final String? startOdometer;
  final String? endOdometer;
  final String? startFastag;
  final String? returnFastag;
  final String? pickupStatus;
  final DateTime? createdAt;

  const BookingModel({
    required this.id,
    required this.bookingId,
    required this.bookingNumber,
    this.firebaseUid,
    required this.userName,
    required this.userEmail,
    this.userPhone,
    required this.vehicleReg,
    required this.vehicleName,
    required this.vehicleCategory,
    required this.pickupDate,
    required this.dropDate,
    required this.duration,
    required this.days,
    required this.hours,
    required this.withDriver,
    required this.baseAmount,
    required this.totalAmount,
    required this.finalAmount,
    required this.advanceAmount,
    required this.remainingBalance,
    required this.securityDeposit,
    this.couponCode,
    required this.couponDiscount,
    required this.paymentPlan,
    required this.paymentStatus,
    required this.status,
    this.paymentRef,
    this.paymentScreenshotUrl,
    required this.location,
    this.startOdometer,
    this.endOdometer,
    this.startFastag,
    this.returnFastag,
    this.pickupStatus,
    this.createdAt,
  });

  bool get isConfirmed => status == '''confirmed''' || status == '''active''' || status == '''completed''';
  bool get isPendingVerification => paymentStatus == '''pending_verification''' || status == '''pending_verification''';
  bool get isCancelled => status == 'cancelled' || paymentStatus == 'rejected';
  String get invoiceNumber => 'INV-$bookingId';

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic val) {
      if (val == null) return DateTime.now();
      try {
        return DateTime.parse(val.toString());
      } catch (_) {
        return DateTime.now();
      }
    }

    double parseDouble(dynamic val, [double def = 0.0]) {
      if (val is num) return val.toDouble();
      return double.tryParse(val?.toString() ?? '''''') ?? def;
    }

    int parseInt(dynamic val, [int def = 0]) {
      if (val is int) return val;
      return int.tryParse(val?.toString() ?? '''''') ?? def;
    }

    return BookingModel(
      id: parseInt(json['''id''']),
      bookingId: (json['''bookingId'''] ?? json['''booking_id'''] ?? json['''booking_number'''] ?? '''''').toString(),
      bookingNumber: (json['''bookingNumber'''] ?? json['''booking_number'''] ?? json['''bookingId'''] ?? '''''').toString(),
      firebaseUid: json['''firebaseUid''']?.toString() ?? json['''firebase_uid''']?.toString(),
      userName: (json['''userName'''] ?? json['''user_name'''] ?? '''Customer''').toString(),
      userEmail: (json['''userEmail'''] ?? json['''user_email'''] ?? '''''').toString(),
      userPhone: json['''userPhone''']?.toString() ?? json['''user_phone''']?.toString(),
      vehicleReg: (json['''vehicleReg'''] ?? json['''vehicle_reg'''] ?? '''''').toString(),
      vehicleName: (json['''vehicleName'''] ?? json['''vehicle_name'''] ?? '''Vehicle''').toString(),
      vehicleCategory: (json['''vehicleCategory'''] ?? json['''vehicle_category'''] ?? '''Sedan''').toString(),
      pickupDate: parseDate(json['''pickupDate'''] ?? json['''pickup_date''']),
      dropDate: parseDate(json['''dropDate'''] ?? json['''drop_date''']),
      duration: (json['''duration'''] ?? '''1 Day''').toString(),
      days: parseInt(json['''days'''], 1),
      hours: parseInt(json['''hours'''], 24),
      withDriver: json['''withDriver'''] == 1 || json['''with_driver'''] == 1 || json['''withDriver'''] == true,
      baseAmount: parseDouble(json['''baseAmount'''] ?? json['''base_amount''']),
      totalAmount: parseDouble(json['''totalAmount'''] ?? json['''total_amount''']),
      finalAmount: parseDouble(json['''finalAmount'''] ?? json['''final_amount'''] ?? json['''total_amount''']),
      advanceAmount: parseDouble(json['''advanceAmount'''] ?? json['''advance_amount''']),
      remainingBalance: parseDouble(json['''remainingBalance'''] ?? json['''remaining_balance''']),
      securityDeposit: parseDouble(json['''securityDeposit'''] ?? json['''security_deposit''']),
      couponCode: json['''couponCode''']?.toString() ?? json['''coupon_code''']?.toString(),
      couponDiscount: parseDouble(json['''couponDiscount'''] ?? json['''coupon_discount''']),
      paymentPlan: (json['''paymentPlan'''] ?? json['''payment_plan'''] ?? '''advance''').toString(),
      paymentStatus: (json['''paymentStatus'''] ?? json['''payment_status'''] ?? '''pending_payment''').toString(),
      status: (json['''status'''] ?? json['''booking_status'''] ?? '''pending_payment''').toString(),
      paymentRef: json['''paymentRef''']?.toString() ?? json['''payment_ref''']?.toString(),
      paymentScreenshotUrl: json['''paymentScreenshotUrl''']?.toString() ?? json['''payment_screenshot_url''']?.toString(),
      location: (json['''location'''] ?? '''Gavson Business Park, Ghansoli''').toString(),
      startOdometer: json['''startOdometer''']?.toString() ?? json['''start_odometer''']?.toString(),
      endOdometer: json['''endOdometer''']?.toString() ?? json['''end_odometer''']?.toString(),
      startFastag: json['''startFastag''']?.toString() ?? json['''start_fastag''']?.toString(),
      returnFastag: json['''returnFastag''']?.toString() ?? json['''return_fastag''']?.toString(),
      pickupStatus: json['''pickupStatus''']?.toString() ?? json['''pickup_status''']?.toString(),
      createdAt: json['''createdAt'''] != null || json['''created_at'''] != null
          ? parseDate(json['''createdAt'''] ?? json['''created_at'''])
          : null,
    );
  }
}
