import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../state/auth_provider.dart';
import '../../state/trips_provider.dart';
import '../../widgets/custom_button.dart';
import 'components/trip_card.dart';

class MyTripsScreen extends ConsumerWidget {
  const MyTripsScreen({super.key});

  static const List<Map<String, String>> filters = [
    {'id': 'all', 'label': 'All Trips'},
    {'id': 'active', 'label': 'Active / Upcoming'},
    {'id': 'completed', 'label': 'Completed'},
    {'id': 'cancelled', 'label': 'Cancelled'},
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    if (!authState.isAuthenticated) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text('My Trips', style: TextStyle(fontWeight: FontWeight.w700, color: context.themeTextPrimary)),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.luggage_outlined, size: 64, color: context.themeTextMuted),
                const SizedBox(height: 16),
                Text(
                  'Sign In to View Trips',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: context.themeTextPrimary),
                ),
                const SizedBox(height: 8),
                Text(
                  'Track active bookings, view invoices, and manage upcoming self-drive rentals.',
                  style: TextStyle(color: context.themeTextSecondary, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                CustomButton(
                  text: 'Sign In',
                  width: 160,
                  onPressed: () => context.push('/sign-in'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final tripsState = ref.watch(tripsProvider);
    final tripsNotifier = ref.read(tripsProvider.notifier);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'My Trips',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: context.themeTextPrimary),
        ),
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        backgroundColor: context.themeSurface,
        onRefresh: () => tripsNotifier.fetchTrips(),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: SizedBox(
                height: 36,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: filters.map((f) {
                    final isSelected = tripsState.filter == f['id'];
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(
                          f['label']!,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: isSelected ? Colors.white : context.themeTextSecondary,
                          ),
                        ),
                        selected: isSelected,
                        selectedColor: AppColors.primary,
                        backgroundColor: context.themeSurfaceElevated,
                        side: BorderSide(
                          color: isSelected ? AppColors.primaryLight : context.themeBorder,
                        ),
                        onSelected: (_) => tripsNotifier.setFilter(f['id']!),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: tripsState.isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                  : tripsState.filteredBookings.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.luggage_outlined, size: 54, color: context.themeTextMuted),
                              const SizedBox(height: 12),
                              Text(
                                'No bookings found',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: context.themeTextPrimary),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Explore the KRUIZLY fleet and book your next drive.',
                                style: TextStyle(color: context.themeTextSecondary, fontSize: 13),
                              ),
                              const SizedBox(height: 20),
                              CustomButton(
                                text: 'Explore Fleet',
                                width: 150,
                                onPressed: () => context.go('/fleet'),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          itemCount: tripsState.filteredBookings.length,
                          itemBuilder: (context, index) {
                            final b = tripsState.filteredBookings[index];
                            return TripCard(
                              booking: b,
                              onTap: () => context.push('/trips/${b.bookingId}'),
                              onPayNow: () => context.push('/checkout/${b.bookingId}'),
                              onInvoice: () => context.push('/invoice/${b.bookingId}'),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
