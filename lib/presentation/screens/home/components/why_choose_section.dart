import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../widgets/glass_card.dart';

class WhyChooseSection extends StatelessWidget {
  const WhyChooseSection({super.key});

  static const List<Map<String, dynamic>> features = [
    {
      'icon': Icons.verified_user_outlined,
      'title': '100% Verified Fleet',
      'desc':
          'Clean, sanitized, and showroom condition cars before every delivery.',
    },
    {
      'icon': Icons.currency_rupee,
      'title': 'Zero Hidden Charges',
      'desc':
          'Transparent pricing with security deposit refunded within 24 hours.',
    },
    {
      'icon': Icons.door_front_door_outlined,
      'title': 'Doorstep Delivery',
      'desc':
          'Delivered right to your airport terminal, office, or home doorstep.',
    },
    {
      'icon': Icons.support_agent_outlined,
      'title': '24/7 Roadside Assist',
      'desc':
          'Dedicated concierge support team ready round the clock across Maharashtra.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Why Kruizly?',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: isDark ? AppColors.textPrimary : AppColors.lightTextPrimary,
          ),
        ),
        const SizedBox(height: 14),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.98,
          ),
          itemCount: features.length,
          itemBuilder: (context, index) {
            final f = features[index];
            return GlassCard(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Icon(
                      f['icon'] as IconData,
                      color: isDark
                          ? AppColors.primaryLight
                          : AppColors.primary,
                      size: 22,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    f['title'] as String,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? AppColors.textPrimary
                          : AppColors.lightTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    f['desc'] as String,
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark
                          ? AppColors.textSecondary
                          : AppColors.lightTextSecondary,
                      height: 1.3,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}
