import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../widgets/glass_card.dart';

class DriverOptionToggle extends StatelessWidget {
  final bool withDriver;
  final double driverPrice;
  final Function(bool val) onToggle;

  const DriverOptionToggle({
    super.key,
    required this.withDriver,
    required this.driverPrice,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.person_pin_outlined,
              color: AppColors.primaryLight,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Add Chauffeur / Driver',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: context.themeTextPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  withDriver
                      ? 'Professional driver included (₹${driverPrice.toInt()}/day)'
                      : 'Self-drive rental (Zero driver charges)',
                  style: TextStyle(
                    fontSize: 12,
                    color: context.themeTextSecondary,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: withDriver,
            activeThumbColor: AppColors.primaryLight,
            activeTrackColor: AppColors.primary.withValues(alpha: 0.4),
            inactiveThumbColor: context.themeTextSecondary,
            inactiveTrackColor: context.themeSurfaceElevated,
            onChanged: onToggle,
          ),
        ],
      ),
    );
  }
}
