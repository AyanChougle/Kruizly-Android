import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/booking_model.dart';
import '../../../widgets/glass_card.dart';
import '../../../widgets/status_badge.dart';

class TripCard extends StatelessWidget {
  final BookingModel booking;
  final VoidCallback onTap;
  final VoidCallback? onPayNow;
  final VoidCallback? onInvoice;

  const TripCard({
    super.key,
    required this.booking,
    required this.onTap,
    this.onPayNow,
    this.onInvoice,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMM yyyy, hh:mm a');
    final isPendingPayment = booking.status.toLowerCase() == 'pending_payment' ||
        booking.paymentStatus.toLowerCase() == 'pending_payment';

    return GlassCard(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '#${booking.bookingId}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryLight,
                ),
              ),
              StatusBadge(status: booking.status),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            booking.vehicleName,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: context.themeTextPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '${booking.vehicleCategory.toUpperCase()} • Reg: ${booking.vehicleReg}',
            style: TextStyle(fontSize: 12, color: context.themeTextSecondary),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Divider(color: context.themeBorder, height: 1),
          ),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('PICKUP', style: TextStyle(fontSize: 10, color: context.themeTextMuted, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text(
                      dateFormat.format(booking.pickupDate),
                      style: TextStyle(fontSize: 12, color: context.themeTextPrimary, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward, size: 16, color: context.themeTextMuted),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('DROP-OFF', style: TextStyle(fontSize: 10, color: context.themeTextMuted, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text(
                      dateFormat.format(booking.dropDate),
                      style: TextStyle(fontSize: 12, color: context.themeTextPrimary, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total: ₹${booking.totalAmount.toInt()} (Paid: ₹${booking.advanceAmount.toInt()})',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: context.themeTextPrimary),
              ),
              if (isPendingPayment && onPayNow != null)
                TextButton(
                  onPressed: onPayNow,
                  style: TextButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Pay Now', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                )
              else if (onInvoice != null)
                TextButton.icon(
                  onPressed: onInvoice,
                  icon: const Icon(Icons.receipt_long, size: 14, color: AppColors.primaryLight),
                  label: const Text('Invoice', style: TextStyle(color: AppColors.primaryLight, fontSize: 12)),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
