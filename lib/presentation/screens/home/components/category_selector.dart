import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class CategorySelector extends StatelessWidget {
  final String selectedCategory;
  final Function(String category) onSelectCategory;

  const CategorySelector({
    super.key,
    required this.selectedCategory,
    required this.onSelectCategory,
  });

  static const List<Map<String, dynamic>> categories = [
    {
      'id': 'all',
      'label': 'All Fleet',
      'icon': Icons.grid_view_rounded,
    },
    {
      'id': 'suv',
      'label': 'SUVs & 4x4',
      'icon': Icons.terrain_rounded,
    },
    {
      'id': 'luxury',
      'label': 'Executive Luxury',
      'icon': Icons.diamond_rounded,
    },
    {
      'id': 'mpv',
      'label': '7-Seaters / MPVs',
      'icon': Icons.groups_rounded,
    },
    {
      'id': 'sedan',
      'label': 'Premium Sedans',
      'icon': Icons.directions_car_rounded,
    },
    {
      'id': 'economy',
      'label': 'City Hatchbacks',
      'icon': Icons.commute_rounded,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final cat = categories[index];
          final isSelected =
              selectedCategory.toLowerCase() == (cat['id'] as String).toLowerCase();
          final icon = cat['icon'] as IconData;

          return InkWell(
            onTap: () => onSelectCategory(cat['id'] as String),
            borderRadius: BorderRadius.circular(14),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                gradient: isSelected
                    ? const LinearGradient(
                        colors: [Color(0xFF0066FF), Color(0xFF0052CC)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: isSelected
                    ? null
                    : (isDark
                        ? AppColors.surfaceElevated
                        : AppColors.lightSurfaceElevated),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF3385FF)
                      : (isDark ? AppColors.border : AppColors.lightBorder),
                  width: isSelected ? 1.5 : 1,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: const Color(0xFF0066FF).withValues(alpha: 0.35),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    size: 16,
                    color: isSelected
                        ? Colors.white
                        : (isDark ? AppColors.primaryLight : AppColors.primary),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    cat['label'] as String,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                      color: isSelected
                          ? Colors.white
                          : (isDark
                              ? AppColors.textPrimary
                              : AppColors.lightTextPrimary),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
