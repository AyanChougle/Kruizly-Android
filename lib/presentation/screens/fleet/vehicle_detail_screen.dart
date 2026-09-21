import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_assets.dart';
import '../../../core/theme/app_colors.dart';
import '../../state/app_providers.dart';
import '../../state/booking_provider.dart';
import '../../state/fleet_provider.dart';
import '../../widgets/glass_card.dart';
import 'components/vehicle_pricing_sheet.dart';
import 'components/vehicle_spec_grid.dart';

class VehicleDetailScreen extends ConsumerWidget {
  final String vehicleId;

  const VehicleDetailScreen({super.key, required this.vehicleId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vehicleAsync = ref.watch(vehicleDetailProvider(vehicleId));
    final themeMode = ref.watch(themeModeProvider);
    final isDark = themeMode == ThemeMode.dark;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.background
          : AppColors.lightBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new,
            color: isDark ? AppColors.textPrimary : AppColors.lightTextPrimary,
            size: 20,
          ),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Vehicle Details',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: isDark ? AppColors.textPrimary : AppColors.lightTextPrimary,
          ),
        ),
      ),
      body: vehicleAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (err, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const SizedBox(height: 12),
              Text(
                'Failed to load vehicle details: $err',
                style: const TextStyle(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.refresh(vehicleDetailProvider(vehicleId)),
                child: const Text('Try Again'),
              ),
            ],
          ),
        ),
        data: (vehicle) {
          if (vehicle == null) {
            return const Center(
              child: Text(
                'Vehicle not found.',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            );
          }

          final assetPath = AppAssets.getCarImagePath(
            vehicle.brand,
            vehicle.model,
          );

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: double.infinity,
                        height: 220,
                        child: Center(
                          child: Image.asset(
                            assetPath,
                            fit: BoxFit.contain,
                            errorBuilder: (_, _, _) {
                              if (vehicle.imageUrl != null &&
                                  vehicle.imageUrl!.isNotEmpty) {
                                return CachedNetworkImage(
                                  imageUrl: vehicle.imageUrl!,
                                  fit: BoxFit.contain,
                                  errorWidget: (_, _, _) =>
                                      Image.asset(AppAssets.carPlaceholder),
                                );
                              }
                              return Image.asset(AppAssets.carPlaceholder);
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: AppColors.primary.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Text(
                              vehicle.categoryDisplay.toUpperCase(),
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: vehicle.isAvailable
                                  ? AppColors.success.withValues(alpha: 0.15)
                                  : AppColors.error.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: vehicle.isAvailable
                                    ? AppColors.success.withValues(alpha: 0.4)
                                    : AppColors.error.withValues(alpha: 0.4),
                              ),
                            ),
                            child: Text(
                              vehicle.isAvailable ? 'AVAILABLE' : 'BOOKED',
                              style: TextStyle(
                                color: vehicle.isAvailable
                                    ? AppColors.success
                                    : AppColors.error,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        vehicle.fullName,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: isDark
                              ? AppColors.textPrimary
                              : AppColors.lightTextPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Registration: ${vehicle.regNo} • Year ${vehicle.year}',
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark
                              ? AppColors.textSecondary
                              : AppColors.lightTextSecondary,
                        ),
                      ),
                      const SizedBox(height: 20),
                      VehicleSpecGrid(vehicle: vehicle),
                      const SizedBox(height: 20),
                      GlassCard(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Included with Rental',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: isDark
                                    ? AppColors.textPrimary
                                    : AppColors.lightTextPrimary,
                              ),
                            ),
                            const SizedBox(height: 12),
                            _buildBenefitRow(
                              Icons.check_circle_outline,
                              'Comprehensive vehicle insurance covered',
                              isDark,
                            ),
                            const SizedBox(height: 8),
                            _buildBenefitRow(
                              Icons.check_circle_outline,
                              '100% Sanitized & clean cabin guarantee',
                              isDark,
                            ),
                            const SizedBox(height: 8),
                            _buildBenefitRow(
                              Icons.check_circle_outline,
                              '24/7 Roadside breakdown assistance in MH',
                              isDark,
                            ),
                            const SizedBox(height: 8),
                            _buildBenefitRow(
                              Icons.check_circle_outline,
                              'Doorstep delivery & pickup available on request',
                              isDark,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      GlassCard(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Requirements for Self-Drive',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: isDark
                                    ? AppColors.textPrimary
                                    : AppColors.lightTextPrimary,
                              ),
                            ),
                            const SizedBox(height: 12),
                            _buildRequirementRow(
                              '1. Minimum age of 21 years with valid original Driving License.',
                              isDark,
                            ),
                            const SizedBox(height: 6),
                            _buildRequirementRow(
                              '2. Aadhaar Card / Passport original verification at handover.',
                              isDark,
                            ),
                            const SizedBox(height: 6),
                            _buildRequirementRow(
                              '3. Security deposit refunded within 24 hours of car return.',
                              isDark,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
              VehiclePricingSheet(
                vehicle: vehicle,
                onBookNow: () {
                  ref.read(bookingProvider.notifier).setVehicle(vehicle);
                  context.push('/booking');
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBenefitRow(IconData icon, String text, bool isDark) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.success),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13,
              color: isDark
                  ? AppColors.textSecondary
                  : AppColors.lightTextSecondary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRequirementRow(String text, bool isDark) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 13,
        color: isDark ? AppColors.textSecondary : AppColors.lightTextSecondary,
        height: 1.4,
      ),
    );
  }
}
