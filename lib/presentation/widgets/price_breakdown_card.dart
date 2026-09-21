import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../state/booking_provider.dart';
import 'glass_card.dart';

class PriceBreakdownCard extends StatelessWidget {
  final BookingPriceBreakdown breakdown;
  final String paymentPlan;
  final bool withDriver;

  const PriceBreakdownCard({
    super.key,
    required this.breakdown,
    required this.paymentPlan,
    required this.withDriver,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Price Breakdown',
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
                  breakdown.formattedDuration,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.primaryLight,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildRow(
            context,
            'Base Rental (${breakdown.durationHours} hrs)',
            '₹${breakdown.rentalTotal.toInt()}',
          ),
          if (withDriver) ...[
            const SizedBox(height: 10),
            _buildRow(context, 'Chauffeur Service', '₹${breakdown.driverTotal.toInt()}'),
          ],
          if (breakdown.securityDeposit > 0) ...[
            const SizedBox(height: 10),
            _buildRow(
              context,
              'Security Deposit (Refundable)',
              '₹${breakdown.securityDeposit.toInt()}',
              isSubtle: true,
            ),
          ],
          if (breakdown.couponDiscount > 0) ...[
            const SizedBox(height: 10),
            _buildRow(
              context,
              'Coupon Discount',
              '-₹${breakdown.couponDiscount.toInt()}',
              isDiscount: true,
            ),
          ],
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Divider(color: context.themeBorder, height: 1),
          ),
          _buildRow(
            context,
            'Total Trip Amount',
            '₹${breakdown.finalAmount.toInt()}',
            isBold: true,
            fontSize: 16,
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: context.themeSurfaceElevated,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: context.themeBorderLight),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      paymentPlan == 'advance'
                          ? 'Advance Token (Pay Now)'
                          : 'Full Payment (Pay Now)',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryLight,
                      ),
                    ),
                    Text(
                      '₹${breakdown.advanceAmount.toInt()}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: context.themeTextPrimary,
                      ),
                    ),
                  ],
                ),
                if (paymentPlan == 'advance' &&
                    breakdown.remainingBalance > 0) ...[
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Balance at Car Delivery',
                        style: TextStyle(
                          fontSize: 13,
                          color: context.themeTextSecondary,
                        ),
                      ),
                      Text(
                        '₹${breakdown.remainingBalance.toInt()}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: context.themeTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(
    BuildContext context,
    String label,
    String value, {
    bool isBold = false,
    bool isDiscount = false,
    bool isSubtle = false,
    double fontSize = 14,
  }) {
    Color valColor = context.themeTextPrimary;
    if (isDiscount) valColor = AppColors.success;
    if (isSubtle) valColor = context.themeTextSecondary;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w400,
            color: isBold ? context.themeTextPrimary : context.themeTextSecondary,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
            color: valColor,
          ),
        ),
      ],
    );
  }
}
