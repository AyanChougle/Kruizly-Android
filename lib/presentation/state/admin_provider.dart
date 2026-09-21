import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/admin_stats_model.dart';
import '../../data/models/booking_model.dart';
import 'app_providers.dart';

final adminStatsProvider = FutureProvider<AdminStatsModel>((ref) async {
  final repo = ref.watch(adminRepositoryProvider);
  return await repo.fetchStats();
});

class AdminBookingsNotifier extends StateNotifier<AsyncValue<List<BookingModel>>> {
  final Ref _ref;

  AdminBookingsNotifier(this._ref) : super(const AsyncValue.loading()) {
    fetchBookings();
  }

  Future<void> fetchBookings() async {
    state = const AsyncValue.loading();
    try {
      final repo = _ref.read(adminRepositoryProvider);
      final bookings = await repo.fetchAllBookings();
      state = AsyncValue.data(bookings);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<bool> updateStatus({
    required String bookingId,
    required String newStatus,
    double? totalAmount,
  }) async {
    final repo = _ref.read(adminRepositoryProvider);
    final success = await repo.updateBookingStatus(
      bookingId: bookingId,
      status: newStatus,
      totalAmount: totalAmount,
    );

    // Optimistically update the list in memory
    state.whenData((bookings) {
      final updated = bookings.map((b) {
        if (b.bookingId == bookingId || b.id.toString() == bookingId) {
          return BookingModel(
            id: b.id,
            bookingId: b.bookingId,
            bookingNumber: b.bookingNumber,
            firebaseUid: b.firebaseUid,
            userName: b.userName,
            userEmail: b.userEmail,
            userPhone: b.userPhone,
            vehicleReg: b.vehicleReg,
            vehicleName: b.vehicleName,
            vehicleCategory: b.vehicleCategory,
            pickupDate: b.pickupDate,
            dropDate: b.dropDate,
            duration: b.duration,
            days: b.days,
            hours: b.hours,
            withDriver: b.withDriver,
            baseAmount: b.baseAmount,
            totalAmount: totalAmount ?? b.totalAmount,
            finalAmount: totalAmount ?? b.finalAmount,
            advanceAmount: b.advanceAmount,
            remainingBalance: b.remainingBalance,
            securityDeposit: b.securityDeposit,
            couponCode: b.couponCode,
            couponDiscount: b.couponDiscount,
            paymentPlan: b.paymentPlan,
            paymentStatus: newStatus == 'confirmed' ? 'paid' : (newStatus == 'cancelled' ? 'rejected' : b.paymentStatus),
            status: newStatus,
            paymentRef: b.paymentRef,
            paymentScreenshotUrl: b.paymentScreenshotUrl,
            location: b.location,
            startOdometer: b.startOdometer,
            endOdometer: b.endOdometer,
            startFastag: b.startFastag,
            returnFastag: b.returnFastag,
            pickupStatus: b.pickupStatus,
            createdAt: b.createdAt,
          );
        }
        return b;
      }).toList();
      state = AsyncValue.data(updated);
    });

    return success;
  }

  Future<bool> verifyPayment({
    required String bookingOrPaymentId,
    required String action,
    String? reason,
  }) async {
    final repo = _ref.read(adminRepositoryProvider);
    final success = await repo.verifyPayment(
      id: bookingOrPaymentId,
      action: action,
      reason: reason,
    );
    if (success) {
      await updateStatus(
        bookingId: bookingOrPaymentId,
        newStatus: action == 'approve' ? 'confirmed' : 'cancelled',
      );
    }
    return success;
  }

  Future<bool> updateKyc({
    required String uid,
    required String documentType,
    required String status,
    String? reason,
  }) async {
    final repo = _ref.read(adminRepositoryProvider);
    return await repo.updateKycStatus(
      uid: uid,
      documentType: documentType,
      status: status,
      reason: reason,
    );
  }
}

final adminBookingsProvider =
    StateNotifierProvider<AdminBookingsNotifier, AsyncValue<List<BookingModel>>>((ref) {
  return AdminBookingsNotifier(ref);
});

final adminUsersProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final repo = ref.watch(adminRepositoryProvider);
  return await repo.fetchUsers();
});

final adminKycListProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final repo = ref.watch(adminRepositoryProvider);
  return await repo.fetchKycList();
});

final adminCouponsProvider = FutureProvider<List<dynamic>>((ref) async {
  final repo = ref.watch(couponRepositoryProvider);
  return await repo.getActiveCoupons();
});

final selectedAdminRoleTabProvider = StateProvider<String>((ref) => 'ADMIN');
