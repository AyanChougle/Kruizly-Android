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
final _hostNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'hostNav');
final _tripsNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'tripsNav');
final _profileNavigatorKey = GlobalKey<NavigatorState>(
  debugLabel: 'profileNav',
);

/// Butter-smooth, GPU-accelerated iOS/Cupertino style slide & parallax page transition
CustomTransitionPage<void> _buildTransitionPage({
  required GoRouterState state,
  required Widget child,
}) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 320),
    reverseTransitionDuration: const Duration(milliseconds: 280),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final forwardCurved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      final secondaryCurved = CurvedAnimation(
        parent: secondaryAnimation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );

      return SlideTransition(
        position: Tween<Offset>(
          begin: Offset.zero,
          end: const Offset(-0.20, 0),
        ).animate(secondaryCurved),
        child: FadeTransition(
          opacity: Tween<double>(
            begin: 1.0,
            end: 0.85,
          ).animate(secondaryCurved),
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1.0, 0),
              end: Offset.zero,
            ).animate(forwardCurved),
            child: child,
          ),
        ),
      );
    },
  );
}

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (context, state) => const SplashScreen()),
      GoRoute(
        path: '/sign-in',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) =>
            _buildTransitionPage(state: state, child: const SignInScreen()),
      ),
      GoRoute(
        path: '/sign-up',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) =>
            _buildTransitionPage(state: state, child: const SignUpScreen()),
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
            navigatorKey: _hostNavigatorKey,
            routes: [
              GoRoute(
                path: '/host',
                builder: (context, state) => const HostCarScreen(),
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
        pageBuilder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return _buildTransitionPage(
            state: state,
            child: VehicleDetailScreen(vehicleId: id),
          );
        },
      ),
      GoRoute(
        path: '/booking',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => _buildTransitionPage(
          state: state,
          child: const BookingConfigScreen(),
        ),
      ),
      GoRoute(
        path: '/checkout/:id',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return _buildTransitionPage(
            state: state,
            child: CheckoutScreen(bookingId: id),
          );
        },
      ),
      GoRoute(
        path: '/trips/:id',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return _buildTransitionPage(
            state: state,
            child: TripDetailScreen(bookingId: id),
          );
        },
      ),
      GoRoute(
        path: '/invoice/:id',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return _buildTransitionPage(
            state: state,
            child: InvoiceViewerScreen(bookingId: id),
          );
        },
      ),
      GoRoute(
        path: '/kyc',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => _buildTransitionPage(
          state: state,
          child: const KycVerificationScreen(),
        ),
      ),
      GoRoute(path: '/host-car', redirect: (context, state) => '/host'),
      GoRoute(
        path: '/contact',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) =>
            _buildTransitionPage(state: state, child: const ContactScreen()),
      ),
      GoRoute(
        path: '/staff-portal',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => _buildTransitionPage(
          state: state,
          child: const StaffDashboardScreen(),
        ),
      ),
    ],
  );
});
