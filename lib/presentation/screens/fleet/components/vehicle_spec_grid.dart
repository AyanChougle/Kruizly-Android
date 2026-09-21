import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/vehicle_model.dart';
import '../../../state/app_providers.dart';
import '../../../widgets/glass_card.dart';

class VehicleSpecGrid extends ConsumerWidget {
  final VehicleModel vehicle;

  const VehicleSpecGrid({super.key, required this.vehicle});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final isDark = themeMode == ThemeMode.dark;

    final specs = [
      {'label': 'Transmission', 'val': vehicle.transmission, 'icon': Icons.settings_outlined},
      {'label': 'Fuel Type', 'val': vehicle.fuel, 'icon': Icons.local_gas_station_outlined},
      {'label': 'Seating', 'val': '${vehicle.seats} Passengers', 'icon': Icons.event_seat_outlined},
      {'label': 'Luggage', 'val': '${vehicle.bags} Bags', 'icon': Icons.luggage_outlined},
      {'label': 'Free KM Limit', 'val': '${vehicle.freeKm} km / day', 'icon': Icons.speed_outlined},
      {'label': 'Extra KM Fee', 'val': '₹${vehicle.extraKm.toInt()} / km', 'icon': Icons.add_road_outlined},
      {'label': 'Year', 'val': vehicle.year.toString(), 'icon': Icons.calendar_today_outlined},
      {'label': 'Location', 'val': 'Ghansoli Hub', 'icon': Icons.location_on_outlined},
    ];

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Vehicle Specifications',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.textPrimary : AppColors.lightTextPrimary,
            ),
          ),
          const SizedBox(height: 14),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 2.2,
            ),
            itemCount: specs.length,
            itemBuilder: (context, index) {
              final s = specs[index];
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceElevated : AppColors.lightSurfaceElevated,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isDark ? AppColors.borderLight : AppColors.lightBorder,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      s['icon'] as IconData,
                      size: 18,
                      color: isDark ? AppColors.primaryLight : AppColors.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            s['label'] as String,
                            style: TextStyle(
                              fontSize: 10,
                              color: isDark ? AppColors.textSecondary : AppColors.lightTextSecondary,
                            ),
                          ),
                          Text(
                            s['val'] as String,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isDark ? AppColors.textPrimary : AppColors.lightTextPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
