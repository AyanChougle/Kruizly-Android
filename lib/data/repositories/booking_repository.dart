import '''../../core/constants/api_endpoints.dart''';
import '''../../core/errors/app_exceptions.dart''';
import '''../../core/network/api_client.dart''';
import '''../models/booking_model.dart''';

class BookingRepository {
  final ApiClient _apiClient;

  BookingRepository({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  Future<String> createBooking({
    required String bookingId,
    required String vehicleReg,
    required String vehicleName,
    required String vehicleCategory,
    required DateTime pickupDate,
    required DateTime dropDate,
    required String duration,
    required int days,
    required int hours,
    required bool withDriver,
    required double baseAmount,
    required double totalAmount,
    required double advanceAmount,
    required double remainingBalance,
    required double securityDeposit,
    String? couponCode,
    double couponDiscount = 0.0,
    String paymentPlan = '''advance''',
    String? userName,
    String? userEmail,
    String? userPhone,
  }) async {
    final response = await _apiClient.post(
      ApiEndpoints.createBooking,
      data: {
        '''bookingId''': bookingId,
        '''bookingNumber''': bookingId,
        '''vehicleReg''': vehicleReg,
        '''vehicleName''': vehicleName,
        '''vehicleCategory''': vehicleCategory,
        '''pickupDate''': pickupDate.toIso8601String(),
        '''dropDate''': dropDate.toIso8601String(),
        '''duration''': duration,
        '''days''': days,
        '''hours''': hours,
        '''withDriver''': withDriver ? 1 : 0,
        '''baseAmount''': baseAmount,
        '''totalAmount''': totalAmount,
        '''finalAmount''': totalAmount,
        '''advanceAmount''': advanceAmount,
        '''remainingBalance''': remainingBalance,
        '''securityDeposit''': securityDeposit,
        '''couponCode''': couponCode,
        '''couponDiscount''': couponDiscount,
        '''paymentPlan''': paymentPlan,
        '''paymentStatus''': '''pending_payment''',
        '''status''': '''pending_payment''',
        '''userName''': ?userName,
        '''userEmail''': ?userEmail,
        '''userPhone''': ?userPhone,
      },
    );

    if (response is Map<String, dynamic> && response['''bookingId'''] != null) {
      return response['''bookingId'''].toString();
    }
    throw const ServerException('''Failed to record booking.''');
  }

  Future<List<BookingModel>> getMyBookings() async {
    final response = await _apiClient.get(ApiEndpoints.myBookings);
    if (response is Map<String, dynamic> && response['''bookings'''] is List) {
      return (response['''bookings'''] as List)
          .map((b) => BookingModel.fromJson(b as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  Future<BookingModel?> getBookingDetail(String bookingId) async {
    final response = await _apiClient.get(
      ApiEndpoints.bookingDetail,
      queryParameters: {'''id''': bookingId},
    );

    if (response is Map<String, dynamic> && response['''booking'''] != null) {
      return BookingModel.fromJson(
        response['''booking'''] as Map<String, dynamic>,
      );
    }
    return null;
  }

  Future<void> cancelBooking(String bookingId, String reason) async {
    final response = await _apiClient.post(
      ApiEndpoints.cancelBooking,
      data: {'''bookingId''': bookingId, '''reason''': reason},
    );

    if (response is Map<String, dynamic> && response['''success'''] == true) {
      return;
    }
    throw const ServerException('''Failed to cancel booking.''');
  }
}
