import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../widgets/custom_button.dart';
import '../../../widgets/glass_card.dart';

class QuickSearchCard extends StatefulWidget {
  final Function(DateTime pickup, DateTime drop) onSearch;

  const QuickSearchCard({super.key, required this.onSearch});

  @override
  State<QuickSearchCard> createState() => _QuickSearchCardState();
}

class _QuickSearchCardState extends State<QuickSearchCard> {
  late DateTime _pickupDate;
  late DateTime _dropDate;

  @override
  void initState() {
    super.initState();
    _pickupDate = DateTime.now().add(const Duration(hours: 2));
    _dropDate = DateTime.now().add(const Duration(hours: 26));
  }

  Future<void> _pickDateTime(bool isPickup) async {
    final initialDate = isPickup ? _pickupDate : _dropDate;
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.primary,
              surface: AppColors.surface,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate == null || !mounted) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initialDate),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.primary,
              surface: AppColors.surface,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedTime == null || !mounted) return;

    final combined = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );

    setState(() {
      if (isPickup) {
        _pickupDate = combined;
        if (_dropDate.isBefore(_pickupDate.add(const Duration(hours: 4)))) {
          _dropDate = _pickupDate.add(const Duration(hours: 24));
        }
      } else {
        if (combined.isAfter(_pickupDate)) {
          _dropDate = combined;
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('EEE, dd MMM • hh:mm a');
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GlassCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Reservation',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.textPrimary : AppColors.lightTextPrimary,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _buildDateTile(
                  title: 'PICKUP',
                  formattedDate: dateFormat.format(_pickupDate),
                  icon: Icons.calendar_today_outlined,
                  isDark: isDark,
                  onTap: () => _pickDateTime(true),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDateTile(
                  title: 'DROP-OFF',
                  formattedDate: dateFormat.format(_dropDate),
                  icon: Icons.event_available_outlined,
                  isDark: isDark,
                  onTap: () => _pickDateTime(false),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceElevated : AppColors.lightSurfaceElevated,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isDark ? AppColors.border : AppColors.lightBorder),
            ),
            child: Row(
              children: [
                const Icon(Icons.location_on_outlined, color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Hub: Gavson Business Park, Ghansoli, Navi Mumbai',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? AppColors.textSecondary : AppColors.lightTextSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          CustomButton(
            text: 'Find Available Fleet',
            icon: Icons.search_rounded,
            height: 48,
            onPressed: () => widget.onSearch(_pickupDate, _dropDate),
          ),
        ],
      ),
    );
  }

  Widget _buildDateTile({
    required String title,
    required String formattedDate,
    required IconData icon,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceElevated : AppColors.lightSurfaceElevated,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isDark ? AppColors.border : AppColors.lightBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 14, color: AppColors.primary),
                const SizedBox(width: 4),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              formattedDate,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.textPrimary : AppColors.lightTextPrimary,
              ),
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }
}
