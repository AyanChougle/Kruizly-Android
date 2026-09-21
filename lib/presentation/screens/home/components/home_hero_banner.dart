import 'package:flutter/material.dart';
import '../../../../core/constants/app_assets.dart';
import '../../../../core/theme/app_colors.dart';

class HomeHeroBanner extends StatelessWidget {
  final VoidCallback onExploreTap;

  const HomeHeroBanner({super.key, required this.onExploreTap});

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: isDark
            ? const LinearGradient(
                colors: [Color(0xFF0C1424), Color(0xFF14243B)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : const LinearGradient(
                colors: [Color(0xFF0071E3), Color(0xFF0A84FF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
        border: Border.all(
          color: isDark ? AppColors.primary.withValues(alpha: 0.2) : Colors.transparent,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: isDark ? 0.12 : 0.25),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isDark ? AppColors.primary.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark ? AppColors.primary.withValues(alpha: 0.4) : Colors.white.withValues(alpha: 0.35),
              ),
            ),
            child: Text(
              'SELF-DRIVE & CHAUFFEUR IN MUMBAI / NAVI MUMBAI',
              style: TextStyle(
                color: isDark ? AppColors.primaryLight : Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Luxury on Demand.\nDrive Your Passion.',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              height: 1.2,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Sanitized vehicles, zero hidden costs, doorstep delivery, and 24x7 roadside support.',
            style: TextStyle(
              fontSize: 13,
              color: isDark ? AppColors.textSecondary : const Color(0xFFE0F2FE),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 140,
            child: Image.asset(
              AppAssets.carPlaceholder,
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) => const SizedBox.shrink(),
            ),
          ),
        ],
      ),
    );
  }
}
