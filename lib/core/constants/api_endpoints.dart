class ApiEndpoints {
  static const String health = '''/health.php''';

  // Users
  static const String usersMe = '''/users/me.php''';
  static const String usersSync = '''/users/sync.php''';
  static const String partnerCars = '''/users/partner-cars.php''';

  // Vehicles / Fleet
  static const String vehicles = '''/vehicles/index.php''';
  static const String vehicleDetail = '''/vehicles/detail.php''';
  static const String activeFleet = '''/vehicles/active-fleet.php''';

  // Bookings
  static const String createBooking = '''/bookings/create.php''';
  static const String myBookings = '''/bookings/my-bookings.php''';
  static const String bookingDetail = '''/bookings/detail.php''';
  static const String cancelBooking = '''/bookings/cancel.php''';

  // Payments
  static const String submitPayment = '''/payments/submit.php''';
  static const String payments = '''/payments/index.php''';

  // Coupons
  static const String validateCoupon = '''/coupons/validate.php''';
  static const String coupons = '''/coupons/index.php''';

  // Verification (KYC)
  static const String submitVerification = '''/verification/submit.php''';
  static const String myVerification = '''/verification/me.php''';

  // Media
  static const String uploadMedia = '''/media/upload.php''';
  static const String fileMedia = '''/media/file.php''';
  static const String myMedia = '''/media/my-media.php''';
  static const String deleteMedia = '''/media/delete.php''';

  // Invoices
  static const String getInvoice = '''/invoices/get.php''';
  static const String pdfInvoice = '''/invoices/pdf.php''';

  // Admin & Operations
  static const String adminStats = '''/admin/stats.php''';
  static const String adminBookings = '''/bookings/index.php''';
  static const String users = '''/users/index.php''';
  static const String userRole = '''/users/role.php''';
  static const String paymentsVerify = '''/payments/verify.php''';
  static const String verificationUserStatus = '''/verification/user-status.php''';
  static const String verificationList = '''/verification/index.php''';
}
