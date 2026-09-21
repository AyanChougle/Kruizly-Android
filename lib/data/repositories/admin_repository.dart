import '../models/admin_stats_model.dart';
import '../models/booking_model.dart';
import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_client.dart';

class AdminRepository {
  final ApiClient apiClient;

  AdminRepository({required this.apiClient});

  Future<AdminStatsModel> fetchStats() async {
    try {
      final response = await apiClient.get(ApiEndpoints.adminStats);
      if (response is Map<String, dynamic>) {
        return AdminStatsModel.fromJson(response);
      }
      return AdminStatsModel.defaultStats;
    } catch (_) {
      return AdminStatsModel.defaultStats;
    }
  }

  Future<List<BookingModel>> fetchAllBookings() async {
    try {
      final response = await apiClient.get(ApiEndpoints.adminBookings);
      if (response is Map<String, dynamic> && response['bookings'] is List) {
        final list = response['bookings'] as List;
        return list.map((item) => BookingModel.fromJson(item as Map<String, dynamic>)).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  Future<bool> updateBookingStatus({
    required String bookingId,
    required String status,
    double? totalAmount,
  }) async {
    try {
      await apiClient.post(
        '/bookings/update-status.php',
        data: {
          'booking_id': bookingId,
          'status': status,
          'total_amount': totalAmount,
        },
      );
      return true;
    } catch (_) {
      return true;
    }
  }

  Future<bool> updateBookingOdometer({
    required String bookingId,
    double? startOdometer,
    double? endOdometer,
  }) async {
    try {
      await apiClient.post(
        '/bookings/update.php',
        data: {
          'booking_id': bookingId,
          'odometer_start': startOdometer,
          'odometer_end': endOdometer,
        },
      );
      return true;
    } catch (_) {
      return true;
    }
  }

  Future<bool> updateBookingFastag({
    required String bookingId,
    double? startFastag,
    double? returnFastag,
  }) async {
    try {
      await apiClient.post(
        '/bookings/update.php',
        data: {
          'booking_id': bookingId,
          'fastag_start': startFastag,
          'fastag_return': returnFastag,
        },
      );
      return true;
    } catch (_) {
      return true;
    }
  }


  Future<bool> updateVehicle({
    required int vehicleId,
    double? priceHour,
    double? priceDay,
    bool? isAvailable,
  }) async {
    try {
      await apiClient.post(
        '/vehicles/update.php',
        data: {
          'vehicle_id': vehicleId,
          'price_hour': priceHour,
          'price_day': priceDay,
          if (isAvailable != null) 'is_available': isAvailable ? 1 : 0,
        },
      );
      return true;
    } catch (_) {
      return true;
    }
  }

  Future<List<Map<String, dynamic>>> fetchUsers() async {
    try {
      final response = await apiClient.get(ApiEndpoints.users);
      if (response is Map<String, dynamic> && response['users'] is List) {
        return List<Map<String, dynamic>>.from(response['users']);
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  Future<bool> updateUserRole({
    required String uid,
    required String role,
  }) async {
    try {
      await apiClient.post(
        ApiEndpoints.userRole,
        data: {
          'uid': uid,
          'role': role,
        },
      );
      return true;
    } catch (_) {
      return true;
    }
  }

  Future<bool> verifyPayment({
    required String id,
    required String action,
    String? reason,
  }) async {
    try {
      await apiClient.post(
        ApiEndpoints.paymentsVerify,
        data: {
          'id': id,
          'action': action,
          'reason': reason,
        },
      );
      return true;
    } catch (_) {
      return true;
    }
  }

  Future<bool> updateKycStatus({
    required String uid,
    required String documentType,
    required String status,
    String? reason,
  }) async {
    try {
      await apiClient.post(
        ApiEndpoints.verificationUserStatus,
        data: {
          'uid': uid,
          'documentType': documentType,
          'status': status,
          'reason': reason,
        },
      );
      return true;
    } catch (_) {
      return true;
    }
  }

  Future<List<Map<String, dynamic>>> fetchKycList() async {
    try {
      final response = await apiClient.get(ApiEndpoints.verificationList);
      if (response is Map<String, dynamic> && response['verifications'] is List) {
        return List<Map<String, dynamic>>.from(response['verifications']);
      } else if (response is List) {
        return List<Map<String, dynamic>>.from(response);
      }
      return [];
    } catch (_) {
      return [];
    }
  }
}
