import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/vehicle_model.dart';
import '../../../state/app_providers.dart';
import '../../../widgets/custom_button.dart';

class VehiclePricingSheet extends ConsumerWidget {
  final VehicleModel vehicle;
  final VoidCallback onBookNow;

  const VehiclePricingSheet({
    super.key,
    required this.vehicle,
    required this.onBookNow,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final isDark = themeMode == ThemeMode.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surface : AppColors.lightSurface,
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.border : AppColors.lightBorder,
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.5)
                : Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    text: '₹${vehicle.priceDay.toInt()} ',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: isDark ? AppColors.primary : AppColors.primary,
                    ),
                    children: [
                      TextSpan(
                        text: '/ day',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: isDark
                              ? AppColors.textSecondary
                              : AppColors.lightTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '₹${vehicle.securityDeposit.toInt()} deposit (refundable)',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark
                        ? AppColors.textMuted
                        : AppColors.lightTextSecondary,
                  ),
                ),
              ],
            ),
            CustomButton(
              text: 'Reserve Now',
              width: 150,
              height: 46,
              onPressed: vehicle.isAvailable ? onBookNow : null,
            ),
          ],
        ),
      ),
    );
  }
}
