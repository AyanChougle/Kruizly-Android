import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_assets.dart';
import '../../../core/theme/app_colors.dart';
import '../../state/auth_provider.dart';
import '../../state/booking_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/price_breakdown_card.dart';
import 'components/coupon_input_card.dart';
import 'components/date_time_picker_card.dart';
import 'components/payment_plan_selector.dart';

class BookingConfigScreen extends ConsumerStatefulWidget {
  const BookingConfigScreen({super.key});

  @override
  ConsumerState<BookingConfigScreen> createState() =>
      _BookingConfigScreenState();
}

class _BookingConfigScreenState extends ConsumerState<BookingConfigScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(authProvider).user;
      if (user != null) {
        _nameController.text = user.name;
        _phoneController.text = user.phone ?? '';
        _emailController.text = user.email;
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleProceed() async {
    final bookingState = ref.read(bookingProvider);
    if (bookingState.vehicle == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a vehicle first.')),
      );
      return;
    }

    final authState = ref.read(authProvider);
    if (!authState.isAuthenticated) {
      final shouldSignIn = await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
          backgroundColor: context.themeSurface,
          title: Text(
            'Sign In Required',
            style: TextStyle(color: context.themeTextPrimary),
          ),
          content: Text(
            'Please sign in or create an account to record and protect your booking.',
            style: TextStyle(color: context.themeTextSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: Text(
                'Cancel',
                style: TextStyle(color: context.themeTextSecondary),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(c, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
              child: const Text('Sign In'),
            ),
          ],
        ),
      );

      if (shouldSignIn == true && mounted) {
        context.push('/sign-in');
      }
      return;
    }

    final bookingId = await ref
        .read(bookingProvider.notifier)
        .submitBooking(
          userName: _nameController.text.trim().isNotEmpty
              ? _nameController.text.trim()
              : null,
          userEmail: _emailController.text.trim().isNotEmpty
              ? _emailController.text.trim()
              : null,
          userPhone: _phoneController.text.trim().isNotEmpty
              ? _phoneController.text.trim()
              : null,
        );

    if (bookingId != null && mounted) {
      context.push('/checkout/$bookingId');
    }
  }

  @override
  Widget build(BuildContext context) {
    final draft = ref.watch(bookingProvider);
    final bookingNotifier = ref.read(bookingProvider.notifier);
    final vehicle = draft.vehicle;

    if (vehicle == null) {
      return Scaffold(
        backgroundColor: context.themeBackground,
        appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.directions_car_outlined,
                size: 64,
                color: context.themeTextMuted,
              ),
              const SizedBox(height: 16),
              Text(
                'No Vehicle Selected',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: context.themeTextPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Please browse the fleet and pick a car to rent.',
                style: TextStyle(color: context.themeTextSecondary),
              ),
              const SizedBox(height: 20),
              CustomButton(
                text: 'Browse Fleet',
                width: 160,
                onPressed: () => context.go('/fleet'),
              ),
            ],
          ),
        ),
      );
    }

    final bk = draft.breakdown;

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
          'Configure Booking',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: context.themeTextPrimary,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GlassCard(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  SizedBox(
                    width: 90,
                    height: 60,
                    child: Center(
                      child: Image.asset(
                        AppAssets.getCarImagePath(vehicle.brand, vehicle.model),
                        fit: BoxFit.contain,
                        errorBuilder: (_, _, _) => Image.asset(
                          AppAssets.carPlaceholder,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          vehicle.fullName,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: context.themeTextPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${vehicle.categoryDisplay} • ₹${vehicle.priceDay.toInt()}/day',
                          style: const TextStyle(
                            fontSize: 12,
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
            DateTimePickerCard(
              pickupDate: draft.pickupDate,
              dropDate: draft.dropDate,
              formattedDuration: bk.formattedDuration,
              onDatesChanged: bookingNotifier.setDates,
            ),
            const SizedBox(height: 16),

            CouponInputCard(
              appliedCoupon: draft.appliedCoupon,
              isValidating: draft.isValidatingCoupon,
              error: draft.couponError,
              onApply: bookingNotifier.applyCoupon,
              onRemove: bookingNotifier.removeCoupon,
            ),
            const SizedBox(height: 16),
            PaymentPlanSelector(
              selectedPlan: draft.paymentPlan,
              advanceAmount: bk.advanceAmount,
              totalAmount: bk.finalAmount,
              onPlanChanged: bookingNotifier.setPaymentPlan,
            ),
            const SizedBox(height: 16),
            PriceBreakdownCard(
              breakdown: bk,
              paymentPlan: draft.paymentPlan,
              withDriver: false,
            ),
            if (draft.submissionError != null) ...[
              const SizedBox(height: 12),
              Text(
                draft.submissionError!,
                style: const TextStyle(color: AppColors.error, fontSize: 13),
              ),
            ],
            const SizedBox(height: 24),
            CustomButton(
              text: draft.paymentPlan == 'advance'
                  ? 'Proceed to Pay ₹${bk.advanceAmount.toInt()} Token'
                  : 'Proceed to Pay ₹${bk.finalAmount.toInt()}',
              isLoading: draft.isSubmitting,
              onPressed: _handleProceed,
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
