import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class FleetFilterBar extends StatefulWidget {
  final String searchQuery;
  final String selectedCategory;
  final String selectedTransmission;
  final String selectedHub;
  final String sortBy;
  final Function(String query) onSearchChanged;
  final Function(String category) onCategoryChanged;
  final Function(String transmission) onTransmissionChanged;
  final Function(String hub) onHubChanged;
  final Function(String sort) onSortChanged;

  const FleetFilterBar({
    super.key,
    required this.searchQuery,
    required this.selectedCategory,
    required this.selectedTransmission,
    this.selectedHub = 'all',
    required this.sortBy,
    required this.onSearchChanged,
    required this.onCategoryChanged,
    required this.onTransmissionChanged,
    required this.onHubChanged,
    required this.onSortChanged,
  });

  static const List<String> categories = ['all', 'suv', 'luxury', 'mpv', 'sedan', 'economy'];
  static const List<String> transmissions = ['all', 'Automatic', 'Manual'];
  static const List<({String key, String label})> hubs = [
    (key: 'all', label: 'All Hubs'),
    (key: 'ghansoli', label: 'Ghansoli Hub (Navi Mumbai)'),
    (key: 'kandivali', label: 'Kandivali Hub (Mumbai)'),
  ];
  static const List<({String key, String label, IconData icon})> sortOptions = [
    (key: 'recommended', label: 'Recommended', icon: Icons.auto_awesome_rounded),
    (key: 'price_asc', label: 'Price: Low → High', icon: Icons.arrow_upward_rounded),
    (key: 'price_desc', label: 'Price: High → Low', icon: Icons.arrow_downward_rounded),
    (key: 'name', label: 'Name: A → Z', icon: Icons.sort_by_alpha_rounded),
  ];

  @override
  State<FleetFilterBar> createState() => FleetFilterBarState();
}

class FleetFilterBarState extends State<FleetFilterBar> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _expandAnimation;
  bool _filtersExpanded = false;

  bool get isExpanded => _filtersExpanded;

  void closeFilters() {
    if (_filtersExpanded) {
      setState(() => _filtersExpanded = false);
      _controller.reverse();
    }
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
      value: 0.0,
    );
    _expandAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleFilters() {
    setState(() => _filtersExpanded = !_filtersExpanded);
    if (_filtersExpanded) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        // Search + Filter Toggle Row
        Row(
          children: [
            Expanded(
              child: TextField(
                onChanged: widget.onSearchChanged,
                style: TextStyle(
                  color: isDark ? AppColors.textPrimary : AppColors.lightTextPrimary,
                  fontSize: 14,
                ),
                decoration: InputDecoration(
                  hintText: 'Search fleet...',
                  hintStyle: TextStyle(
                    color: isDark ? AppColors.textMuted : AppColors.lightTextMuted,
                    fontSize: 13,
                  ),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: isDark ? AppColors.textSecondary : AppColors.lightTextSecondary,
                    size: 20,
                  ),
                  filled: true,
                  fillColor: isDark ? AppColors.surfaceElevated : AppColors.lightSurfaceElevated,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: isDark ? AppColors.border : AppColors.lightBorder),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: isDark ? AppColors.border : AppColors.lightBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppColors.primary),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            // Filter toggle button
            GestureDetector(
              onTap: _toggleFilters,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(
                  color: _filtersExpanded
                      ? AppColors.primary.withValues(alpha: 0.18)
                      : (isDark ? AppColors.surfaceElevated : AppColors.lightSurfaceElevated),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: _filtersExpanded
                        ? AppColors.primary
                        : (isDark ? AppColors.border : AppColors.lightBorder),
                  ),
                ),
                child: AnimatedRotation(
                  turns: _filtersExpanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 280),
                  child: Icon(
                    Icons.tune_rounded,
                    size: 20,
                    color: _filtersExpanded
                        ? AppColors.primary
                        : (isDark ? AppColors.textSecondary : AppColors.lightTextSecondary),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // PERMANENTLY VISIBLE HUB SELECTOR PILLS
        SizedBox(
          height: 36,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: FleetFilterBar.hubs.map((hub) {
              final isActive = widget.selectedHub.toLowerCase() == hub.key.toLowerCase();
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _AnimatedPill(
                  label: hub.label,
                  icon: Icons.location_on_rounded,
                  isSelected: isActive,
                  isDark: isDark,
                  onTap: () => widget.onHubChanged(hub.key),
                ),
              );
            }).toList(),
          ),
        ),

        // Animated expandable filters section
        SizeTransition(
          sizeFactor: _expandAnimation,
          alignment: Alignment.topCenter,
          child: FadeTransition(
            opacity: _expandAnimation,
            child: Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Sort Row
                  _SectionLabel(label: 'SORT BY', isDark: isDark),
                  const SizedBox(height: 6),
                  SizedBox(
                    height: 36,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: FleetFilterBar.sortOptions.map((opt) {
                        final isActive = widget.sortBy == opt.key;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: _AnimatedPill(
                            label: opt.label,
                            icon: opt.icon,
                            isSelected: isActive,
                            isDark: isDark,
                            onTap: () {
                              widget.onSortChanged(opt.key);
                              if (_filtersExpanded) _toggleFilters();
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Category Row
                  _SectionLabel(label: 'CATEGORY', isDark: isDark),
                  const SizedBox(height: 6),
                  SizedBox(
                    height: 36,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: FleetFilterBar.categories.map((cat) {
                        final isActive = widget.selectedCategory.toLowerCase() == cat.toLowerCase();
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: _AnimatedPill(
                            label: cat == 'all' ? 'All Types' : cat.toUpperCase(),
                            isSelected: isActive,
                            isDark: isDark,
                            onTap: () {
                              widget.onCategoryChanged(cat);
                              if (_filtersExpanded) _toggleFilters();
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Transmission Row
                  _SectionLabel(label: 'TRANSMISSION', isDark: isDark),
                  const SizedBox(height: 6),
                  SizedBox(
                    height: 36,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: FleetFilterBar.transmissions.map((tr) {
                        final isActive = widget.selectedTransmission.toLowerCase() == tr.toLowerCase();
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: _AnimatedPill(
                            label: tr == 'all' ? 'All Trans.' : tr,
                            isSelected: isActive,
                            isDark: isDark,
                            onTap: () {
                              widget.onTransmissionChanged(tr);
                              if (_filtersExpanded) _toggleFilters();
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Hub Location Row
                  _SectionLabel(label: 'OPERATIONAL HUB', isDark: isDark),
                  const SizedBox(height: 6),
                  SizedBox(
                    height: 36,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: FleetFilterBar.hubs.map((hub) {
                        final isActive = widget.selectedHub.toLowerCase() == hub.key.toLowerCase();
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: _AnimatedPill(
                            label: hub.label,
                            icon: Icons.location_on_rounded,
                            isSelected: isActive,
                            isDark: isDark,
                            onTap: () {
                              widget.onHubChanged(hub.key);
                              if (_filtersExpanded) _toggleFilters();
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Animated filter/sort pill with scale + color transitions
class _AnimatedPill extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  const _AnimatedPill({
    required this.label,
    this.icon,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedScale(
        scale: isSelected ? 1.05 : 1.0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutBack,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary
                : (isDark ? AppColors.surfaceElevated : AppColors.lightSurfaceElevated),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected
                  ? AppColors.primary
                  : (isDark ? AppColors.border : AppColors.lightBorder),
              width: isSelected ? 1.5 : 1.0,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 14,
                  color: isSelected
                      ? Colors.white
                      : (isDark ? AppColors.textSecondary : AppColors.lightTextSecondary),
                ),
                const SizedBox(width: 5),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected
                      ? Colors.white
                      : (isDark ? AppColors.textSecondary : AppColors.lightTextSecondary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  final bool isDark;

  const _SectionLabel({required this.label, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.0,
        color: isDark ? AppColors.textMuted : AppColors.lightTextMuted,
      ),
    );
  }
}
