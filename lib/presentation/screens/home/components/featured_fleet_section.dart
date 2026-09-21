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
    regNo: 'FEATURED-THAR',
    brand: 'Mahindra',
    model: 'Thar',
    year: 2026,
    category: 'suv',
    transmission: 'Manual',
    fuel: 'Diesel',
    seats: 4,
    bags: 2,
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
    // Still watch fleet to trigger load, but display hardcoded featured cars
    ref.watch(fleetProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Featured Vehicles',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: isDark ? AppColors.textPrimary : AppColors.lightTextPrimary,
              ),
            ),
            TextButton(
              onPressed: onViewAll,
              child: const Row(
                children: [
                  Text(
                    'View All',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
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
        ..._featuredShowcase.map(
          (v) => VehicleCard(
            vehicle: v,
            onTap: () => onVehicleTap(v.id.toString()),
            onBookNow: () => onBookNow(v.id.toString()),
          ),
        ),
      ],
    );
  }
}
