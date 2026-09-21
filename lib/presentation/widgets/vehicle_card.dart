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

  const VehicleCard({
    super.key,
    required this.vehicle,
    required this.onTap,
    required this.onBookNow,
  });

  Widget _buildCarImage(bool isDark) {
    final candidates = AppAssets.getCarImageCandidates(
      vehicle.brand,
      vehicle.model,
    );

    Widget buildFromAsset(int candidateIndex) {
      if (candidateIndex >= candidates.length) {
        return _buildNetworkOrFallback();
      }
      return Image.asset(
        candidates[candidateIndex],
        height: 195,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return buildFromAsset(candidateIndex + 1);
        },
      );
    }

    return Container(
      width: double.infinity,
      height: 215,
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF141C28) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(20),
        gradient: isDark
            ? const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF1B2433), Color(0xFF0E141E)],
              )
            : const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFFFFFFF), Color(0xFFF1F5F9)],
              ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Center(child: buildFromAsset(0)),
    );
  }

  Widget _buildNetworkOrFallback() {
    if (vehicle.imageUrl != null && vehicle.imageUrl!.isNotEmpty) {
      final netUrl = vehicle.imageUrl!.startsWith('http')
          ? vehicle.imageUrl!
          : '${AppConfig.mediaBaseUrl}/${vehicle.imageUrl!}';
      return CachedNetworkImage(
        imageUrl: netUrl,
        height: 195,
        fit: BoxFit.contain,
        placeholder: (c, u) => const Center(
          child: SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.primary,
            ),
          ),
        ),
        errorWidget: (c, u, e) => Image.asset(
          AppAssets.carPlaceholder,
          height: 195,
          fit: BoxFit.contain,
        ),
      );
    }
    return Image.asset(
      AppAssets.carPlaceholder,
      height: 195,
      fit: BoxFit.contain,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GlassCard(
      margin: const EdgeInsets.only(bottom: 20),
      borderRadius: 24,
      padding: EdgeInsets.zero,
      blur: 14,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Studio car showcase podium
            _buildCarImage(isDark),

            // Car Details
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Availability Status & Hourly Price
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: vehicle.isAvailable
                              ? const Color(0xFF10B981).withValues(alpha: 0.15)
                              : const Color(0xFFEF4444).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          vehicle.isAvailable ? 'AVAILABLE' : 'RENTED',
                          style: TextStyle(
                            color: vehicle.isAvailable
                                ? const Color(0xFF10B981)
                                : const Color(0xFFEF4444),
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '₹${vehicle.priceHour.toInt()}',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF0F172A),
                              letterSpacing: -0.5,
                              height: 1.0,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '/HOUR',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? const Color(0xFF94A3B8)
                                  : const Color(0xFF64748B),
                              letterSpacing: 0.6,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Vehicle Name
                  Text(
                    vehicle.fullName,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 3),

                  // Vehicle year and category
                  Text(
                    '${vehicle.year} • ${vehicle.categoryDisplay.toLowerCase()}',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: isDark
                          ? const Color(0xFF94A3B8)
                          : const Color(0xFF64748B),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Feature Pills Row
                  Row(
                    children: [
                      _buildTag(vehicle.transmission, isDark),
                      const SizedBox(width: 8),
                      _buildTag(vehicle.fuel, isDark),
                      const SizedBox(width: 8),
                      _buildTag('${vehicle.seats} Seats', isDark),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Thin Divider
                  Divider(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : AppColors.lightBorder,
                    height: 1,
                    thickness: 0.8,
                  ),
                  const SizedBox(height: 16),

                  // Action Buttons Row (Unified colors)
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 46,
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
                                borderRadius: BorderRadius.circular(24),
                              ),
                              padding: EdgeInsets.zero,
                            ),
                            child: const Text(
                              'BOOK NOW',
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.8,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      SizedBox(
                        height: 46,
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
                              borderRadius: BorderRadius.circular(24),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Show More',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: isDark
                                      ? Colors.white
                                      : const Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                Icons.keyboard_arrow_down_rounded,
                                size: 18,
                                color: isDark
                                    ? Colors.white70
                                    : const Color(0xFF64748B),
                              ),
                            ],
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.06)
            : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(8),
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
          fontSize: 12,
          color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
