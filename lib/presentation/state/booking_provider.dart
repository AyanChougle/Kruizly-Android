import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/coupon_model.dart';
import '../../data/models/vehicle_model.dart';
import 'app_providers.dart';

class BookingPriceBreakdown {
  final int durationHours;
  final int durationDays;
  final String formattedDuration;
  final double hourlyRate;
  final double driverHourlyRate;
  final double rentalTotal;
  final double driverTotal;
  final double securityDeposit;
  final double couponDiscount;
  final double finalAmount;
  final double advanceAmount;
  final double remainingBalance;

  const BookingPriceBreakdown({
    this.durationHours = 0,
    this.durationDays = 0,
    this.formattedDuration = '—',
    this.hourlyRate = 0,
    this.driverHourlyRate = 0,
    this.rentalTotal = 0,
    this.driverTotal = 0,
    this.securityDeposit = 0,
    this.couponDiscount = 0,
    this.finalAmount = 0,
    this.advanceAmount = 0,
    this.remainingBalance = 0,
  });
}

class BookingDraftState {
  final VehicleModel? vehicle;
  final DateTime pickupDate;
  final DateTime dropDate;
  final bool withDriver;
  final String paymentPlan; // "advance" or "full"
  final CouponModel? appliedCoupon;
  final bool isValidatingCoupon;
  final String? couponError;
  final bool isSubmitting;
  final String? submissionError;
  final String? createdBookingId;

  BookingDraftState({
    this.vehicle,
    DateTime? pickupDate,
    DateTime? dropDate,
    this.withDriver = false,
    this.paymentPlan = 'advance',
    this.appliedCoupon,
    this.isValidatingCoupon = false,
    this.couponError,
    this.isSubmitting = false,
    this.submissionError,
    this.createdBookingId,
  })  : pickupDate = pickupDate ?? DateTime.now().add(const Duration(hours: 2)),
        dropDate = dropDate ?? DateTime.now().add(const Duration(hours: 26));

  BookingPriceBreakdown get breakdown {
    if (vehicle == null) return const BookingPriceBreakdown();

    final diffMs = dropDate.difference(pickupDate).inMilliseconds;
    if (diffMs <= 0) return const BookingPriceBreakdown();

    final hours = (diffMs / (1000 * 60 * 60)).ceil().clamp(1, 999999);
    final days = (hours / 24).ceil().clamp(1, 999999);

    final dayLabel = days == 1 ? '1 Day' : '$days Days';
    final hrLabel = '$hours ${hours == 1 ? "hr" : "hrs"}';
    final formattedDuration = '$dayLabel ($hrLabel)';

    final priceDay = vehicle!.priceDay;
    final hourlyRate = vehicle!.priceHour > 0
        ? vehicle!.priceHour
        : (priceDay > 0 ? priceDay / 24.0 : 0.0);

    final driverHourlyRate = vehicle!.driverPriceHour;

    final rentalTotal = (hours * hourlyRate).roundToDouble();
    final driverTotal = withDriver ? (hours * driverHourlyRate).roundToDouble() : 0.0;
    final securityDeposit = vehicle!.securityDeposit;

    double couponDiscount = 0.0;
    if (appliedCoupon != null) {
      final c = appliedCoupon!;
      if (rentalTotal >= c.minOrder) {
        if (c.type.toLowerCase() == 'percent' || c.type.toLowerCase() == 'percentage') {
          var disc = (rentalTotal * c.value / 100.0).roundToDouble();
          final maxCap = c.maxDiscountValue;
          if (maxCap > 0 && disc > maxCap) {
            disc = maxCap;
          }
          couponDiscount = disc.clamp(0.0, rentalTotal);
        } else {
          couponDiscount = c.value.clamp(0.0, rentalTotal);
        }
      }
    }

    final finalAmount = (rentalTotal + driverTotal + securityDeposit - couponDiscount).clamp(0.0, double.infinity);
    final advanceAmount = paymentPlan == 'full' ? finalAmount : (finalAmount > 500.0 ? 500.0 : finalAmount);
    final remainingBalance = (finalAmount - advanceAmount).clamp(0.0, double.infinity);

    return BookingPriceBreakdown(
      durationHours: hours,
      durationDays: days,
      formattedDuration: formattedDuration,
      hourlyRate: hourlyRate,
      driverHourlyRate: driverHourlyRate,
      rentalTotal: rentalTotal,
      driverTotal: driverTotal,
      securityDeposit: securityDeposit,
      couponDiscount: couponDiscount,
      finalAmount: finalAmount,
      advanceAmount: advanceAmount,
      remainingBalance: remainingBalance,
    );
  }

  BookingDraftState copyWith({
    VehicleModel? vehicle,
    DateTime? pickupDate,
    DateTime? dropDate,
    bool? withDriver,
    String? paymentPlan,
    CouponModel? appliedCoupon,
    bool clearCoupon = false,
    bool? isValidatingCoupon,
    String? couponError,
    bool clearCouponError = false,
    bool? isSubmitting,
    String? submissionError,
    bool clearSubmissionError = false,
    String? createdBookingId,
  }) {
    return BookingDraftState(
      vehicle: vehicle ?? this.vehicle,
      pickupDate: pickupDate ?? this.pickupDate,
      dropDate: dropDate ?? this.dropDate,
      withDriver: withDriver ?? this.withDriver,
      paymentPlan: paymentPlan ?? this.paymentPlan,
      appliedCoupon: clearCoupon ? null : (appliedCoupon ?? this.appliedCoupon),
      isValidatingCoupon: isValidatingCoupon ?? this.isValidatingCoupon,
      couponError: clearCouponError ? null : (couponError ?? this.couponError),
      isSubmitting: isSubmitting ?? this.isSubmitting,
      submissionError: clearSubmissionError ? null : (submissionError ?? this.submissionError),
      createdBookingId: createdBookingId ?? this.createdBookingId,
    );
  }
}

class BookingNotifier extends StateNotifier<BookingDraftState> {
  final Ref _ref;

  BookingNotifier(this._ref) : super(BookingDraftState());

  void setVehicle(VehicleModel vehicle) {
    state = state.copyWith(vehicle: vehicle);
  }

  void setDates(DateTime pickup, DateTime drop) {
    state = state.copyWith(pickupDate: pickup, dropDate: drop);
  }

  void toggleDriver(bool withDriver) {
    state = state.copyWith(withDriver: withDriver);
  }

  void setPaymentPlan(String plan) {
    state = state.copyWith(paymentPlan: plan);
  }

  Future<bool> applyCoupon(String code) async {
    final cleanCode = code.trim().toUpperCase();
    if (cleanCode.isEmpty) {
      state = state.copyWith(couponError: 'Please enter a coupon code.');
      return false;
    }

    state = state.copyWith(isValidatingCoupon: true, clearCouponError: true);
    try {
      final couponRepo = _ref.read(couponRepositoryProvider);
      final rentalTotal = state.breakdown.rentalTotal;
      final result = await couponRepo.validateCoupon(cleanCode, rentalTotal);

      if (!result.isValid) {
        state = state.copyWith(
          isValidatingCoupon: false,
          couponError: result.description.isNotEmpty ? result.description : 'Coupon is invalid or expired.',
        );
        return false;
      }

      final coupon = result.coupon ?? CouponModel(
        code: cleanCode,
        discountType: 'flat',
        discountValue: result.discountAmount,
        minOrder: 0,
        label: result.label,
        description: result.description,
      );

      if (rentalTotal < coupon.minOrder) {
        state = state.copyWith(
          isValidatingCoupon: false,
          couponError: 'Minimum booking amount of ₹${coupon.minOrder.toInt()} required for this coupon.',
        );
        return false;
      }

      state = state.copyWith(
        isValidatingCoupon: false,
        appliedCoupon: coupon,
        clearCouponError: true,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isValidatingCoupon: false,
        couponError: e.toString(),
      );
      return false;
    }
  }

  void removeCoupon() {
    state = state.copyWith(clearCoupon: true, clearCouponError: true);
  }

  Future<String?> submitBooking({
    String? userName,
    String? userEmail,
    String? userPhone,
  }) async {
    final v = state.vehicle;
    if (v == null) {
      state = state.copyWith(submissionError: 'Please select a vehicle first.');
      return null;
    }

    final bk = state.breakdown;
    final bookingId = 'BK${DateTime.now().millisecondsSinceEpoch.toString().substring(3)}';

    state = state.copyWith(isSubmitting: true, clearSubmissionError: true);
    try {
      final bookingRepo = _ref.read(bookingRepositoryProvider);
      final recordedId = await bookingRepo.createBooking(
        bookingId: bookingId,
        vehicleReg: v.registrationNumber,
        vehicleName: v.title,
        vehicleCategory: v.category,
        pickupDate: state.pickupDate,
        dropDate: state.dropDate,
        duration: bk.formattedDuration,
        days: bk.durationDays,
        hours: bk.durationHours,
        withDriver: state.withDriver,
        baseAmount: bk.rentalTotal,
        totalAmount: bk.finalAmount,
        advanceAmount: bk.advanceAmount,
        remainingBalance: bk.remainingBalance,
        securityDeposit: bk.securityDeposit,
        couponCode: state.appliedCoupon?.code,
        couponDiscount: bk.couponDiscount,
        paymentPlan: state.paymentPlan,
        userName: userName,
        userEmail: userEmail,
        userPhone: userPhone,
      );

      state = state.copyWith(
        isSubmitting: false,
        createdBookingId: recordedId,
      );
      return recordedId;
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        submissionError: e.toString(),
      );
      return null;
    }
  }

  void reset() {
    state = BookingDraftState();
  }
}

final bookingProvider = StateNotifierProvider<BookingNotifier, BookingDraftState>((ref) {
  return BookingNotifier(ref);
});
