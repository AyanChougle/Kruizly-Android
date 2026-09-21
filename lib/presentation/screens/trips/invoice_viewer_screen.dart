import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/invoice_model.dart';
import '../../state/app_providers.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/glass_card.dart';

final invoiceProvider = FutureProvider.family<InvoiceModel?, String>((
  ref,
  bookingId,
) async {
  final repo = ref.read(invoiceRepositoryProvider);
  return repo.getInvoice(bookingId);
});

class InvoiceViewerScreen extends ConsumerWidget {
  final String bookingId;

  const InvoiceViewerScreen({super.key, required this.bookingId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final invoiceAsync = ref.watch(invoiceProvider(bookingId));

    return Scaffold(
      backgroundColor: context.themeBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new,
            color: context.themeTextPrimary,
            size: 20,
          ),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Invoice #$bookingId',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: context.themeTextPrimary,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.share_outlined,
              color: AppColors.primaryLight,
            ),
            onPressed: () {
              Share.share(
                'Check out my KRUIZLY invoice for booking #$bookingId at https://kruizly.com/invoice.html?id=$bookingId',
              );
            },
          ),
        ],
      ),
      body: invoiceAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (err, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.receipt_long_outlined,
                size: 48,
                color: context.themeTextMuted,
              ),
              const SizedBox(height: 12),
              Text(
                'Invoice is being generated.',
                style: TextStyle(color: context.themeTextPrimary, fontSize: 16),
              ),
              const SizedBox(height: 6),
              Text(
                'Please check back once payment verification completes.',
                style: TextStyle(color: context.themeTextSecondary, fontSize: 13),
              ),
              const SizedBox(height: 16),
              CustomButton(
                text: 'Go Back',
                width: 140,
                isOutlined: true,
                onPressed: () => context.pop(),
              ),
            ],
          ),
        ),
        data: (inv) {
          if (inv == null) {
            return Center(
              child: Text(
                'No invoice available.',
                style: TextStyle(color: context.themeTextSecondary),
              ),
            );
          }

          final invoiceNum = inv.invoiceNumber.isNotEmpty
              ? inv.invoiceNumber
              : 'INV-$bookingId';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                GlassCard(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'TAX INVOICE',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primaryLight,
                              letterSpacing: 1.5,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.success.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppColors.success.withValues(alpha: 0.4),
                              ),
                            ),
                            child: const Text(
                              'GENERATED',
                              style: TextStyle(
                                color: AppColors.success,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'Invoice ID: $invoiceNum',
                        style: TextStyle(
                          fontSize: 13,
                          color: context.themeTextSecondary,
                        ),
                      ),
                      Text(
                        'Booking Ref: #${inv.bookingId}',
                        style: TextStyle(
                          fontSize: 13,
                          color: context.themeTextSecondary,
                        ),
                      ),
                      Text(
                        'Vehicle: ${inv.vehicleName} (${inv.vehicleReg})',
                        style: TextStyle(
                          fontSize: 13,
                          color: context.themeTextSecondary,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Divider(color: context.themeBorder, height: 1),
                      ),
                      _buildRow(
                        context,
                        'Base Rental Charge',
                        '₹${inv.rentalCharge.toInt()}',
                      ),
                      if (inv.securityDeposit > 0) ...[
                        const SizedBox(height: 10),
                        _buildRow(
                          context,
                          'Security Deposit (Refundable)',
                          '₹${inv.securityDeposit.toInt()}',
                        ),
                      ],
                      if (inv.discount > 0) ...[
                        const SizedBox(height: 10),
                        _buildRow(
                          context,
                          'Coupon Discount',
                          '-₹${inv.discount.toInt()}',
                          isHighlight: true,
                        ),
                      ],
                      const SizedBox(height: 10),
                      _buildRow(
                        context,
                        'Total Amount',
                        '₹${inv.totalAmount.toInt()}',
                        isBold: true,
                      ),
                      const SizedBox(height: 10),
                      _buildRow(
                        context,
                        'Amount Paid',
                        '₹${inv.amountPaid.toInt()}',
                        isHighlight: true,
                      ),
                      if (inv.balanceDue > 0) ...[
                        const SizedBox(height: 10),
                        _buildRow(
                          context,
                          'Balance Due at Delivery',
                          '₹${inv.balanceDue.toInt()}',
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                CustomButton(
                  text: 'Share Invoice Link',
                  icon: Icons.share,
                  onPressed: () {
                    Share.share(
                      'View KRUIZLY Invoice: https://kruizly.com/invoice.html?id=$bookingId',
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildRow(
    BuildContext context,
    String label,
    String val, {
    bool isBold = false,
    bool isHighlight = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isBold ? 15 : 13,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w400,
            color: isBold ? context.themeTextPrimary : context.themeTextSecondary,
          ),
        ),
        Text(
          val,
          style: TextStyle(
            fontSize: isBold ? 15 : 13,
            fontWeight: isBold || isHighlight
                ? FontWeight.w700
                : FontWeight.w500,
            color: isHighlight
                ? AppColors.success
                : (isBold ? context.themeTextPrimary : context.themeTextSecondary),
          ),
        ),
      ],
    );
  }
}
