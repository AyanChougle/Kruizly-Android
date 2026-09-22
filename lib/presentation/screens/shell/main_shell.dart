import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../state/app_providers.dart';
import '../../widgets/background_video_widget.dart';

class MainShell extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;

  const MainShell({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = navigationShell.currentIndex;
    final themeMode = ref.watch(themeModeProvider);
    final isDark = themeMode == ThemeMode.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.black : const Color(0xFFF8FAFC),
      extendBody: true,
      body: BackgroundVideoWidget(
        isEnabled: true,
        isDark: isDark,
        overlayOpacity: isDark ? 0.68 : 0.85,
        child: navigationShell,
      ),
      bottomNavigationBar: _AppleNavBar(
        currentIndex: currentIndex,
        isDark: isDark,
        onTap: (index) {
          HapticFeedback.selectionClick();
          navigationShell.goBranch(
            index,
            initialLocation: index == navigationShell.currentIndex,
          );
        },
      ),
    );
  }
}

class _AppleNavBar extends StatelessWidget {
  final int currentIndex;
  final bool isDark;
  final ValueChanged<int> onTap;

  const _AppleNavBar({
    required this.currentIndex,
    required this.isDark,
    required this.onTap,
  });

  static const _items = [
    (icon: Icons.home_outlined, activeIcon: Icons.home_rounded, label: 'Home'),
    (
      icon: Icons.directions_car_outlined,
      activeIcon: Icons.directions_car_filled_rounded,
      label: 'Fleet',
    ),
    (
      icon: Icons.add_business_outlined,
      activeIcon: Icons.add_business_rounded,
      label: 'Host',
    ),
    (
      icon: Icons.luggage_outlined,
      activeIcon: Icons.luggage_rounded,
      label: 'Trips',
    ),
    (
      icon: Icons.person_outline_rounded,
      activeIcon: Icons.person_rounded,
      label: 'Profile',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              height: 64,
              padding: const EdgeInsets.symmetric(horizontal: 6),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.black.withValues(alpha: 0.38)
                    : Colors.white.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: isDark
                      ? AppColors.primary.withValues(alpha: 0.28)
                      : AppColors.primary.withValues(alpha: 0.18),
                  width: 0.8,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                  BoxShadow(
                    color: isDark
                        ? Colors.black.withValues(alpha: 0.4)
                        : const Color(0x12000000),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(_items.length, (i) {
                  return _NavItem(
                    index: i,
                    icon: _items[i].icon,
                    activeIcon: _items[i].activeIcon,
                    label: _items[i].label,
                    currentIndex: currentIndex,
                    isDark: isDark,
                    onTap: onTap,
                  );
                }),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final int index;
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final int currentIndex;
  final bool isDark;
  final ValueChanged<int> onTap;

  const _NavItem({
    required this.index,
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.currentIndex,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = index == currentIndex;
    final activeColor = AppColors.primary;
    final inactiveColor = isDark
        ? Colors.white.withValues(alpha: 0.48)
        : Colors.black.withValues(alpha: 0.42);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onTap(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark
                    ? AppColors.primary.withValues(alpha: 0.18)
                    : AppColors.primary.withValues(alpha: 0.12))
              : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              transitionBuilder: (child, anim) => ScaleTransition(
                scale: CurvedAnimation(parent: anim, curve: Curves.easeOutBack),
                child: FadeTransition(opacity: anim, child: child),
              ),
              child: Icon(
                isSelected ? activeIcon : icon,
                key: ValueKey(isSelected),
                color: isSelected ? activeColor : inactiveColor,
                size: 22,
              ),
            ),
            const SizedBox(height: 3),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                letterSpacing: isSelected ? 0.2 : 0.0,
                color: isSelected ? activeColor : inactiveColor,
              ),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }
}
