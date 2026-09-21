import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../state/app_providers.dart';

class MainShell extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;

  const MainShell({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = navigationShell.currentIndex;
    final themeMode = ref.watch(themeModeProvider);
    final isDark = themeMode == ThemeMode.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.background : AppColors.lightBackground,
      body: navigationShell,
      extendBody: true,
      bottomNavigationBar: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xF2101622) : const Color(0xF8FFFFFF),
            borderRadius: BorderRadius.circular(24),
            gradient: isDark
                ? const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xF2161F2E),
                      Color(0xFA0B0F17),
                    ],
                  )
                : const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFFFFFFFF),
                      Color(0xFFF1F5F9),
                    ],
                  ),
            border: Border.all(
              color: isDark ? Colors.white.withValues(alpha: 0.14) : AppColors.lightBorder,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: isDark ? Colors.black.withValues(alpha: 0.45) : const Color(0x1F0F172A),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(
                  0,
                  Icons.home_outlined,
                  Icons.home_rounded,
                  'Home',
                  currentIndex,
                  isDark,
                ),
                _buildNavItem(
                  1,
                  Icons.directions_car_outlined,
                  Icons.directions_car_rounded,
                  'Fleet',
                  currentIndex,
                  isDark,
                ),
                _buildNavItem(
                  2,
                  Icons.luggage_outlined,
                  Icons.luggage_rounded,
                  'Trips',
                  currentIndex,
                  isDark,
                ),
                _buildNavItem(
                  3,
                  Icons.person_outline_rounded,
                  Icons.person_rounded,
                  'Profile',
                  currentIndex,
                  isDark,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    int index,
    IconData icon,
    IconData activeIcon,
    String label,
    int currentIndex,
    bool isDark,
  ) {
    final isSelected = index == currentIndex;
    final activeColor = AppColors.primary;
    final inactiveColor = isDark
        ? AppColors.textSecondary.withValues(alpha: 0.7)
        : AppColors.lightTextMuted;

    return InkWell(
      onTap: () => navigationShell.goBranch(
        index,
        initialLocation: index == navigationShell.currentIndex,
      ),
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: isDark ? 0.15 : 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: isSelected
              ? Border.all(
                  color: AppColors.primary.withValues(alpha: isDark ? 0.3 : 0.25),
                  width: 1,
                )
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              color: isSelected ? activeColor : inactiveColor,
              size: 22,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                letterSpacing: 0.2,
                color: isSelected ? activeColor : inactiveColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
