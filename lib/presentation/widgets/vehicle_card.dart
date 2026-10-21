import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../core/config/app_config.dart';
import '../../core/constants/app_assets.dart';
import '../../data/models/vehicle_model.dart';

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

  Widget _buildCarImage() {
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
        height: 155,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return buildFromAsset(candidateIndex + 1);
        },
      );
    }

    return Container(
      width: double.infinity,
      height: 160,
      decoration: const BoxDecoration(
        color: Color(0xFFF1F1F6), // Matches authentic website studio card background
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Ambient ground shadow under vehicle
          Positioned(
            bottom: 10,
            child: Container(
              width: 180,
              height: 10,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(100),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.18),
                    blurRadius: 16,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),
          ),
          // Car Image
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: buildFromAsset(0),
          ),
        ],
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
        height: 155,
        fit: BoxFit.contain,
        placeholder: (c, u) => const Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Color(0xFF5FD8FE),
            ),
          ),
        ),
        errorWidget: (c, u, e) => Image.asset(
          AppAssets.carPlaceholder,
          width: double.infinity,
          height: 155,
          fit: BoxFit.contain,
        ),
      );
    }
    return Image.asset(
      AppAssets.carPlaceholder,
      width: double.infinity,
      height: 155,
      fit: BoxFit.contain,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Website card styling:
    // Outer card: dark slate navy container #0C151B with subtle border #292F32 and 20px rounded corners
    final cardBgColor = isDark ? const Color(0xFF0C151B) : Colors.white;
    final cardBorderColor = isDark ? const Color(0xFF232D34) : const Color(0xFFE2E8F0);

    return Container(
      margin: margin ?? const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cardBorderColor, width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.06),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Car Image with white website background
              _buildCarImage(),

              // 2. Card Content Body
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Row 1: AVAILABLE status badge on Left, Price on Right
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 3.5,
                          ),
                          decoration: BoxDecoration(
                            color: vehicle.isAvailable
                                ? const Color(0xFF10B981).withValues(alpha: 0.12)
                                : const Color(0xFFEF4444).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: vehicle.isAvailable
                                  ? const Color(0xFF10B981).withValues(alpha: 0.35)
                                  : const Color(0xFFEF4444).withValues(alpha: 0.35),
                              width: 0.8,
                            ),
                          ),
                          child: Text(
                            vehicle.isAvailable ? 'AVAILABLE' : 'RENTED',
                            style: TextStyle(
                              color: vehicle.isAvailable
                                  ? const Color(0xFF49CD86) // Website exact emerald green
                                  : const Color(0xFFEF4444),
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
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
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                                letterSpacing: -0.4,
                                height: 1.0,
                              ),
                            ),
                            const SizedBox(width: 2),
                            Text(
                              '/HOUR',
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                                color: isDark
                                    ? const Color(0xFF94A3B8)
                                    : const Color(0xFF64748B),
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Row 2: Car Title
                    Text(
                      vehicle.fullName,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                        letterSpacing: -0.3,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),

                    // Row 3: Year & Category
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${vehicle.year} • ${vehicle.categoryDisplay}',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? const Color(0xFF94A3B8)
                                : const Color(0xFF64748B),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          '₹${vehicle.priceDay.toInt()}/day',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF5FD8FE), // Website cyan accent
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),

                    // Row 4: Location with cyan pin
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 14,
                          color: Color(0xFF5FD8FE),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            vehicle.location.isNotEmpty
                                ? vehicle.location
                                : 'Gavson Business Park, Ghansoli',
                            style: const TextStyle(
                              fontSize: 11.5,
                              color: Color(0xFF5ACDF1), // Website cyan location text
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 9),

                    // Row 5: Feature Pills (Dark rounded containers with subtle borders)
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        _buildTag(vehicle.transmission, isDark),
                        _buildTag(vehicle.fuel, isDark),
                        _buildTag('${vehicle.seats} Seats', isDark),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Row 6: Divider
                    Divider(
                      color: isDark
                          ? const Color(0xFF1B252C)
                          : const Color(0xFFE2E8F0),
                      height: 1,
                      thickness: 0.8,
                    ),
                    const SizedBox(height: 12),

                    // Row 7: Action Buttons (BOOK NOW in Cyan + Show More in Dark Outline)
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 38,
                            child: ElevatedButton(
                              onPressed: vehicle.isAvailable ? onBookNow : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: vehicle.isAvailable
                                    ? const Color(0xFF5FD8FE) // Website cyan pill
                                    : const Color(0xFF334155),
                                foregroundColor: const Color(0xFF0F1E26), // Dark text on cyan
                                disabledBackgroundColor: const Color(0xFF242C33),
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
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.6,
                                  color: Color(0xFF0F1E26), // Dark text as on website
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
                                    ? const Color(0xFF1A1E23)
                                    : const Color(0xFFF8FAFC),
                                foregroundColor: isDark
                                    ? Colors.white
                                    : const Color(0xFF0F172A),
                                side: BorderSide(
                                  color: isDark
                                      ? const Color(0xFF2A343D)
                                      : const Color(0xFFCBD5E1),
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
      ),
    );
  }

  Widget _buildTag(String text, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF171C22)
            : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isDark
              ? const Color(0xFF222B32)
              : const Color(0xFFCBD5E1),
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

