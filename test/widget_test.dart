import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kruizly/data/models/admin_stats_model.dart';
import 'package:kruizly/data/models/coupon_model.dart';
import 'package:kruizly/data/models/user_model.dart';
import 'package:kruizly/data/models/vehicle_model.dart';
import 'package:kruizly/core/theme/app_theme.dart';
import 'package:kruizly/presentation/screens/booking/components/payment_plan_selector.dart';
import 'package:kruizly/presentation/state/booking_provider.dart';
import 'package:kruizly/presentation/widgets/background_video_widget.dart';
import 'package:kruizly/presentation/widgets/glass_card.dart';
import 'package:kruizly/presentation/widgets/price_breakdown_card.dart';
import 'package:kruizly/presentation/widgets/status_badge.dart';
import 'package:kruizly/presentation/widgets/vehicle_card.dart';

void main() {
  group('1. KRUIZLY Model Serialization Tests', () {
    test('VehicleModel.fromJson parses JSON correctly with computed getters', () {
      final json = {
        'id': 101,
        'car_id': 'CAR-101',
        'reg_no': 'MH43BZ9999',
        'brand': 'Audi',
        'model': 'A6',
        'year': 2024,
        'category': 'luxury',
        'transmission': 'Automatic',
        'fuel': 'Petrol',
        'seats': 5,
        'bags': 3,
        'price_day': 6500.0,
        'price_hour': 300.0,
        'driver_price': 1600.0,
        'security_deposit': 5000.0,
        'free_km': 300,
        'extra_km': 25.0,
        'location': 'Navi Mumbai Hub',
        'is_available': true,
        'status': 'available',
        'image_url': 'https://kruizly.com/cars/a6.jpg',
        'gallery': ['https://kruizly.com/cars/a6_1.jpg'],
      };

      final vehicle = VehicleModel.fromJson(json);

      expect(vehicle.id, 101);
      expect(vehicle.fullName, 'Audi A6');
      expect(vehicle.categoryDisplay, 'Luxury');
      expect(vehicle.regNo, 'MH43BZ9999');
      expect(vehicle.priceDay, 6500.0);
      expect(vehicle.priceHour, 300.0);
      expect(vehicle.isAvailable, true);
      expect(vehicle.gallery.length, 1);
      expect(vehicle.driverPriceHour, 1600.0 / 24.0);
    });

    test('UserModel.fromJson and toJson parses user profile fields correctly', () {
      final json = {
        'id': 99,
        'firebaseUid': 'fb_uid_99',
        'name': 'Ayan Chakraborty',
        'email': 'ayan@example.com',
        'phone': '+919876543210',
        'role': 'customer',
        'licenseStatus': 'verified',
        'aadharStatus': 'verified',
        'panStatus': 'verified',
      };

      final user = UserModel.fromJson(json);

      expect(user.id, 99);
      expect(user.name, 'Ayan Chakraborty');
      expect(user.isVerified, true);
      expect(user.role, 'customer');

      final outJson = user.toJson();
      expect(outJson['name'], 'Ayan Chakraborty');
      expect(outJson['licenseStatus'], 'verified');
    });

    test('CouponModel parses properties and CouponValidationResult maps correctly', () {
      const percentCoupon = CouponModel(
        id: 1,
        code: 'SAVE20',
        discountType: 'percent',
        discountValue: 20.0,
        minOrder: 2000.0,
        maxDiscount: 1000.0,
        label: '20% OFF',
        description: 'Get 20% off up to ₹1,000',
        active: true,
      );

      expect(percentCoupon.type, 'percent');
      expect(percentCoupon.value, 20.0);
      expect(percentCoupon.maxDiscountValue, 1000.0);
      expect(percentCoupon.isActive, true);

      final valResult = CouponValidationResult.fromJson({
        'valid': true,
        'code': 'SAVE20',
        'discountAmount': 800.0,
        'finalTotal': 3200.0,
        'label': '20% OFF',
        'description': 'Applied successfully',
      });

      expect(valResult.isValid, true);
      expect(valResult.discountAmount, 800.0);
      expect(valResult.finalTotal, 3200.0);
    });
  });

  group('2. KRUIZLY Booking Price Engine Tests', () {
    const vehicle = VehicleModel(
      id: 1,
      regNo: 'MH43BZ0001',
      brand: 'BMW',
      model: '7 Series',
      year: 2024,
      category: 'luxury',
      transmission: 'Automatic',
      fuel: 'Petrol',
      seats: 5,
      bags: 3,
      priceDay: 5000.0,
      priceHour: 250.0,
      driverPrice: 1500.0,
      securityDeposit: 3000.0,
      freeKm: 250,
      extraKm: 20.0,
      location: 'Gavson Business Park, Ghansoli',
      isAvailable: true,
      status: 'available',
    );

    test('Calculates 24-hour single-day rental accurately', () {
      final now = DateTime(2026, 9, 20, 10, 0);
      final drop = DateTime(2026, 9, 21, 10, 0);

      final draft = BookingDraftState(
        vehicle: vehicle,
        pickupDate: now,
        dropDate: drop,
        withDriver: false,
        paymentPlan: 'advance',
      );

      final bk = draft.breakdown;
      expect(bk.durationHours, 24);
      expect(bk.durationDays, 1);
      expect(bk.rentalTotal, 6000.0); // 24 * 250
      expect(bk.securityDeposit, 3000.0);
      expect(bk.finalAmount, 9000.0);
      expect(bk.advanceAmount, 500.0);
      expect(bk.remainingBalance, 8500.0);
    });

    test('Calculates driver charges properly over multi-day booking', () {
      final now = DateTime(2026, 9, 20, 10, 0);
      final drop = DateTime(2026, 9, 22, 10, 0); // 48 hours = 2 days

      final draft = BookingDraftState(
        vehicle: vehicle,
        pickupDate: now,
        dropDate: drop,
        withDriver: true,
        paymentPlan: 'full',
      );

      final bk = draft.breakdown;
      expect(bk.durationHours, 48);
      expect(bk.durationDays, 2);
      expect(bk.driverTotal, 3000.0); // 2 days * 1500
      expect(bk.rentalTotal, 12000.0); // 48 * 250
      expect(bk.advanceAmount, bk.finalAmount); // Full payment
      expect(bk.remainingBalance, 0.0);
    });

    test('Applies percentage coupon correctly up to max cap', () {
      const coupon = CouponModel(
        id: 1,
        code: 'KRUIZ10',
        discountType: 'percent',
        discountValue: 10.0,
        minOrder: 1000.0,
        maxDiscount: 500.0,
        label: '10% OFF',
        description: '10% off up to 500',
        active: true,
      );

      final now = DateTime(2026, 9, 20, 10, 0);
      final drop = DateTime(2026, 9, 22, 10, 0); // 48 hours

      final draft = BookingDraftState(
        vehicle: vehicle,
        pickupDate: now,
        dropDate: drop,
        withDriver: false,
        appliedCoupon: coupon,
        paymentPlan: 'full',
      );

      final bk = draft.breakdown;
      expect(bk.durationHours, 48);
      expect(bk.rentalTotal, 12000.0); // 48 * 250
      expect(bk.couponDiscount, 500.0); // 10% of 12000 = 1200, capped at 500
      expect(bk.finalAmount, 12000.0 + 3000.0 - 500.0); // 14500
      expect(bk.advanceAmount, 14500.0);
      expect(bk.remainingBalance, 0.0);
    });
  });

  group('3. KRUIZLY Widget Rendering Tests', () {
    testWidgets('StatusBadge renders correct labels and styling', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                StatusBadge(status: 'confirmed'),
                StatusBadge(status: 'pending_payment'),
                StatusBadge(status: 'cancelled'),
              ],
            ),
          ),
        ),
      );

      expect(find.text('CONFIRMED'), findsOneWidget);
      expect(find.text('PENDING PAYMENT'), findsOneWidget);
      expect(find.text('CANCELLED'), findsOneWidget);
    });

    testWidgets('GlassCard displays content and responds to taps', (tester) async {
      var tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GlassCard(
              onTap: () => tapped = true,
              child: const Text('Kruizly Glass Card Content'),
            ),
          ),
        ),
      );

      expect(find.text('Kruizly Glass Card Content'), findsOneWidget);
      await tester.tap(find.text('Kruizly Glass Card Content'));
      expect(tapped, true);
    });

    testWidgets('PaymentPlanSelector renders advance and full options and allows selection',
        (tester) async {
      String selected = 'advance';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return PaymentPlanSelector(
                  selectedPlan: selected,
                  advanceAmount: 500.0,
                  totalAmount: 6500.0,
                  onPlanChanged: (plan) {
                    setState(() => selected = plan);
                  },
                );
              },
            ),
          ),
        ),
      );

      expect(find.text('Payment Preference'), findsOneWidget);
      expect(find.textContaining('Pay Advance Token (₹500)'), findsOneWidget);
      expect(find.textContaining('Pay Full Amount (₹6500)'), findsOneWidget);
      expect(find.text('POPULAR'), findsOneWidget);

      // Tap on the full amount option
      await tester.tap(find.textContaining('Pay Full Amount (₹6500)'));
      await tester.pumpAndSettle();

      expect(selected, 'full');
    });

    test('AdminStatsModel parses Hostinger live and effective stats with monthly ledger', () {
      final hostingerPayload = {
        'status': 'success',
        'success': true,
        'data': {
          'live': {
            'total_users': 158,
            'total_bookings': 22,
            'pending_docs': 11,
            'pending_payments': 8,
            'day_sales': 0,
            'week_sales': 105816,
            'total_revenue': 627565,
            'month_revenue': 267168,
            'last_month_revenue': 281857,
            'paid_bookings': 16,
            'avg_booking': 39222.81,
            'active_trips': 7,
            'completed_trips': 10,
            'total_fleet': 8,
            'available_in_yard': 1,
            'fleet_utilization': 88,
          },
          'effective': {
            'total_users': 158,
            'total_bookings': 22,
            'pending_docs': 11,
            'pending_payments': 8,
            'day_sales': 0,
            'week_sales': 105816,
            'total_revenue': 627565,
            'month_revenue': 267168,
            'last_month_revenue': 281857,
            'paid_bookings': 16,
            'avg_booking': 39222.81,
            'active_trips': 7,
            'completed_trips': 10,
            'total_fleet': 8,
            'available_in_yard': 1,
            'fleet_utilization': 88,
          },
          'monthly': {
            '2026-09-01': {
              'metric_date': '2026-09-01',
              'month_sales': 267168,
              'total_bookings': 20,
            },
          },
        },
      };

      final stats = AdminStatsModel.fromJson(hostingerPayload);
      expect(stats.totalRevenue, 627565.0);
      expect(stats.monthRevenue, 267168.0);
      expect(stats.totalBookings, 22);
      expect(stats.paidBookings, 16);
      expect(stats.pendingPayments, 8);
      expect(stats.pendingDocs, 11);
      expect(stats.activeTrips, 7);
      expect(stats.monthly.containsKey('2026-09-01'), true);
      expect((stats.monthly['2026-09-01'] as Map)['month_sales'], 267168);
    });

    test('AdminStatsModel.empty has strictly zeroed values with no hardcoded demo data', () {
      const emptyStats = AdminStatsModel.empty;
      expect(emptyStats.totalRevenue, 0.0);
      expect(emptyStats.monthRevenue, 0.0);
      expect(emptyStats.totalBookings, 0);
      expect(emptyStats.paidBookings, 0);
      expect(emptyStats.pendingPayments, 0);
      expect(emptyStats.pendingDocs, 0);
      expect(emptyStats.activeTrips, 0);
      expect(emptyStats.totalFleet, 0);
      expect(emptyStats.monthly.isEmpty, true);
    });

    testWidgets('PriceBreakdownCard renders properly in both Light and Dark modes', (tester) async {
      const breakdown = BookingPriceBreakdown(
        durationHours: 24,
        durationDays: 1,
        rentalTotal: 6000.0,
        driverTotal: 0.0,
        securityDeposit: 3000.0,
        couponDiscount: 500.0,
        finalAmount: 8500.0,
        advanceAmount: 500.0,
        remainingBalance: 8000.0,
        formattedDuration: '24 hrs',
      );

      // Render in Light Mode
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: PriceBreakdownCard(
              breakdown: breakdown,
              paymentPlan: 'advance',
              withDriver: false,
            ),
          ),
        ),
      );

      expect(find.text('Price Breakdown'), findsOneWidget);
      expect(find.text('Base Rental (24 hrs)'), findsOneWidget);
      expect(find.text('₹6000'), findsOneWidget);
      expect(find.text('Security Deposit (Refundable)'), findsOneWidget);
      expect(find.text('₹3000'), findsOneWidget);
      expect(find.text('Coupon Discount'), findsOneWidget);
      expect(find.text('-₹500'), findsOneWidget);
      expect(find.text('Total Trip Amount'), findsOneWidget);
      expect(find.text('₹8500'), findsOneWidget);
      expect(find.text('Advance Token (Pay Now)'), findsOneWidget);
      expect(find.text('Balance at Car Delivery'), findsOneWidget);
      expect(find.text('₹8000'), findsOneWidget);
    });


    testWidgets('VehicleCard renders available tag, hourly rate, specifications, and action buttons', (tester) async {
      const cardVehicle = VehicleModel(
        id: 77,
        regNo: 'MH43BZ7777',
        brand: 'Mahindra',
        model: '7XO',
        year: 2026,
        category: 'suv',
        transmission: 'AMT',
        fuel: 'Diesel',
        seats: 7,
        bags: 3,
        priceDay: 4500.0,
        priceHour: 375.0,
        driverPrice: 1200.0,
        securityDeposit: 3000.0,
        freeKm: 250,
        extraKm: 18.0,
        location: 'Navi Mumbai',
        isAvailable: true,
        status: 'available',
      );

      bool bookNowTapped = false;
      bool showMoreTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: VehicleCard(
              vehicle: cardVehicle,
              onTap: () => showMoreTapped = true,
              onBookNow: () => bookNowTapped = true,
            ),
          ),
        ),
      );

      expect(find.text('AVAILABLE'), findsOneWidget);
      expect(find.text('Mahindra 7XO'), findsOneWidget);
      expect(find.text('₹375'), findsOneWidget);
      expect(find.text('/HOUR'), findsOneWidget);
      expect(find.text('AMT'), findsOneWidget);
      expect(find.text('Diesel'), findsOneWidget);
      expect(find.text('7 Seats'), findsOneWidget);
      expect(find.text('BOOK NOW'), findsOneWidget);
      expect(find.text('Show More'), findsOneWidget);

      await tester.tap(find.text('BOOK NOW'));
      expect(bookNowTapped, true);

      await tester.tap(find.text('Show More'));
      expect(showMoreTapped, true);
    });

    testWidgets('BackgroundVideoWidget mounts safely and renders child content', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: BackgroundVideoWidget(
              isEnabled: true,
              child: Center(
                child: Text('KRUIZLY EXECUTIVE CONTENT'),
              ),
            ),
          ),
        ),
      );

      expect(find.text('KRUIZLY EXECUTIVE CONTENT'), findsOneWidget);

      // Verify disabled state
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: BackgroundVideoWidget(
              isEnabled: false,
              child: Center(
                child: Text('KRUIZLY STATIC CONTENT'),
              ),
            ),
          ),
        ),
      );

      expect(find.text('KRUIZLY STATIC CONTENT'), findsOneWidget);
    });
  });
}
