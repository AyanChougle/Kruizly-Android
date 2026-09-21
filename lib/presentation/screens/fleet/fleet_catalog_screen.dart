import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../state/app_providers.dart';
import '../../state/booking_provider.dart';
import '../../state/fleet_provider.dart';
import '../../widgets/vehicle_card.dart';
import 'components/fleet_filter_bar.dart';

class FleetCatalogScreen extends ConsumerWidget {
  const FleetCatalogScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fleetState = ref.watch(fleetProvider);
    final fleetNotifier = ref.read(fleetProvider.notifier);
    final themeMode = ref.watch(themeModeProvider);
    final isDark = themeMode == ThemeMode.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Our Fleet',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: isDark ? AppColors.textPrimary : AppColors.lightTextPrimary,
          ),
        ),
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        backgroundColor: isDark ? AppColors.surface : AppColors.lightSurface,
        onRefresh: () => fleetNotifier.fetchFleet(),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: FleetFilterBar(
                searchQuery: fleetState.searchQuery,
                selectedCategory: fleetState.selectedCategory,
                selectedTransmission: fleetState.selectedTransmission,
                sortBy: fleetState.sortBy,
                onSearchChanged: fleetNotifier.setSearchQuery,
                onCategoryChanged: fleetNotifier.setCategory,
                onTransmissionChanged: fleetNotifier.setTransmission,
                onSortChanged: fleetNotifier.setSortBy,
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: fleetState.isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    )
                  : fleetState.filteredVehicles.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.car_crash_outlined,
                            size: 54,
                            color: AppColors.textMuted,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No vehicles match your criteria',
                            style: TextStyle(
                              color: isDark
                                  ? AppColors.textPrimary
                                  : AppColors.lightTextPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Try clearing filters or changing search terms.',
                            style: TextStyle(
                              color: isDark
                                  ? AppColors.textSecondary
                                  : AppColors.lightTextSecondary,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextButton(
                            onPressed: () {
                              fleetNotifier.setCategory('all');
                              fleetNotifier.setTransmission('all');
                              fleetNotifier.setSearchQuery('');
                            },
                            child: const Text(
                              'Clear All Filters',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      itemCount: fleetState.filteredVehicles.length,
                      itemBuilder: (context, index) {
                        final v = fleetState.filteredVehicles[index];
                        return VehicleCard(
                          vehicle: v,
                          onTap: () => context.push('/fleet/${v.id}'),
                          onBookNow: () {
                            ref.read(bookingProvider.notifier).setVehicle(v);
                            context.push('/booking');
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
