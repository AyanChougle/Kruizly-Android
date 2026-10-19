import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_assets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/vehicle_model.dart';
import '../../state/app_providers.dart';
import '../../state/auth_provider.dart';
import '../../state/booking_provider.dart';
import '../../state/fleet_provider.dart';
import 'components/category_selector.dart';
import 'components/featured_fleet_section.dart';
import 'components/home_hero_banner.dart';
import 'components/quick_search_card.dart';
import 'components/why_choose_section.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  String _selectedCategory = 'all';

  void _onCategorySelected(String category) {
    setState(() => _selectedCategory = category);
    ref.read(fleetProvider.notifier).setCategory(category);
    context.go('/fleet');
  }

  void _handleQuickSearch(DateTime pickup, DateTime drop, String hub) {
    ref.read(bookingProvider.notifier).setDates(pickup, drop);
    ref.read(fleetProvider.notifier).setHub(hub);
    context.go('/fleet');
  }

  void _handleVehicleTap(String vehicleId) {
    context.push('/fleet/$vehicleId');
  }

  void _handleBookNow(String vehicleId) {
    final vehicle = ref
        .read(fleetProvider)
        .vehicles
        .firstWhere((v) => v.id.toString() == vehicleId);
    ref.read(bookingProvider.notifier).setVehicle(vehicle);
    context.push('/booking');
  }

  void _handleBookTharRoxx() {
    final vehicles = ref.read(fleetProvider).vehicles;
    final thar = vehicles.firstWhere(
      (v) =>
          v.model.toLowerCase().contains('thar') ||
          v.brand.toLowerCase().contains('thar'),
      orElse: () => const VehicleModel(
        id: 9002,
        regNo: 'FEATURED-THAR-ROXX',
        brand: 'Mahindra',
        model: 'Thar Roxx',
        year: 2026,
        category: 'suv',
        transmission: 'Automatic',
        fuel: 'Diesel',
        seats: 5,
        bags: 3,
        priceDay: 5500,
        priceHour: 229,
        driverPrice: 1500,
        securityDeposit: 3000,
        freeKm: 200,
        extraKm: 10,
        location: 'Pune',
        isAvailable: true,
        status: 'active',
      ),
    );
    ref.read(bookingProvider.notifier).setVehicle(thar);
    context.push('/booking');
  }

  void _handleBookSpecific(String modelKey) {
    final vehicles = ref.read(fleetProvider).vehicles;
    final match = vehicles.firstWhere(
      (v) =>
          v.model.toLowerCase().contains(modelKey) ||
          v.brand.toLowerCase().contains(modelKey),
      orElse: () {
        if (modelKey == 'bmw') {
          return const VehicleModel(
            id: 9001,
            regNo: 'FEATURED-BMW',
            brand: 'BMW',
            model: '520D',
            year: 2026,
            category: 'luxury',
            transmission: 'Automatic',
            fuel: 'Diesel',
            seats: 5,
            bags: 3,
            priceDay: 18000,
            priceHour: 750,
            driverPrice: 2000,
            securityDeposit: 5000,
            freeKm: 250,
            extraKm: 15,
            location: 'Pune',
            isAvailable: true,
            status: 'active',
          );
        } else if (modelKey == 'innova') {
          return const VehicleModel(
            id: 9004,
            regNo: 'FEATURED-INNOVA',
            brand: 'Toyota',
            model: 'Innova Crysta',
            year: 2026,
            category: 'mpv',
            transmission: 'Manual',
            fuel: 'Diesel',
            seats: 7,
            bags: 4,
            priceDay: 3800,
            priceHour: 158,
            driverPrice: 1500,
            securityDeposit: 3000,
            freeKm: 200,
            extraKm: 12,
            location: 'Pune',
            isAvailable: true,
            status: 'active',
          );
        }
        return const VehicleModel(
          id: 9002,
          regNo: 'FEATURED-THAR-ROXX',
          brand: 'Mahindra',
          model: 'Thar Roxx',
          year: 2026,
          category: 'suv',
          transmission: 'Automatic',
          fuel: 'Diesel',
          seats: 5,
          bags: 3,
          priceDay: 5500,
          priceHour: 229,
          driverPrice: 1500,
          securityDeposit: 3000,
          freeKm: 200,
          extraKm: 10,
          location: 'Pune',
          isAvailable: true,
          status: 'active',
        );
      },
    );
    ref.read(bookingProvider.notifier).setVehicle(match);
    context.push('/booking');
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final themeMode = ref.watch(themeModeProvider);
    final isDark = themeMode == ThemeMode.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF030712) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF070D19) : Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        titleSpacing: 16,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
            height: 1,
          ),
        ),
        title: Row(
          children: [
            Image.asset(
              isDark ? AppAssets.logoDark : AppAssets.logoLight,
              height: 32,
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) => Text(
                'Kruizly',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.8,
                  color: isDark ? AppColors.primaryLight : AppColors.primary,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF0F172A)
                    : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? const Color(0xFF1E293B) : const Color(0xFFCBD5E1),
                  width: 0.8,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.location_on_rounded,
                    size: 11,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 3),
                  Text(
                    'Mumbai / Pune',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white70 : const Color(0xFF334155),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          if (authState.isAuthenticated && (authState.user?.isStaff ?? false))
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: GestureDetector(
                onTap: () => context.push('/staff-portal'),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF06D6A0).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFF06D6A0).withValues(alpha: 0.4),
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.admin_panel_settings_rounded,
                        color: Color(0xFF06D6A0),
                        size: 15,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'STAFF',
                        style: TextStyle(
                          color: Color(0xFF06D6A0),
                          fontSize: 10.5,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          if (authState.isAuthenticated)
            Padding(
              padding: const EdgeInsets.only(right: 14),
              child: GestureDetector(
                onTap: () => context.go('/profile'),
                child: CircleAvatar(
                  radius: 15,
                  backgroundColor: AppColors.primary,
                  child: Text(
                    (authState.user?.name ?? 'U').substring(0, 1).toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: TextButton(
                onPressed: () => context.push('/sign-in'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primaryLight,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                ),
                child: const Text(
                  'Sign In',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                ),
              ),
            ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        backgroundColor: isDark ? AppColors.surface : AppColors.lightSurface,
        onRefresh: () async {
          await ref.read(fleetProvider.notifier).fetchFleet();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Quick Search Capsule
                  GestureDetector(
                    onTap: () => context.go('/fleet'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF0F172A)
                            : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark
                              ? const Color(0xFF1E293B)
                              : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.search_rounded,
                            size: 20,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Search Thar Roxx, BMW 520D, Innova, Creta...',
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? Colors.white54
                                    : const Color(0xFF64748B),
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.tune_rounded,
                              size: 15,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // 2. Star Hero Highlights Carousel
                  HomeHeroBanner(
                    onExploreTap: () => context.go('/fleet'),
                    onBookTharRoxx: _handleBookTharRoxx,
                    onBookSpecific: _handleBookSpecific,
                  ),
                  const SizedBox(height: 16),

                  // 3. First Ride Discount Promo Banner
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 11,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFF1A1303),
                          Color(0xFF2E2007),
                          Color(0xFF45300B),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFFFFB703).withValues(alpha: 0.35),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFB703).withValues(alpha: 0.18),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.discount_rounded,
                            color: Color(0xFFFFB703),
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Flat ₹500 OFF On First Self-Drive',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(height: 1),
                              Text(
                                'Use coupon code FIRST500 at checkout',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Color(0xFFFFE8A3),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 4.5,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFB703),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'FIRST500',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w900,
                              color: Colors.black87,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 4. Plan Your Drive Reservation Capsule
                  QuickSearchCard(onSearch: _handleQuickSearch),
                  const SizedBox(height: 22),

                  // 5. Explore by Category Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Explore Fleet by Category',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                          color: isDark
                              ? AppColors.textPrimary
                              : AppColors.lightTextPrimary,
                          letterSpacing: -0.2,
                        ),
                      ),
                      TextButton(
                        onPressed: () => context.go('/fleet'),
                        child: const Text(
                          'All Fleets',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  CategorySelector(
                    selectedCategory: _selectedCategory,
                    onSelectCategory: _onCategorySelected,
                  ),
                  const SizedBox(height: 22),

                  // 6. Featured Fleet Showcase
                  FeaturedFleetSection(
                    onVehicleTap: _handleVehicleTap,
                    onBookNow: _handleBookNow,
                    onViewAll: () => context.go('/fleet'),
                  ),
                  const SizedBox(height: 22),

                  // 7. Why Kruizly Trust Pillars
                  const WhyChooseSection(),
                  const SizedBox(height: 95),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
