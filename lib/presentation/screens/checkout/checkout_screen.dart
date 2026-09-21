import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/booking_model.dart';
import '../../state/app_providers.dart';
import '../../state/booking_provider.dart';
import '../../state/trips_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/status_badge.dart';
import 'components/payment_proof_uploader.dart';
import 'components/upi_qr_section.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  final String bookingId;

  const CheckoutScreen({super.key, required this.bookingId});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  final _utrController = TextEditingController();
  File? _proofFile;
  bool _isSubmitting = false;
  String? _error;
  int _selectedPaymentMethod = 0; // 0: UPI, 1: Bank Transfer

  @override
  void dispose() {
    _utrController.dispose();
    super.dispose();
  }

  void _copyToClipboard(String label, String value) {
    Clipboard.setData(ClipboardData(text: value));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label copied to clipboard!'),
        duration: const Duration(seconds: 2),
        backgroundColor: AppColors.primaryDark,
      ),
    );
  }

  Future<void> _handlePaymentSubmission(double amount) async {
    final utr = _utrController.text.trim();
    if (utr.isEmpty) {
      setState(
        () => _error =
            'Please enter the 12-digit UPI / Bank Reference Number (UTR).',
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    try {
      final paymentRepo = ref.read(paymentRepositoryProvider);
      String? screenshotUrl;
      String? screenshotMediaId;

      if (_proofFile != null) {
        final uploadRes = await paymentRepo.uploadPaymentScreenshot(
          _proofFile!,
          widget.bookingId,
        );
        screenshotMediaId = uploadRes['mediaId']?.toString();
        screenshotUrl = uploadRes['url']?.toString();
      }

      await paymentRepo.submitPayment(
        bookingId: widget.bookingId,
        amount: amount,
        utr: utr,
        method: _selectedPaymentMethod == 0 ? 'upi' : 'bank_transfer',
        screenshotUrl: screenshotUrl,
        screenshotMediaId: screenshotMediaId,
      );

      // Refresh trips
      ref.read(tripsProvider.notifier).fetchTrips();

      if (!mounted) return;

      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          backgroundColor: ctx.themeSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: ctx.themeBorder),
          ),
          title: Row(
            children: const [
              Icon(Icons.check_circle, color: AppColors.success, size: 26),
              SizedBox(width: 10),
              Text(
                'Payment Submitted',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          content: Text(
            'Your payment of ₹${amount.toInt()} for Booking #${widget.bookingId} has been recorded in the live database. Our operations team will verify your reference number and confirm your trip.',
            style: TextStyle(
              color: ctx.themeTextSecondary,
              fontSize: 13,
              height: 1.4,
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                context.go('/trips');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text('View My Bookings', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    } catch (e) {
      setState(() {
        _isSubmitting = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final draft = ref.watch(bookingProvider);
    final bookingAsync = ref.watch(bookingDetailProvider(widget.bookingId));

    double payableAmount = draft.breakdown.advanceAmount > 0
        ? draft.breakdown.advanceAmount
        : (draft.breakdown.finalAmount > 0 ? draft.breakdown.finalAmount : 500.0);

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
          'Secure Checkout',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: context.themeTextPrimary,
          ),
        ),
      ),
      body: bookingAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (_, _) => _buildBody(context, payableAmount, null),
        data: (booking) {
          if (booking != null) {
            payableAmount = booking.advanceAmount > 0
                ? booking.advanceAmount
                : (booking.totalAmount > 0
                      ? booking.totalAmount
                      : payableAmount);
          }
          return _buildBody(context, payableAmount, booking);
        },
      ),
    );
  }

  Widget _buildBody(BuildContext context, double payableAmount, BookingModel? booking) {
    final draft = ref.watch(bookingProvider);
    final dateFormat = DateFormat('dd MMM yyyy, hh:mm a');

    final vehicleName = booking?.vehicleName ?? draft.vehicle?.fullName ?? 'Vehicle Rental';
    final vehicleCategory = booking?.vehicleCategory ?? draft.vehicle?.categoryDisplay ?? 'Self-Drive';
    final vehicleReg = booking?.vehicleReg ?? draft.vehicle?.regNo ?? '';
    final pickupDate = booking?.pickupDate ?? draft.pickupDate;
    final dropDate = booking?.dropDate ?? draft.dropDate;
    final totalAmount = booking?.totalAmount ?? draft.breakdown.finalAmount;
    final securityDeposit = booking?.securityDeposit ?? draft.breakdown.securityDeposit;
    final couponDiscount = booking?.couponDiscount ?? draft.breakdown.couponDiscount;
    final remainingBalance = booking?.remainingBalance ?? draft.breakdown.remainingBalance;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // RESERVATION & PAYMENT SUMMARY CARD
          GlassCard(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'BOOKING #${widget.bookingId}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1,
                        color: AppColors.primaryLight,
                      ),
                    ),
                    StatusBadge(status: booking?.status ?? 'pending_payment'),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  vehicleName,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: context.themeTextPrimary,
                  ),
                ),
                if (vehicleCategory.isNotEmpty || vehicleReg.isNotEmpty)
                  Text(
                    '$vehicleCategory ${vehicleReg.isNotEmpty ? "• $vehicleReg" : ""}',
                    style: TextStyle(
                      fontSize: 12,
                      color: context.themeTextSecondary,
                    ),
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
                          Text(
                            'PICKUP',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: context.themeTextMuted,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            dateFormat.format(pickupDate),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: context.themeTextPrimary,
                            ),
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
                          Text(
                            'DROP-OFF',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: context.themeTextMuted,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            dateFormat.format(dropDate),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: context.themeTextPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (totalAmount > 0) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Divider(color: context.themeBorder, height: 1),
                  ),
                  _buildSummaryRow(context, 'Total Rental Charge', '₹${totalAmount.toInt()}'),
                  if (securityDeposit > 0) ...[
                    const SizedBox(height: 6),
                    _buildSummaryRow(context, 'Security Deposit (Refundable)', '₹${securityDeposit.toInt()}'),
                  ],
                  if (couponDiscount > 0) ...[
                    const SizedBox(height: 6),
                    _buildSummaryRow(context, 'Coupon Discount', '-₹${couponDiscount.toInt()}', isDiscount: true),
                  ],
                  if (remainingBalance > 0) ...[
                    const SizedBox(height: 6),
                    _buildSummaryRow(context, 'Balance Due on Delivery', '₹${remainingBalance.toInt()}'),
                  ],
                ],
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'PAYABLE TODAY',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1,
                              color: AppColors.primaryLight,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            payableAmount < totalAmount ? 'Advance Token Deposit' : 'Full Payment',
                            style: TextStyle(
                              fontSize: 12,
                              color: context.themeTextSecondary,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '₹${payableAmount.toInt()}',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: AppColors.primaryLight,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // PAYMENT METHOD SELECTOR TABS
          Text(
            'SELECT PAYMENT METHOD',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
              color: context.themeTextMuted,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedPaymentMethod = 0),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                    decoration: BoxDecoration(
                      color: _selectedPaymentMethod == 0
                          ? AppColors.primary
                          : context.themeSurfaceElevated,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: _selectedPaymentMethod == 0
                            ? Colors.transparent
                            : context.themeBorder,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.qr_code_scanner,
                          size: 22,
                          color: _selectedPaymentMethod == 0 ? Colors.white : AppColors.primaryLight,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'UPI Payment',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: _selectedPaymentMethod == 0 ? Colors.white : context.themeTextPrimary,
                          ),
                        ),
                        Text(
                          'GPay, PhonePe, Paytm',
                          style: TextStyle(
                            fontSize: 10,
                            color: _selectedPaymentMethod == 0 ? Colors.white70 : context.themeTextMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedPaymentMethod = 1),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                    decoration: BoxDecoration(
                      color: _selectedPaymentMethod == 1
                          ? AppColors.primary
                          : context.themeSurfaceElevated,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: _selectedPaymentMethod == 1
                            ? Colors.transparent
                            : context.themeBorder,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.account_balance_outlined,
                          size: 22,
                          color: _selectedPaymentMethod == 1 ? Colors.white : AppColors.primaryLight,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Bank Transfer',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: _selectedPaymentMethod == 1 ? Colors.white : context.themeTextPrimary,
                          ),
                        ),
                        Text(
                          'NEFT, IMPS, RTGS',
                          style: TextStyle(
                            fontSize: 10,
                            color: _selectedPaymentMethod == 1 ? Colors.white70 : context.themeTextMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // METHOD VIEW (UPI OR BANK TRANSFER)
          if (_selectedPaymentMethod == 0)
            UpiQrSection(bookingId: widget.bookingId, amount: payableAmount)
          else
            _buildBankTransferCard(context, payableAmount),

          const SizedBox(height: 16),

          // CONFIRM PAYMENT REFERENCE & UTR
          GlassCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Confirm Payment Reference',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: context.themeTextPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'After transferring ₹${payableAmount.toInt()}, enter the 12-digit UPI Reference / UTR Number found in your banking app receipt.',
                  style: TextStyle(
                    fontSize: 12,
                    color: context.themeTextSecondary,
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _utrController,
                  keyboardType: TextInputType.number,
                  style: TextStyle(
                    color: context.themeTextPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: InputDecoration(
                    labelText: '12-digit UTR / Reference Number *',
                    labelStyle: TextStyle(
                      color: context.themeTextSecondary,
                      fontSize: 13,
                    ),
                    hintText: 'e.g. 423589123456',
                    hintStyle: TextStyle(
                      color: context.themeTextMuted,
                      fontSize: 13,
                    ),
                    prefixIcon: const Icon(
                      Icons.tag,
                      color: AppColors.primaryLight,
                    ),
                    filled: true,
                    fillColor: context.themeSurfaceElevated,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: context.themeBorder),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: context.themeBorder),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.primary),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // RECEIPT / SCREENSHOT UPLOADER
          PaymentProofUploader(
            selectedFile: _proofFile,
            onFilePicked: (file) => setState(() => _proofFile = file),
          ),

          if (_error != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: AppColors.error, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _error!,
                      style: const TextStyle(color: AppColors.error, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 24),

          // ACTION BUTTON
          CustomButton(
            text: 'I Have Paid ₹${payableAmount.toInt()}',
            isLoading: _isSubmitting,
            icon: Icons.lock_outline,
            onPressed: () => _handlePaymentSubmission(payableAmount),
          ),

          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.verified_user_outlined, size: 14, color: context.themeTextMuted),
              const SizedBox(width: 6),
              Text(
                'Direct Hostinger MySQL API • 256-Bit SSL Encrypted',
                style: TextStyle(fontSize: 11, color: context.themeTextMuted),
              ),
            ],
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildBankTransferCard(BuildContext context, double payableAmount) {
    return GlassCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'BANK TRANSFER (NEFT / IMPS)',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                  color: context.themeTextMuted,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'SVC BANK',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryLight,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildCopyableField(
            context,
            'Beneficiary Account Name',
            'KRUIZLY',
          ),
          const SizedBox(height: 10),
          _buildCopyableField(
            context,
            'Account Number',
            '003110100014092',
          ),
          const SizedBox(height: 10),
          _buildCopyableField(
            context,
            'IFSC Code',
            'SVCB0000031',
          ),
          const SizedBox(height: 10),
          _buildCopyableField(
            context,
            'Bank Name',
            'SVC Co-operative Bank Ltd',
          ),
          const SizedBox(height: 10),
          _buildCopyableField(
            context,
            'Branch & Type',
            'Ghansoli, Navi Mumbai • Current Account',
          ),
        ],
      ),
    );
  }

  Widget _buildCopyableField(BuildContext context, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: context.themeSurfaceElevated,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: context.themeBorder),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 10, color: context.themeTextSecondary, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: context.themeTextPrimary),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Copy $label',
            icon: const Icon(Icons.copy, size: 18, color: AppColors.primaryLight),
            onPressed: () => _copyToClipboard(label, value),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(BuildContext context, String label, String val, {bool isDiscount = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 12, color: context.themeTextSecondary),
        ),
        Text(
          val,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isDiscount ? AppColors.success : context.themeTextPrimary,
          ),
        ),
      ],
    );
  }
}
