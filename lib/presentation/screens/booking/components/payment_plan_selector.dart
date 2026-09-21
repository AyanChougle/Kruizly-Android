import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../widgets/glass_card.dart';

class PaymentPlanSelector extends StatelessWidget {
  final String selectedPlan; // "advance" or "full"
  final double advanceAmount;
  final double totalAmount;
  final Function(String plan) onPlanChanged;

  const PaymentPlanSelector({
    super.key,
    required this.selectedPlan,
    required this.advanceAmount,
    required this.totalAmount,
    required this.onPlanChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Payment Preference',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: context.themeTextPrimary,
            ),
          ),
          const SizedBox(height: 12),
          RadioGroup<String>(
            groupValue: selectedPlan,
            onChanged: (value) {
              if (value != null) onPlanChanged(value);
            },
            child: Column(
              children: [
                _buildOption(
                  context: context,
                  plan: 'advance',
                  title: 'Pay Advance Token (₹${advanceAmount.toInt()})',
                  subtitle:
                      'Pay token now to reserve this vehicle. Pay balance on car delivery.',
                  badge: 'POPULAR',
                ),
                const SizedBox(height: 10),
                _buildOption(
                  context: context,
                  plan: 'full',
                  title: 'Pay Full Amount (₹${totalAmount.toInt()})',
                  subtitle:
                      'Complete entire trip payment now for express contact-free pickup.',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOption({
    required BuildContext context,
    required String plan,
    required String title,
    required String subtitle,
    String? badge,
  }) {
    final isSelected = selectedPlan == plan;

    return InkWell(
      onTap: () => onPlanChanged(plan),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.12)
              : context.themeSurfaceElevated,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : context.themeBorder,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 20,
              height: 20,
              margin: const EdgeInsets.only(top: 2, right: 12),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? AppColors.primary : context.themeBorderLight,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                    )
                  : null,
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: isSelected
                              ? AppColors.primaryLight
                              : context.themeTextPrimary,
                        ),
                      ),
                      if (badge != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            badge,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: context.themeTextSecondary,
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
}
