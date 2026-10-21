import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../core/config/app_config.dart';
import '../../core/constants/app_assets.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/vehicle_model.dart';
import 'glass_card.dart';

class VehicleCard extends StatelessWidget {
  final VehicleModel vehicle;
  final VoidCallback onTap;
  final VoidCallback onBookNow;
  final EdgeInsetsGeometry? margin;

  const VehicleCard({
    super.key,
    required this.vehicle,
    required this.onTap,
    required this.onBookNow,
    this.margin,
  });

  Widget _buildCarImage(bool isDark) {
    final candidates = AppAssets.getCarImageCandidates(
      vehicle.brand,
      vehicle.model,
      vehicle.imageUrl,
    );

    Widget buildFromAsset(int candidateIndex) {
      if (candidateIndex >= candidates.length) {
        return _buildNetworkOrFallback();
      }
      final assetPath = candidates[candidateIndex];
      return Image.asset(
        assetPath,
        width: double.infinity,
        height: 145,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return buildFromAsset(candidateIndex + 1);
        },
      );
    }

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      child: Container(
        width: double.infinity,
        height: 145,
        decoration: BoxDecoration(
          color: isDark
              ? const Color(0xFF080F1E).withValues(alpha: 0.7)
              : const Color(0xFFF1F5F9),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Ambient ground shadow under vehicle
            Positioned(
              bottom: 8,
              child: Container(
                width: 170,
                height: 10,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(100),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.15),
                      blurRadius: 14,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
            ),
            // Car Image
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              child: buildFromAsset(0),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNetworkOrFallback() {
    if (vehicle.imageUrl != null && vehicle.imageUrl!.isNotEmpty) {
      final netUrl = vehicle.imageUrl!.startsWith('http')
          ? vehicle.imageUrl!
          : '${AppConfig.mediaBaseUrl}/${vehicle.imageUrl!}';
      return CachedNetworkImage(
        imageUrl: netUrl,
        width: double.infinity,
        height: 145,
        fit: BoxFit.contain,
        placeholder: (c, u) => const Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.primary,
            ),
          ),
        ),
        errorWidget: (c, u, e) => Image.asset(
          AppAssets.carPlaceholder,
          width: double.infinity,
          height: 145,
          fit: BoxFit.contain,
        ),
      );
    }
    return Image.asset(
      AppAssets.carPlaceholder,
      width: double.infinity,
      height: 145,
      fit: BoxFit.contain,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GlassCard(
      margin: margin ?? const EdgeInsets.only(bottom: 16),
      borderRadius: 20,
      padding: EdgeInsets.zero,
      blur: 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Car Image Stage with native theme background
            _buildCarImage(isDark),

            // Car Details
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Availability Badge & Rates
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: vehicle.isAvailable
                              ? const Color(0xFF10B981).withValues(alpha: 0.15)
                              : const Color(0xFFEF4444).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: vehicle.isAvailable
                                ? const Color(0xFF10B981).withValues(alpha: 0.3)
                                : const Color(0xFFEF4444).withValues(alpha: 0.3),
                            width: 0.8,
                          ),
                        ),
                        child: Text(
                          vehicle.isAvailable ? 'AVAILABLE' : 'RENTED',
                          style: TextStyle(
                            color: vehicle.isAvailable
                                ? const Color(0xFF10B981)
                                : const Color(0xFFEF4444),
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            '₹${vehicle.priceHour.toInt()}',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                              letterSpacing: -0.3,
                              height: 1.0,
                            ),
                          ),
                          Text(
                            '/HOUR',
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? const Color(0xFF94A3B8)
                                  : const Color(0xFF64748B),
                              letterSpacing: 0.4,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // Vehicle Name
                  Text(
                    vehicle.fullName,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                      letterSpacing: -0.3,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),

                  // Vehicle year, category, and daily rate
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${vehicle.year} • ${vehicle.categoryDisplay.toLowerCase()}',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: isDark
                              ? const Color(0xFF94A3B8)
                              : const Color(0xFF64748B),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '₹${vehicle.priceDay.toInt()}/day',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryLight,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Feature Pills Row
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      _buildTag(vehicle.transmission, isDark),
                      _buildTag(vehicle.fuel, isDark),
                      _buildTag('${vehicle.seats} Seats', isDark),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Thin Divider
                  Divider(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : AppColors.lightBorder,
                    height: 1,
                    thickness: 0.8,
                  ),
                  const SizedBox(height: 10),

                  // Equal-sized Action Buttons (BOOK NOW and Show More)
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 38,
                          child: ElevatedButton(
                            onPressed: vehicle.isAvailable ? onBookNow : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: vehicle.isAvailable
                                  ? AppColors.primary
                                  : const Color(0xFF334155),
                              foregroundColor: Colors.white,
                              disabledBackgroundColor: const Color(0xFF334155),
                              disabledForegroundColor: Colors.white38,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              padding: EdgeInsets.zero,
                            ),
                            child: const Text(
                              'BOOK NOW',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.6,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: SizedBox(
                          height: 38,
                          child: OutlinedButton(
                            onPressed: onTap,
                            style: OutlinedButton.styleFrom(
                              backgroundColor: isDark
                                  ? Colors.white.withValues(alpha: 0.06)
                                  : Colors.black.withValues(alpha: 0.04),
                              foregroundColor: isDark
                                  ? Colors.white
                                  : const Color(0xFF0F172A),
                              side: BorderSide(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.12)
                                    : AppColors.lightBorder,
                                width: 0.8,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              padding: EdgeInsets.zero,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Show More',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: isDark
                                        ? Colors.white
                                        : const Color(0xFF0F172A),
                                  ),
                                ),
                                const SizedBox(width: 2),
                                Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  size: 16,
                                  color: isDark
                                      ? Colors.white70
                                      : const Color(0xFF64748B),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTag(String text, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.06)
            : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : AppColors.lightBorder,
          width: 0.8,
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10.5,
          color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
