import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_assets.dart';
import '../../../core/theme/app_colors.dart';
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

  void _handleQuickSearch(DateTime pickup, DateTime drop) {
    ref.read(bookingProvider.notifier).setDates(pickup, drop);
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

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final themeMode = ref.watch(themeModeProvider);
    final isDark = themeMode == ThemeMode.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.black.withValues(alpha: 0.55)
                    : Colors.white.withValues(alpha: 0.72),
                border: Border(
                  bottom: BorderSide(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.black.withValues(alpha: 0.06),
                    width: 0.5,
                  ),
                ),
              ),
              child: AppBar(
                backgroundColor: Colors.transparent,
                surfaceTintColor: Colors.transparent,
                elevation: 0,
                titleSpacing: 16,
                title: Image.asset(
                  isDark ? AppAssets.logoDark : AppAssets.logoLight,
                  height: 36,
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) => Text(
                    'Kruizly',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.8,
                      color: isDark
                          ? AppColors.primaryLight
                          : AppColors.primary,
                    ),
                  ),
                ),
                actions: [
                  if (authState.isAuthenticated)
                    Padding(
                      padding: const EdgeInsets.only(right: 14),
                      child: GestureDetector(
                        onTap: () => context.go('/profile'),
                        child: CircleAvatar(
                          radius: 15,
                          backgroundColor: AppColors.primary,
                          child: Text(
                            (authState.user?.name ?? 'U')
                                .substring(0, 1)
                                .toUpperCase(),
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
                      child: IconButton(
                        tooltip: 'Sign In',
                        icon: Icon(
                          Icons.account_circle_outlined,
                          color: isDark
                              ? Colors.white54
                              : AppColors.lightTextSecondary,
                          size: 23,
                        ),
                        onPressed: () => context.push('/sign-in'),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        backgroundColor: isDark ? AppColors.surface : AppColors.lightSurface,
        onRefresh: () async {
          await ref.read(fleetProvider.notifier).fetchFleet();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              HomeHeroBanner(onExploreTap: () => context.go('/fleet')),
              const SizedBox(height: 20),
              QuickSearchCard(onSearch: _handleQuickSearch),
              const SizedBox(height: 24),
              Text(
                'Explore Fleet by Category',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: isDark
                      ? AppColors.textPrimary
                      : AppColors.lightTextPrimary,
                ),
              ),
              const SizedBox(height: 12),
              CategorySelector(
                selectedCategory: _selectedCategory,
                onSelectCategory: _onCategorySelected,
              ),
              const SizedBox(height: 24),
              FeaturedFleetSection(
                onVehicleTap: _handleVehicleTap,
                onBookNow: _handleBookNow,
                onViewAll: () => context.go('/fleet'),
              ),
              const SizedBox(height: 24),
              const WhyChooseSection(),
              const SizedBox(height: 36),
            ],
          ),
        ),
      ),
    );
  }
}
