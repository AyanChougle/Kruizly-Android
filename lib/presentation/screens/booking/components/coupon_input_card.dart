import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/coupon_model.dart';
import '../../../widgets/glass_card.dart';

class CouponInputCard extends StatefulWidget {
  final CouponModel? appliedCoupon;
  final bool isValidating;
  final String? error;
  final Function(String code) onApply;
  final VoidCallback onRemove;

  const CouponInputCard({
    super.key,
    required this.appliedCoupon,
    required this.isValidating,
    required this.error,
    required this.onApply,
    required this.onRemove,
  });

  @override
  State<CouponInputCard> createState() => _CouponInputCardState();
}

class _CouponInputCardState extends State<CouponInputCard> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.appliedCoupon != null) {
      final c = widget.appliedCoupon!;
      return GlassCard(
        padding: const EdgeInsets.all(14),
        borderColor: AppColors.success.withValues(alpha: 0.5),
        child: Row(
          children: [
            const Icon(Icons.check_circle, color: AppColors.success, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Coupon "${c.code}" Applied!',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.success,
                    ),
                  ),
                  Text(
                    c.type.toLowerCase() == 'percent'
                        ? '${c.value.toInt()}% off on rental base'
                        : '₹${c.value.toInt()} flat discount on rental base',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, color: AppColors.error, size: 20),
              onPressed: widget.onRemove,
            ),
          ],
        ),
      );
    }

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Promotional Coupon',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: context.themeTextPrimary,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  textCapitalization: TextCapitalization.characters,
                  style: TextStyle(
                    color: context.themeTextPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Apply coupon code',
                    hintStyle: TextStyle(
                      color: context.themeTextMuted,
                      fontSize: 13,
                    ),
                    filled: true,
                    fillColor: context.themeSurfaceElevated,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: context.themeBorder),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: context.themeBorder),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: widget.isValidating
                    ? null
                    : () {
                        if (_controller.text.trim().isNotEmpty) {
                          widget.onApply(_controller.text.trim());
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
                child: widget.isValidating
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Apply',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(
                Icons.local_offer_outlined,
                size: 14,
                color: AppColors.primaryLight,
              ),
              const SizedBox(width: 6),
              Text(
                'Available: ',
                style: TextStyle(
                  fontSize: 11,
                  color: context.themeTextSecondary,
                ),
              ),
              InkWell(
                onTap: () {
                  _controller.text = 'coupon code';
                  widget.onApply('coupon code');
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'KRUIZ10 (10% OFF)',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryLight,
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (widget.error != null) ...[
            const SizedBox(height: 8),
            Text(
              widget.error!,
              style: const TextStyle(color: AppColors.error, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }
}
