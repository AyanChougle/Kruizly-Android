import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class StatusBadge extends StatelessWidget {
  final String status;

  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    String label = status.toUpperCase().replaceAll('_', ' ');

    switch (status.toLowerCase()) {
      case 'confirmed':
      case 'approved':
      case 'verified':
      case 'paid':
        bg = AppColors.success.withValues(alpha: 0.15);
        fg = AppColors.success;
        break;
      case 'pending':
      case 'pending_payment':
      case 'under_review':
        bg = AppColors.warning.withValues(alpha: 0.15);
        fg = AppColors.warning;
        break;
      case 'active':
        bg = AppColors.info.withValues(alpha: 0.15);
        fg = AppColors.info;
        break;
      case 'completed':
        bg = Colors.purple.withValues(alpha: 0.15);
        fg = Colors.purpleAccent;
        break;
      case 'cancelled':
      case 'rejected':
      case 'failed':
        bg = AppColors.error.withValues(alpha: 0.15);
        fg = AppColors.error;
        break;
      default:
        bg = AppColors.surfaceElevated;
        fg = AppColors.textSecondary;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: fg.withValues(alpha: 0.4), width: 1),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: fg,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
