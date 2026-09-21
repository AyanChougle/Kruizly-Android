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

  static const List<Map<String, String>> categories = [
    {'id': 'all', 'label': 'All Fleet', 'icon': 'fleet'},
    {'id': 'suv', 'label': 'SUVs', 'icon': 'suv'},
    {'id': 'luxury', 'label': 'Luxury', 'icon': 'luxury'},
    {'id': 'mpv', 'label': '7-Seater / MPV', 'icon': 'mpv'},
    {'id': 'sedan', 'label': 'Sedan', 'icon': 'sedan'},
    {'id': 'economy', 'label': 'Hatchback', 'icon': 'economy'},
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final cat = categories[index];
          final isSelected =
              selectedCategory.toLowerCase() == cat['id']!.toLowerCase();

          return InkWell(
            onTap: () => onSelectCategory(cat['id']!),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary
                    : (isDark ? AppColors.surfaceElevated : AppColors.lightSurfaceElevated),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? AppColors.primary : (isDark ? AppColors.border : AppColors.lightBorder),
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.35),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Center(
                child: Text(
                  cat['label']!,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected
                        ? Colors.white
                        : (isDark ? AppColors.textSecondary : AppColors.lightTextPrimary),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
