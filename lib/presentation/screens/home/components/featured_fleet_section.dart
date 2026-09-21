import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../state/fleet_provider.dart';
import '../../../widgets/vehicle_card.dart';

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

    if (fleetState.isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 40),
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    final vehicles = fleetState.vehicles.take(4).toList();

    if (vehicles.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: const Center(
          child: Text(
            'Fleet is currently being updated.',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
      );
    }

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
        ...vehicles.map(
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
