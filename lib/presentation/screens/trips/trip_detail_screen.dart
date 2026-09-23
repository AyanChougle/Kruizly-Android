import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/booking_notification_helper.dart';
import '../../state/trips_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/status_badge.dart';
import 'components/cancel_booking_dialog.dart';

class TripDetailScreen extends ConsumerWidget {
  final String bookingId;

  const TripDetailScreen({super.key, required this.bookingId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(bookingDetailProvider(bookingId));
    final dateFormat = DateFormat('EEE, dd MMM yyyy • hh:mm a');

    return Scaffold(
      backgroundColor: context.themeBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: context.themeTextPrimary, size: 20),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Booking #$bookingId',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: context.themeTextPrimary),
        ),
      ),
      body: detailAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (err, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const SizedBox(height: 12),
              Text('Error loading booking: $err', style: TextStyle(color: context.themeTextSecondary)),
            ],
          ),
        ),
        data: (booking) {
          if (booking == null) {
            return Center(child: Text('Booking not found.', style: TextStyle(color: context.themeTextSecondary)));
          }

          final isPendingPayment = booking.status.toLowerCase() == 'pending_payment' ||
              booking.paymentStatus.toLowerCase() == 'pending_payment';
          final canCancel = booking.status.toLowerCase() != 'cancelled' &&
              booking.status.toLowerCase() != 'completed';

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                GlassCard(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '#${booking.bookingId}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryLight,
                            ),
                          ),
                          StatusBadge(status: booking.status),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        booking.vehicleName,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: context.themeTextPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Category: ${booking.vehicleCategory.toUpperCase()} • Reg: ${booking.vehicleReg}',
                        style: TextStyle(fontSize: 13, color: context.themeTextSecondary),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        child: Divider(color: context.themeBorder, height: 1),
                      ),
                      Text(
                        'RENTAL SCHEDULE',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.0,
                          color: context.themeTextMuted,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: context.themeSurfaceElevated,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: context.themeBorder),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF06D6A0).withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(Icons.arrow_upward_rounded, color: Color(0xFF06D6A0), size: 16),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'PICKUP TIME & DATE',
                                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: context.themeTextMuted),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        dateFormat.format(booking.pickupDate),
                                        style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: context.themeTextPrimary),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              child: Row(
                                children: [
                                  const SizedBox(width: 15),
                                  Container(width: 2, height: 20, color: context.themeBorder),
                                  const SizedBox(width: 20),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.timelapse_rounded, size: 13, color: AppColors.primaryLight),
                                        const SizedBox(width: 5),
                                        Text(
                                          BookingNotificationHelper.formatDurationDetailed(
                                            booking.pickupDate,
                                            booking.dropDate,
                                            days: booking.days,
                                            hours: booking.hours,
                                          ),
                                          style: const TextStyle(
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.w800,
                                            color: AppColors.primaryLight,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFF5C77).withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(Icons.arrow_downward_rounded, color: Color(0xFFFF5C77), size: 16),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'DROP-OFF TIME & DATE',
                                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: context.themeTextMuted),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        dateFormat.format(booking.dropDate),
                                        style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: context.themeTextPrimary),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildInfoRow(context, 'Pickup Hub Location', booking.location),
                      const SizedBox(height: 8),
                      _buildInfoRow(
                        context,
                        'Total Booked Duration',
                        BookingNotificationHelper.formatDurationDetailed(
                          booking.pickupDate,
                          booking.dropDate,
                          days: booking.days,
                          hours: booking.hours,
                        ),
                        isBold: true,
                      ),
                      const SizedBox(height: 8),
                      _buildInfoRow(context, 'Payment Plan', booking.paymentPlan.toUpperCase()),
                    ],
                  ),
                ),
                if (booking.isConfirmed) ...[
                  const SizedBox(height: 14),
                  GlassCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.check_circle_rounded, color: Color(0xFF06D6A0), size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Booking Approved & Confirmed',
                              style: TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w800,
                                color: context.themeTextPrimary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Your reservation has been confirmed by our operations team. You can get a copy of your confirmation via WhatsApp or Email below.',
                          style: TextStyle(fontSize: 12, color: context.themeTextSecondary, height: 1.3),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                icon: const Icon(Icons.chat_rounded, size: 16, color: Color(0xFF25D366)),
                                label: const Text('WhatsApp Confirmation', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF25D366))),
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: Color(0xFF25D366), width: 1.2),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                ),
                                onPressed: () async {
                                  final ok = await BookingNotificationHelper.sendWhatsAppConfirmation(booking);
                                  if (!ok && context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Could not launch WhatsApp.')),
                                    );
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton.icon(
                                icon: const Icon(Icons.mail_outline_rounded, size: 16, color: AppColors.primary),
                                label: const Text('Email Notice', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary)),
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: AppColors.primary, width: 1.2),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                ),
                                onPressed: () async {
                                  final ok = await BookingNotificationHelper.sendEmailConfirmation(booking);
                                  if (!ok && context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Could not open mail client.')),
                                    );
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                GlassCard(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Financial Breakdown',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: context.themeTextPrimary,
                        ),
                      ),
                      const SizedBox(height: 14),
                      _buildInfoRow(context, 'Rental Base Amount', '₹${booking.baseAmount.toInt()}'),
                      if (booking.securityDeposit > 0) ...[
                        const SizedBox(height: 10),
                        _buildInfoRow(context, 'Security Deposit (Refundable)', '₹${booking.securityDeposit.toInt()}'),
                      ],
                      if (booking.couponDiscount > 0) ...[
                        const SizedBox(height: 10),
                        _buildInfoRow(context, 'Coupon Discount', '-₹${booking.couponDiscount.toInt()}', isDiscount: true),
                      ],
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Divider(color: context.themeBorder, height: 1),
                      ),
                      _buildInfoRow(context, 'Total Trip Amount', '₹${booking.totalAmount.toInt()}', isBold: true),
                      const SizedBox(height: 10),
                      _buildInfoRow(context, 'Amount Paid', '₹${booking.advanceAmount.toInt()}', isPaid: true),
                      if (booking.remainingBalance > 0) ...[
                        const SizedBox(height: 10),
                        _buildInfoRow(context, 'Remaining Balance on Delivery', '₹${booking.remainingBalance.toInt()}'),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                if (isPendingPayment) ...[
                  CustomButton(
                    text: 'Complete Payment Now',
                    icon: Icons.payment,
                    onPressed: () => context.push('/checkout/${booking.bookingId}'),
                  ),
                  const SizedBox(height: 12),
                ],
                CustomButton(
                  text: 'View Tax Invoice',
                  icon: Icons.receipt_long,
                  isOutlined: true,
                  onPressed: () => context.push('/invoice/${booking.bookingId}'),
                ),
                if (canCancel) ...[
                  const SizedBox(height: 12),
                  CustomButton(
                    text: 'Cancel Booking',
                    isOutlined: true,
                    backgroundColor: AppColors.error,
                    textColor: AppColors.error,
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (_) => CancelBookingDialog(
                          bookingId: booking.bookingId,
                          onConfirm: (reason) async {
                            final success = await ref
                                .read(tripsProvider.notifier)
                                .cancelBooking(booking.bookingId, reason);
                            if (success && context.mounted) {
                              context.pop();
                            }
                          },
                        ),
                      );
                    },
                  ),
                ],
                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value, {bool isBold = false, bool isDiscount = false, bool isPaid = false}) {
    Color col = context.themeTextPrimary;
    if (isDiscount || isPaid) col = AppColors.success;
    if (!isBold && !isDiscount && !isPaid) col = context.themeTextSecondary;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isBold ? 14 : 13,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w400,
            color: isBold ? context.themeTextPrimary : context.themeTextSecondary,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isBold ? 15 : 13,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
            color: col,
          ),
        ),
      ],
    );
  }
}
