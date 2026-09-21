import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/network/api_client.dart';
import '''../../data/repositories/auth_repository.dart''';
import '''../../data/repositories/booking_repository.dart''';
import '''../../data/repositories/coupon_repository.dart''';
import '''../../data/repositories/fleet_repository.dart''';
import '''../../data/repositories/invoice_repository.dart''';
import '''../../data/repositories/kyc_repository.dart''';
import '../../data/repositories/admin_repository.dart';
import '../../data/repositories/partner_repository.dart';
import '../../data/repositories/payment_repository.dart';

final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(apiClient: ref.watch(apiClientProvider)),
);

final fleetRepositoryProvider = Provider<FleetRepository>(
  (ref) => FleetRepository(apiClient: ref.watch(apiClientProvider)),
);

final bookingRepositoryProvider = Provider<BookingRepository>(
  (ref) => BookingRepository(apiClient: ref.watch(apiClientProvider)),
);

final paymentRepositoryProvider = Provider<PaymentRepository>(
  (ref) => PaymentRepository(apiClient: ref.watch(apiClientProvider)),
);

final couponRepositoryProvider = Provider<CouponRepository>(
  (ref) => CouponRepository(apiClient: ref.watch(apiClientProvider)),
);

final invoiceRepositoryProvider = Provider<InvoiceRepository>(
  (ref) => InvoiceRepository(apiClient: ref.watch(apiClientProvider)),
);

final kycRepositoryProvider = Provider<KycRepository>(
  (ref) => KycRepository(apiClient: ref.watch(apiClientProvider)),
);

final partnerRepositoryProvider = Provider<PartnerRepository>(
  (ref) => PartnerRepository(apiClient: ref.watch(apiClientProvider)),
);

final adminRepositoryProvider = Provider<AdminRepository>(
  (ref) => AdminRepository(apiClient: ref.watch(apiClientProvider)),
);

/// StateNotifier that manages ThemeMode and persists user choice to SharedPreferences
class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  static const _key = 'kruizly_theme_mode';

  ThemeModeNotifier() : super(ThemeMode.dark) {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_key);
      if (saved == 'light') {
        state = ThemeMode.light;
      } else if (saved == 'dark') {
        state = ThemeMode.dark;
      }
    } catch (_) {}
  }

  Future<void> setTheme(ThemeMode mode) async {
    state = mode;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, mode == ThemeMode.light ? 'light' : 'dark');
    } catch (_) {}
  }

  Future<void> toggleTheme() async {
    final next = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    await setTheme(next);
  }
}

/// Controls Theme Mode: ThemeMode.dark vs ThemeMode.light (persisted)
final themeModeProvider =
    StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  return ThemeModeNotifier();
});
