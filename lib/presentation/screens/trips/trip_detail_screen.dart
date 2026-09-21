import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
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
                      _buildInfoRow(context, 'Pickup Time', dateFormat.format(booking.pickupDate)),
                      const SizedBox(height: 10),
                      _buildInfoRow(context, 'Drop-off Time', dateFormat.format(booking.dropDate)),
                      const SizedBox(height: 10),
                      _buildInfoRow(context, 'Duration', booking.duration),

                      const SizedBox(height: 10),
                      _buildInfoRow(context, 'Payment Plan', booking.paymentPlan.toUpperCase()),
                    ],
                  ),
                ),
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
