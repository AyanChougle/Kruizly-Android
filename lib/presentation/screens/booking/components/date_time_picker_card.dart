import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../widgets/glass_card.dart';

class DateTimePickerCard extends StatelessWidget {
  final DateTime pickupDate;
  final DateTime dropDate;
  final String formattedDuration;
  final Function(DateTime pickup, DateTime drop) onDatesChanged;

  const DateTimePickerCard({
    super.key,
    required this.pickupDate,
    required this.dropDate,
    required this.formattedDuration,
    required this.onDatesChanged,
  });

  Future<void> _selectDateTime(BuildContext context, bool isPickup) async {
    final current = isPickup ? pickupDate : dropDate;
    final firstDate = isPickup
        ? DateTime.now()
        : pickupDate.add(const Duration(hours: 2));

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: current.isBefore(firstDate) ? firstDate : current,
      firstDate: firstDate,
      lastDate: DateTime.now().add(const Duration(days: 90)),
      builder: (context, child) {
        return Theme(
          data: isDark
              ? ThemeData.dark().copyWith(
                  colorScheme: const ColorScheme.dark(
                    primary: AppColors.primary,
                    surface: AppColors.surface,
                  ),
                )
              : ThemeData.light().copyWith(
                  colorScheme: const ColorScheme.light(
                    primary: AppColors.primary,
                    surface: AppColors.lightSurface,
                  ),
                ),
          child: child!,
        );
      },
    );

    if (pickedDate == null) return;
    if (!context.mounted) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(current),
      builder: (context, child) {
        return Theme(
          data: isDark
              ? ThemeData.dark().copyWith(
                  colorScheme: const ColorScheme.dark(
                    primary: AppColors.primary,
                    surface: AppColors.surface,
                  ),
                )
              : ThemeData.light().copyWith(
                  colorScheme: const ColorScheme.light(
                    primary: AppColors.primary,
                    surface: AppColors.lightSurface,
                  ),
                ),
          child: child!,
        );
      },
    );

    if (pickedTime == null) return;

    final combined = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );

    if (isPickup) {
      DateTime newDrop = dropDate;
      if (dropDate.isBefore(combined.add(const Duration(hours: 4)))) {
        newDrop = combined.add(const Duration(hours: 24));
      }
      onDatesChanged(combined, newDrop);
    } else {
      if (combined.isAfter(pickupDate)) {
        onDatesChanged(pickupDate, combined);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('EEE, dd MMM yyyy • hh:mm a');

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Trip Schedule',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: context.themeTextPrimary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  formattedDuration,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryLight,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildSelector(
            context: context,
            label: 'PICKUP DATE & TIME',
            value: fmt.format(pickupDate),
            icon: Icons.calendar_today_outlined,
            onTap: () => _selectDateTime(context, true),
          ),
          const SizedBox(height: 10),
          _buildSelector(
            context: context,
            label: 'DROP-OFF DATE & TIME',
            value: fmt.format(dropDate),
            icon: Icons.event_available_outlined,
            onTap: () => _selectDateTime(context, false),
          ),
        ],
      ),
    );
  }

  Widget _buildSelector({
    required BuildContext context,
    required String label,
    required String value,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: context.themeSurfaceElevated,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: context.themeBorder),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppColors.primaryLight),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: context.themeTextSecondary,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: context.themeTextPrimary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.edit_calendar_outlined,
              size: 18,
              color: context.themeTextMuted,
            ),
          ],
        ),
      ),
    );
  }
}
