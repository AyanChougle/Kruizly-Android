import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class FleetFilterBar extends StatelessWidget {
  final String searchQuery;
  final String selectedCategory;
  final String selectedTransmission;
  final Function(String query) onSearchChanged;
  final Function(String category) onCategoryChanged;
  final Function(String transmission) onTransmissionChanged;

  const FleetFilterBar({
    super.key,
    required this.searchQuery,
    required this.selectedCategory,
    required this.selectedTransmission,
    required this.onSearchChanged,
    required this.onCategoryChanged,
    required this.onTransmissionChanged,
  });

  static const List<String> categories = ['all', 'suv', 'luxury', 'mpv', 'sedan', 'economy'];
  static const List<String> transmissions = ['all', 'Automatic', 'Manual'];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        TextField(
          onChanged: onSearchChanged,
          style: TextStyle(
            color: isDark ? AppColors.textPrimary : AppColors.lightTextPrimary,
            fontSize: 14,
          ),
          decoration: InputDecoration(
            hintText: 'Search by model (e.g. BMW, Creta, Fortuner)...',
            hintStyle: TextStyle(
              color: isDark ? AppColors.textMuted : AppColors.lightTextMuted,
              fontSize: 13,
            ),
            prefixIcon: Icon(
              Icons.search,
              color: isDark ? AppColors.textSecondary : AppColors.lightTextSecondary,
              size: 20,
            ),
            filled: true,
            fillColor: isDark ? AppColors.surfaceElevated : AppColors.lightSurfaceElevated,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: isDark ? AppColors.border : AppColors.lightBorder,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: isDark ? AppColors.border : AppColors.lightBorder,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 34,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              ...categories.map((cat) {
                final isSelected = selectedCategory.toLowerCase() == cat.toLowerCase();
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(
                      cat == 'all' ? 'All Types' : cat.toUpperCase(),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected
                            ? Colors.white
                            : (isDark ? AppColors.textSecondary : AppColors.lightTextSecondary),
                      ),
                    ),
                    selected: isSelected,
                    selectedColor: AppColors.primary,
                    backgroundColor: isDark ? AppColors.surfaceElevated : AppColors.lightSurfaceElevated,
                    side: BorderSide(
                      color: isSelected
                          ? AppColors.primaryLight
                          : (isDark ? AppColors.border : AppColors.lightBorder),
                    ),
                    onSelected: (_) => onCategoryChanged(cat),
                  ),
                );
              }),
              Container(
                height: 24,
                width: 1,
                color: isDark ? AppColors.border : AppColors.lightBorder,
                margin: const EdgeInsets.symmetric(horizontal: 4),
              ),
              ...transmissions.map((tr) {
                final isSelected = selectedTransmission.toLowerCase() == tr.toLowerCase();
                return Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: ChoiceChip(
                    label: Text(
                      tr == 'all' ? 'All Trans.' : tr,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected
                            ? Colors.white
                            : (isDark ? AppColors.textSecondary : AppColors.lightTextSecondary),
                      ),
                    ),
                    selected: isSelected,
                    selectedColor: isDark ? AppColors.surfaceGlass : AppColors.primary.withValues(alpha: 0.15),
                    backgroundColor: isDark ? AppColors.surfaceElevated : AppColors.lightSurfaceElevated,
                    side: BorderSide(
                      color: isSelected
                          ? AppColors.primary
                          : (isDark ? AppColors.border : AppColors.lightBorder),
                    ),
                    onSelected: (_) => onTransmissionChanged(tr),
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }
}
