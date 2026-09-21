import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../screens/auth/sign_in_screen.dart';
import '../screens/auth/sign_up_screen.dart';
import '../screens/booking/booking_config_screen.dart';
import '../screens/checkout/checkout_screen.dart';
import '../screens/fleet/fleet_catalog_screen.dart';
import '../screens/fleet/vehicle_detail_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/partner/host_car_screen.dart';
import '../screens/contact/contact_screen.dart';
import '../screens/profile/kyc_verification_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/shell/main_shell.dart';
import '../screens/splash_screen.dart';
import '../screens/staff/staff_dashboard_screen.dart';
import '../screens/trips/invoice_viewer_screen.dart';
import '../screens/trips/my_trips_screen.dart';
import '../screens/trips/trip_detail_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _homeNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'homeNav');
final _fleetNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'fleetNav');
final _tripsNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'tripsNav');
final _profileNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'profileNav');

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/sign-in',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const SignInScreen(),
      ),
      GoRoute(
        path: '/sign-up',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const SignUpScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            navigatorKey: _homeNavigatorKey,
            routes: [
              GoRoute(
                path: '/home',
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _fleetNavigatorKey,
            routes: [
              GoRoute(
                path: '/fleet',
                builder: (context, state) => const FleetCatalogScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _tripsNavigatorKey,
            routes: [
              GoRoute(
                path: '/trips',
                builder: (context, state) => const MyTripsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _profileNavigatorKey,
            routes: [
              GoRoute(
                path: '/profile',
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/fleet/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return VehicleDetailScreen(vehicleId: id);
        },
      ),
      GoRoute(
        path: '/booking',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const BookingConfigScreen(),
      ),
      GoRoute(
        path: '/checkout/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return CheckoutScreen(bookingId: id);
        },
      ),
      GoRoute(
        path: '/trips/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return TripDetailScreen(bookingId: id);
        },
      ),
      GoRoute(
        path: '/invoice/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return InvoiceViewerScreen(bookingId: id);
        },
      ),
      GoRoute(
        path: '/kyc',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const KycVerificationScreen(),
      ),
      GoRoute(
        path: '/host-car',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const HostCarScreen(),
      ),
      GoRoute(
        path: '/contact',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const ContactScreen(),
      ),
      GoRoute(
        path: '/staff-portal',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const StaffDashboardScreen(),
      ),
    ],
  );
});
