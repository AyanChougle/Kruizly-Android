import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../widgets/glass_card.dart';

class QuickSearchCard extends StatefulWidget {
  final Function(DateTime pickup, DateTime drop, String hub) onSearch;

  const QuickSearchCard({super.key, required this.onSearch});

  @override
  State<QuickSearchCard> createState() => _QuickSearchCardState();
}

class _QuickSearchCardState extends State<QuickSearchCard> {
  late DateTime _pickupDate;
  late DateTime _dropDate;
  String _selectedHub = 'all'; // 'all', 'ghansoli', 'kandivali'
  int _driveMode = 0; // 0: Self-Drive, 1: Doorstep Delivery

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _pickupDate = DateTime(now.year, now.month, now.day, now.hour + 2, 0);
    _dropDate = _pickupDate.add(const Duration(hours: 24));
  }

  String get _durationText {
    final diff = _dropDate.difference(_pickupDate);
    final hours = diff.inHours;
    if (hours < 24) return '24 Hours (Min. Rule)';
    final days = (hours / 24).floor();
    final remHours = hours % 24;
    if (remHours == 0) {
      return '$days Day${days > 1 ? 's' : ''} ($hours hrs)';
    }
    return '$days Day${days > 1 ? 's' : ''} $remHours hr${remHours > 1 ? 's' : ''}';
  }

  Future<void> _pickDateTime(bool isPickup) async {
    final initialDate = isPickup ? _pickupDate : _dropDate;
    final firstDate = isPickup
        ? DateTime.now()
        : _pickupDate.add(const Duration(hours: 24));
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate.isBefore(firstDate) ? firstDate : initialDate,
      firstDate: firstDate,
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
        if (_dropDate.isBefore(_pickupDate.add(const Duration(hours: 24)))) {
          _dropDate = _pickupDate.add(const Duration(hours: 24));
        }
      } else {
        DateTime effectiveDrop = combined;
        final minDrop = _pickupDate.add(const Duration(hours: 24));
        if (effectiveDrop.isBefore(minDrop)) {
          effectiveDrop = minDrop;
        }
        _dropDate = effectiveDrop;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GlassCard(
      padding: const EdgeInsets.all(16),
      borderRadius: 22,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drive mode selector
          Row(
            children: [
              Expanded(
                child: _buildDriveModeTab(
                  index: 0,
                  label: 'Self-Drive',
                  subtitle: 'Total Freedom',
                  icon: Icons.directions_car_filled_rounded,
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildDriveModeTab(
                  index: 1,
                  label: 'Doorstep Drop',
                  subtitle: 'Airport & Home',
                  icon: Icons.hail_rounded,
                  isDark: isDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Date & Time Selectors Row
          Row(
            children: [
              Expanded(
                child: _buildDateTile(
                  title: 'PICKUP',
                  date: _pickupDate,
                  icon: Icons.calendar_today_rounded,
                  isDark: isDark,
                  onTap: () => _pickDateTime(true),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_forward_rounded,
                    size: 14,
                    color: AppColors.primaryLight,
                  ),
                ),
              ),
              Expanded(
                child: _buildDateTile(
                  title: 'RETURN',
                  date: _dropDate,
                  icon: Icons.event_available_rounded,
                  isDark: isDark,
                  onTap: () => _pickDateTime(false),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Duration summary pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF0F172A)
                  : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFCBD5E1),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.timelapse_rounded,
                  size: 14,
                  color: AppColors.primaryLight,
                ),
                const SizedBox(width: 6),
                Text(
                  'Trip Duration: $_durationText',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white70 : const Color(0xFF334155),
                  ),
                ),
                const Spacer(),
                const Text(
                  'Min. 24h Enforced',
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF06D6A0),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Hub selector dropdown
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceElevated : AppColors.lightSurfaceElevated,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark ? AppColors.border : AppColors.lightBorder,
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.storefront_rounded,
                  color: AppColors.primaryLight,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedHub,
                      isExpanded: true,
                      dropdownColor: isDark ? const Color(0xFF0F172A) : Colors.white,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: isDark ? AppColors.textPrimary : AppColors.lightTextPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                      icon: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: isDark ? AppColors.textSecondary : AppColors.lightTextSecondary,
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'all',
                          child: Text('All Hubs (Mumbai, Navi Mumbai, Pune)'),
                        ),
                        DropdownMenuItem(
                          value: 'ghansoli',
                          child: Text('Ghansoli Hub (Gavson Park, Navi Mumbai)'),
                        ),
                        DropdownMenuItem(
                          value: 'kandivali',
                          child: Text('Kandivali Hub (Mumbai West)'),
                        ),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _selectedHub = val);
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Find Cars Button
          GestureDetector(
            onTap: () => widget.onSearch(_pickupDate, _dropDate, _selectedHub),
            child: Container(
              height: 48,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0066FF), Color(0xFF0052CC), Color(0xFF003D99)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0066FF).withValues(alpha: 0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search_rounded, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Search Available Cars (Lock for ₹500)',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDriveModeTab({
    required int index,
    required String label,
    required String subtitle,
    required IconData icon,
    required bool isDark,
  }) {
    final isSelected = _driveMode == index;
    return GestureDetector(
      onTap: () => setState(() => _driveMode = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: isDark ? 0.25 : 0.15)
              : (isDark ? AppColors.surfaceElevated : AppColors.lightSurfaceElevated),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : (isDark ? AppColors.border : AppColors.lightBorder),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected
                  ? AppColors.primaryLight
                  : (isDark ? Colors.white60 : Colors.black54),
            ),
            const SizedBox(width: 7),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: isSelected
                          ? (isDark ? Colors.white : AppColors.primary)
                          : (isDark ? Colors.white70 : Colors.black87),
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 9.5,
                      color: isDark ? Colors.white54 : Colors.black45,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateTile({
    required String title,
    required DateTime date,
    required IconData icon,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    final dayFormat = DateFormat('EEE, dd MMM');
    final timeFormat = DateFormat('hh:mm a');

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceElevated : AppColors.lightSurfaceElevated,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark ? AppColors.border : AppColors.lightBorder,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 12, color: AppColors.primaryLight),
                const SizedBox(width: 4),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w900,
                    color: AppColors.primaryLight,
                    letterSpacing: 0.6,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),
            Text(
              dayFormat.format(date),
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
                color: isDark ? AppColors.textPrimary : AppColors.lightTextPrimary,
              ),
            ),
            Text(
              timeFormat.format(date),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white60 : Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
