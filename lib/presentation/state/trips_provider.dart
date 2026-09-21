import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/booking_model.dart';
import 'app_providers.dart';

class TripsState {
  final bool isLoading;
  final List<BookingModel> bookings;
  final String? errorMessage;
  final String filter; // "all", "active", "completed", "cancelled"

  const TripsState({
    this.isLoading = false,
    this.bookings = const [],
    this.errorMessage,
    this.filter = 'all',
  });

  List<BookingModel> get filteredBookings {
    if (filter == 'all') return bookings;
    if (filter == 'active') {
      return bookings.where((b) =>
          b.status.toLowerCase() == 'confirmed' ||
          b.status.toLowerCase() == 'active' ||
          b.status.toLowerCase() == 'pending_payment' ||
          b.status.toLowerCase() == 'pending').toList();
    }
    if (filter == 'completed') {
      return bookings.where((b) => b.status.toLowerCase() == 'completed').toList();
    }
    if (filter == 'cancelled') {
      return bookings.where((b) =>
          b.status.toLowerCase() == 'cancelled' ||
          b.status.toLowerCase() == 'rejected').toList();
    }
    return bookings;
  }

  TripsState copyWith({
    bool? isLoading,
    List<BookingModel>? bookings,
    String? errorMessage,
    bool clearError = false,
    String? filter,
  }) {
    return TripsState(
      isLoading: isLoading ?? this.isLoading,
      bookings: bookings ?? this.bookings,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      filter: filter ?? this.filter,
    );
  }
}

class TripsNotifier extends StateNotifier<TripsState> {
  final Ref _ref;

  TripsNotifier(this._ref) : super(const TripsState(isLoading: true)) {
    fetchTrips();
  }

  Future<void> fetchTrips() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final repo = _ref.read(bookingRepositoryProvider);
      final list = await repo.getMyBookings();
      state = state.copyWith(isLoading: false, bookings: list);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  void setFilter(String filter) {
    state = state.copyWith(filter: filter);
  }

  Future<bool> cancelBooking(String bookingId, String reason) async {
    try {
      final repo = _ref.read(bookingRepositoryProvider);
      await repo.cancelBooking(bookingId, reason);
      await fetchTrips();
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      return false;
    }
  }
}

final tripsProvider = StateNotifierProvider<TripsNotifier, TripsState>((ref) {
  return TripsNotifier(ref);
});

final bookingDetailProvider = FutureProvider.family<BookingModel?, String>((ref, bookingId) async {
  final repo = ref.read(bookingRepositoryProvider);
  return repo.getBookingDetail(bookingId);
});
