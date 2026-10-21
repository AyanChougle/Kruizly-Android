import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/vehicle_model.dart';
import '../../../state/fleet_provider.dart';
import '../../../widgets/vehicle_card.dart';

/// Three featured showcase vehicles hardcoded for the home page
const _featuredShowcase = [
  VehicleModel(
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
  ),
  VehicleModel(
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
  VehicleModel(
    id: 9003,
    regNo: 'FEATURED-SWIFT',
    brand: 'Maruti Suzuki',
    model: 'Swift',
    year: 2026,
    category: 'economy',
    transmission: 'Manual',
    fuel: 'Petrol',
    seats: 5,
    bags: 2,
    priceDay: 2500,
    priceHour: 104,
    driverPrice: 1000,
    securityDeposit: 2000,
    freeKm: 200,
    extraKm: 8,
    location: 'Pune',
    isAvailable: true,
    status: 'active',
  ),
];

class FeaturedFleetSection extends ConsumerWidget {
  final Function(String vehicleId) onVehicleTap;
  final Function(String vehicleId) onBookNow;
  final VoidCallback onViewAll;

  const FeaturedFleetSection({
    super.key,
    required this.onVehicleTap,
    required this.onBookNow,
    required this.onViewAll,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fleetState = ref.watch(fleetProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final displayVehicles = fleetState.filteredVehicles.isNotEmpty
        ? fleetState.filteredVehicles.take(6).toList()
        : _featuredShowcase;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Featured Fleet',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: isDark ? AppColors.textPrimary : AppColors.lightTextPrimary,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Lock any car for ₹500 • 24h min. booking',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white60 : Colors.black54,
                  ),
                ),
              ],
            ),
            TextButton(
              onPressed: onViewAll,
              child: const Row(
                children: [
                  Text(
                    'Explore All',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(Icons.arrow_forward_ios, color: AppColors.primary, size: 12),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final isTablet = constraints.maxWidth >= 600;
            if (isTablet) {
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  childAspectRatio: 0.82,
                ),
                itemCount: displayVehicles.length,
                itemBuilder: (context, idx) {
                  final v = displayVehicles[idx];
                  return VehicleCard(
                    vehicle: v,
                    margin: EdgeInsets.zero,
                    onTap: () => onVehicleTap(v.id.toString()),
                    onBookNow: () => onBookNow(v.id.toString()),
                  );
                },
              );
            }

            return Column(
              children: displayVehicles
                  .map(
                    (v) => VehicleCard(
                      vehicle: v,
                      onTap: () => onVehicleTap(v.id.toString()),
                      onBookNow: () => onBookNow(v.id.toString()),
                    ),
                  )
                  .toList(),
            );
          },
        ),
      ],
    );
  }
}
