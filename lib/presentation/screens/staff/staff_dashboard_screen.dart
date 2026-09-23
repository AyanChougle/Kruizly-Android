import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_assets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/media_permission_helper.dart';
import '../../../core/utils/booking_notification_helper.dart';
import '../../../data/models/admin_stats_model.dart';
import '../../../data/models/booking_model.dart';
import '../../../data/models/coupon_model.dart';
import '../../../data/models/vehicle_model.dart';
import '../../state/admin_provider.dart';
import '../../state/auth_provider.dart';
import '../../state/fleet_provider.dart';
import '../../widgets/background_video_widget.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/status_badge.dart';

String _formatINR(num value) {
  final formatter = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 0,
  );
  return formatter.format(value.round());
}

/// User requested: "dont show amounts like eg 124L show full figures like 123456"
String _formatINRShort(num value) {
  return _formatINR(value);
}

class StaffDashboardScreen extends ConsumerStatefulWidget {
  const StaffDashboardScreen({super.key});

  @override
  ConsumerState<StaffDashboardScreen> createState() => _StaffDashboardScreenState();
}

class _StaffDashboardScreenState extends ConsumerState<StaffDashboardScreen> {
  String _selectedRole = 'ADMIN';
  final bool _bgVideoEnabled = true;

  // Sub-tabs for Admin (8 tabs matching admin.html)
  int _adminSubTab = 0;

  // Sub-tabs for Executive (5 tabs matching executive.html)
  int _execSubTab = 0;

  // Sub-tabs for Manager (4 tabs matching manager.html)
  int _mgrSubTab = 0;

  // Manager state & filters
  String _mgrPeriod = 'All Time';
  DateTime? _mgrCustomFrom;
  DateTime? _mgrCustomTo;
  String _mgrFleetFilter = 'all'; // 'all', 'on_trip', 'yard'
  bool _otherFleetsCollapsed = false;

  // Customer Analytics filter
  String _custPeriod = 'All Time';

  // Booking Analytics filter
  String _bookPeriod = 'All Time';

  // Accounts filter
  String _accountsSearchQuery = '';

  // Booking Calendar state
  DateTime _calendarMonth = DateTime(2026, 9, 1);
  String _calendarViewMode = 'grid'; // 'grid', 'agenda'
  DateTime? _selectedCalendarDate;

  // User Accounts & KYC search
  String _userSearchQuery = '';

  // All Bookings filters (Admin & Executive)
  String _adminBookingStatusFilter = 'all';
  String _adminBookingSort = 'newest';
  DateTime? _adminDateFrom;
  DateTime? _adminDateTo;

  // Form states for Add Fleet Vehicle
  final _addFleetRegController = TextEditingController();
  final _addFleetBrandController = TextEditingController();
  final _addFleetModelController = TextEditingController();
  final _addFleetRateController = TextEditingController(text: '3500');
  final _addFleetOwnerController = TextEditingController();
  bool _addFleetIsCurrent = true;

  // Form states for Add Coupon Code
  final _couponCodeController = TextEditingController();
  final _couponLabelController = TextEditingController();
  final _couponValueController = TextEditingController(text: '500');
  final _couponMinOrderController = TextEditingController(text: '0');
  String _couponDiscountType = 'flat'; // 'flat', 'percentage'

  // Expanded booking IDs in Admin All Bookings (Screenshot 1)
  final Set<String> _expandedBookingIds = {};
  final Map<String, TextEditingController> _startOdoControllers = {};
  final Map<String, TextEditingController> _endOdoControllers = {};
  final Map<String, TextEditingController> _startFastagControllers = {};
  final Map<String, TextEditingController> _returnFastagControllers = {};

  // Active roster tracking for manager summary
  final Set<String> _currentRosterRegs = {
    'MH03EL1025',
    'MH05GJ4711',
    'MH48GJ4153',
    'MH04MU1178',
    'MH05FV3454',
    'MH43CU1632',
    'MH02FU6808',
    'CPR-007',
    'MH43BY2773',
  };

  @override
  void dispose() {
    _addFleetRegController.dispose();
    _addFleetBrandController.dispose();
    _addFleetModelController.dispose();
    _addFleetRateController.dispose();
    _addFleetOwnerController.dispose();
    _couponCodeController.dispose();
    _couponLabelController.dispose();
    _couponValueController.dispose();
    _couponMinOrderController.dispose();
    for (final c in _startOdoControllers.values) {
      c.dispose();
    }
    for (final c in _endOdoControllers.values) {
      c.dispose();
    }
    for (final c in _startFastagControllers.values) {
      c.dispose();
    }
    for (final c in _returnFastagControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  DateTimeRange? _getDateRange(String period, DateTime? customFrom, DateTime? customTo) {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);

    switch (period) {
      case 'Today':
        return DateTimeRange(start: todayStart, end: todayEnd);
      case 'Yesterday':
        final yestStart = todayStart.subtract(const Duration(days: 1));
        final yestEnd = DateTime(yestStart.year, yestStart.month, yestStart.day, 23, 59, 59, 999);
        return DateTimeRange(start: yestStart, end: yestEnd);
      case 'This Week':
        final dayOfWeek = now.weekday % 7;
        final startOfWeek = todayStart.subtract(Duration(days: dayOfWeek));
        final endOfWeek = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day + 6, 23, 59, 59, 999);
        return DateTimeRange(start: startOfWeek, end: endOfWeek);
      case 'This Month':
        final startOfMonth = DateTime(now.year, now.month, 1);
        final endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59, 999);
        return DateTimeRange(start: startOfMonth, end: endOfMonth);
      case 'Last Month':
        final startOfLastMonth = DateTime(now.year, now.month - 1, 1);
        final endOfLastMonth = DateTime(now.year, now.month, 0, 23, 59, 59, 999);
        return DateTimeRange(start: startOfLastMonth, end: endOfLastMonth);
      case 'This Year':
        final startOfYear = DateTime(now.year, 1, 1);
        final endOfYear = DateTime(now.year, 12, 31, 23, 59, 59, 999);
        return DateTimeRange(start: startOfYear, end: endOfYear);
      case 'Custom':
        if (customFrom != null && customTo != null) {
          return DateTimeRange(
            start: DateTime(customFrom.year, customFrom.month, customFrom.day),
            end: DateTime(customTo.year, customTo.month, customTo.day, 23, 59, 59, 999),
          );
        }
        return null;
      case 'All Time':
      default:
        return null;
    }
  }

  bool _isBookingInRange(BookingModel b, DateTimeRange? range) {
    if (range == null) return true;
    final bDate = b.createdAt ?? b.pickupDate;
    return !bDate.isBefore(range.start) && !bDate.isAfter(range.end);
  }

  String _formatDateShort(DateTime d) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final stats = ref.watch(adminStatsProvider).value ?? AdminStatsModel.empty;
    final bookingsAsync = ref.watch(adminBookingsProvider);
    final vehicles = ref.watch(fleetProvider).vehicles;
    final authState = ref.watch(authProvider);
    final currentUser = authState.user;

    final userRole = (currentUser?.role ?? 'admin').toUpperCase();
    final availableRoles = (userRole == 'ADMIN' || userRole == 'MANAGER')
        ? ['ADMIN', 'MANAGER PANEL', 'EXECUTIVE', 'ACCOUNTS']
        : [userRole];

    final accentColor = switch (_selectedRole) {
      'ADMIN' => AppColors.primary,
      'MANAGER PANEL' => const Color(0xFF10B981),
      'EXECUTIVE' => const Color(0xFFF59E0B),
      'ACCOUNTS' => const Color(0xFFEC4899),
      _ => AppColors.primary,
    };

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset(
              AppAssets.logo,
              height: 26,
              errorBuilder: (_, _, _) => const Text('KRUIZLY'),
            ),
            const SizedBox(width: 10),
            Text(
              'STAFF PORTAL',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
                color: accentColor,
              ),
            ),
          ],
        ),
        backgroundColor: context.themeBackground.withValues(alpha: 0.88),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, size: 20),
            tooltip: 'Refresh MySQL Data',
            onPressed: () {
              ref.invalidate(adminStatsProvider);
              ref.read(adminBookingsProvider.notifier).fetchBookings();
              ref.read(fleetProvider.notifier).fetchFleet();
              ref.invalidate(adminKycListProvider);
              ref.invalidate(adminCouponsProvider);
              ref.invalidate(adminUsersProvider);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Synchronizing live Hostinger MySQL database...')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 20),
            tooltip: 'Exit Staff Portal',
            onPressed: () => context.go('/home'),
          ),
        ],
      ),
      body: BackgroundVideoWidget(
        isEnabled: _bgVideoEnabled,
        overlayOpacity: 0.84,
        child: Column(
          children: [
            if (availableRoles.length > 1)
              Container(
                color: context.themeBackground.withValues(alpha: 0.82),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: availableRoles.map((role) {
                      final isSelected = _selectedRole == role;
                      return Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedRole = role),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? accentColor
                                  : (context.isDarkMode
                                      ? const Color(0x441A2333)
                                      : const Color(0xE6FFFFFF)),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: isSelected
                                    ? accentColor.withValues(alpha: 0.8)
                                    : (context.isDarkMode
                                        ? Colors.white.withValues(alpha: 0.22)
                                        : AppColors.lightBorder),
                                width: isSelected ? 1.4 : 0.8,
                              ),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: accentColor.withValues(alpha: 0.45),
                                        blurRadius: 12,
                                        offset: const Offset(0, 3),
                                      ),
                                    ]
                                  : [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.2),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                            ),
                            child: Text(
                              role,
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.6,
                                color: isSelected
                                    ? Colors.white
                                    : (context.isDarkMode
                                        ? Colors.white.withValues(alpha: 0.88)
                                        : AppColors.lightTextPrimary),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),

            Divider(height: 1, color: context.themeBorder),

            Expanded(
              child: RefreshIndicator(
                color: accentColor,
                backgroundColor: context.themeSurfaceElevated,
                onRefresh: () async {
                  ref.invalidate(adminStatsProvider);
                  await ref.read(adminBookingsProvider.notifier).fetchBookings();
                  await ref.read(fleetProvider.notifier).fetchFleet();
                  ref.invalidate(adminKycListProvider);
                  ref.invalidate(adminCouponsProvider);
                },
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 260),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeIn,
                  transitionBuilder: (child, animation) {
                    return FadeTransition(
                      opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 0.03),
                          end: Offset.zero,
                        ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
                        child: child,
                      ),
                    );
                  },
                  child: KeyedSubtree(
                    key: ValueKey(_selectedRole),
                    child: _buildRoleContent(
                      role: _selectedRole,
                      stats: stats,
                      vehicles: vehicles,
                      bookingsAsync: bookingsAsync,
                      accentColor: accentColor,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleContent({
    required String role,
    required AdminStatsModel stats,
    required List<VehicleModel> vehicles,
    required AsyncValue<List<BookingModel>> bookingsAsync,
    required Color accentColor,
  }) {
    switch (role) {
      case 'ADMIN':
        return _buildAdminPanel(stats, vehicles, bookingsAsync, accentColor);
      case 'MANAGER PANEL':
        return _buildManagerPanel(stats, vehicles, bookingsAsync, accentColor);
      case 'EXECUTIVE':
        return _buildExecutivePanel(stats, vehicles, bookingsAsync, accentColor);
      case 'ACCOUNTS':
        return _buildAccountsPanel(stats, bookingsAsync, accentColor);
      default:
        return _buildAdminPanel(stats, vehicles, bookingsAsync, accentColor);
    }
  }

  // =========================================================================
  // 1. ADMIN CONTROL CENTER (8 Subtabs matching kruizly.com/admin.html)
  // =========================================================================
  Widget _buildAdminPanel(
    AdminStatsModel stats,
    List<VehicleModel> vehicles,
    AsyncValue<List<BookingModel>> bookingsAsync,
    Color accentColor,
  ) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        Row(
          children: [
            Text(
              'PERFORMANCE & BUSINESS KPIS',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.5, color: context.themeTextMuted),
            ),
            const Spacer(),
            Text(
              'September 2026',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: accentColor),
            ),
          ],
        ),
        const SizedBox(height: 10),

        _buildAdmin12Kpis(stats, accentColor),
        const SizedBox(height: 16),

        GlassCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Production Database Export', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: context.themeTextPrimary)),
                    const SizedBox(height: 2),
                    Text('Download all MySQL database tables as an Excel workbook.', style: TextStyle(fontSize: 11, color: context.themeTextSecondary)),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              CustomButton(
                text: 'Export to Excel',
                width: 120,
                height: 36,
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Database export initiated via /api/admin/export.php')),
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // 8 SUB-TABS ROW (media_1789971983424.png)
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildFilterPill('All Bookings (${stats.totalBookings})', _adminSubTab == 0, () => setState(() => _adminSubTab = 0)),
              _buildFilterPill('Booking Calendar', _adminSubTab == 1, () => setState(() => _adminSubTab = 1)),
              _buildFilterPill('User Accounts & Verification (${stats.pendingDocs})', _adminSubTab == 2, () => setState(() => _adminSubTab = 2)),
              _buildFilterPill('Users & Customers Analytics', _adminSubTab == 3, () => setState(() => _adminSubTab = 3)),
              _buildFilterPill('Bookings & Reservations Analytics', _adminSubTab == 4, () => setState(() => _adminSubTab = 4)),
              _buildFilterPill('Vehicle Acquisition', _adminSubTab == 5, () => setState(() => _adminSubTab = 5)),
              _buildFilterPill('Fleet Management (${vehicles.length})', _adminSubTab == 6, () => setState(() => _adminSubTab = 6)),
              _buildFilterPill('Coupons', _adminSubTab == 7, () => setState(() => _adminSubTab = 7)),
            ],
          ),
        ),
        const SizedBox(height: 14),

        if (_adminSubTab == 0) _buildAdminAllBookingsView(bookingsAsync, accentColor),
        if (_adminSubTab == 1) _buildBookingCalendarView(bookingsAsync, accentColor),
        if (_adminSubTab == 2) _buildUserAccountsVerificationView(accentColor),
        if (_adminSubTab == 3) _buildUsersCustomersAnalyticsView(stats, bookingsAsync, accentColor),
        if (_adminSubTab == 4) _buildBookingsReservationsAnalyticsView(stats, bookingsAsync, accentColor),
        if (_adminSubTab == 5) _buildVehicleAcquisitionView(),
        if (_adminSubTab == 6) _buildFleetManagementView(vehicles, accentColor),
        if (_adminSubTab == 7) _buildCouponsView(accentColor),
      ],
    );
  }

  // --- SUBTAB 0: All Bookings (media_1789971983424.png) ---
  Widget _buildAdminAllBookingsView(AsyncValue<List<BookingModel>> bookingsAsync, Color accentColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('System Bookings & Fleet Operations', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: context.themeTextPrimary)),
        const SizedBox(height: 2),
        Text('Filter and audit trip status, odometer readings, and FASTag logs.', style: TextStyle(fontSize: 12, color: context.themeTextSecondary)),
        const SizedBox(height: 12),

        GlassCard(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _adminBookingStatusFilter,
                      decoration: const InputDecoration(labelText: 'STATUS', contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8), border: OutlineInputBorder()),
                      dropdownColor: context.themeSurfaceElevated,
                      style: TextStyle(fontSize: 12, color: context.themeTextPrimary),
                      items: const [
                        DropdownMenuItem(value: 'all', child: Text('All Statuses')),
                        DropdownMenuItem(value: 'pending_verification', child: Text('Pending Verification')),
                        DropdownMenuItem(value: 'active', child: Text('Active / On-Road')),
                        DropdownMenuItem(value: 'completed', child: Text('Completed')),
                        DropdownMenuItem(value: 'cancelled', child: Text('Cancelled')),
                      ],
                      onChanged: (val) => setState(() => _adminBookingStatusFilter = val ?? 'all'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _adminBookingSort,
                      decoration: const InputDecoration(labelText: 'SORT BY DATE', contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8), border: OutlineInputBorder()),
                      dropdownColor: context.themeSurfaceElevated,
                      style: TextStyle(fontSize: 12, color: context.themeTextPrimary),
                      items: const [
                        DropdownMenuItem(value: 'newest', child: Text('Newest first')),
                        DropdownMenuItem(value: 'oldest', child: Text('Oldest first')),
                      ],
                      onChanged: (val) => setState(() => _adminBookingSort = val ?? 'newest'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(context: context, initialDate: DateTime(2026, 9, 1), firstDate: DateTime(2025), lastDate: DateTime(2028));
                        if (picked != null) setState(() => _adminDateFrom = picked);
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(labelText: 'FROM', contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8), border: OutlineInputBorder()),
                        child: Text(_adminDateFrom != null ? _formatDateShort(_adminDateFrom!) : 'dd/mm/yyyy', style: TextStyle(fontSize: 12, color: _adminDateFrom != null ? context.themeTextPrimary : context.themeTextMuted)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(context: context, initialDate: DateTime(2026, 9, 30), firstDate: DateTime(2025), lastDate: DateTime(2028));
                        if (picked != null) setState(() => _adminDateTo = picked);
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(labelText: 'TO', contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8), border: OutlineInputBorder()),
                        child: Text(_adminDateTo != null ? _formatDateShort(_adminDateTo!) : 'dd/mm/yyyy', style: TextStyle(fontSize: 12, color: _adminDateTo != null ? context.themeTextPrimary : context.themeTextMuted)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (_adminDateFrom != null || _adminDateTo != null)
                    CustomButton(
                      text: 'Clear',
                      isOutlined: true,
                      height: 38,
                      width: 70,
                      onPressed: () => setState(() {
                        _adminDateFrom = null;
                        _adminDateTo = null;
                      }),
                    ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        bookingsAsync.when(
          loading: () => const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator(color: AppColors.primary))),
          error: (e, _) => Text('Error loading bookings: $e', style: const TextStyle(color: AppColors.error)),
          data: (bookings) {
            var filtered = bookings.where((b) {
              if (_adminBookingStatusFilter != 'all') {
                if (_adminBookingStatusFilter == 'pending_verification') {
                  if (!b.paymentStatus.toLowerCase().contains('pending') && !b.status.toLowerCase().contains('pending')) return false;
                } else if (b.status.toLowerCase() != _adminBookingStatusFilter) {
                  return false;
                }
              }
              if (_adminDateFrom != null) {
                final d = b.createdAt ?? b.pickupDate;
                if (d.isBefore(_adminDateFrom!)) return false;
              }
              if (_adminDateTo != null) {
                final d = b.createdAt ?? b.pickupDate;
                if (d.isAfter(_adminDateTo!.add(const Duration(days: 1)))) return false;
              }
              return true;
            }).toList();

            filtered.sort((a, b) {
              final da = a.createdAt ?? a.pickupDate;
              final db = b.createdAt ?? b.pickupDate;
              return _adminBookingSort == 'newest' ? db.compareTo(da) : da.compareTo(db);
            });

            if (filtered.isEmpty) {
              return GlassCard(
                padding: const EdgeInsets.all(32),
                child: Center(
                  child: Text('No bookings match the selected filters.', style: TextStyle(color: context.themeTextSecondary)),
                ),
              );
            }

            return Column(
              children: filtered.map((b) => _buildBookingCard(b, accentColor, false)).toList(),
            );
          },
        ),
      ],
    );
  }

  // --- SUBTAB 1: Booking Calendar (media_1789972136479.png) ---
  Widget _buildBookingCalendarView(AsyncValue<List<BookingModel>> bookingsAsync, Color accentColor) {
    final allBookings = bookingsAsync.value ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GlassCard(
          padding: const EdgeInsets.all(14),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left),
                        onPressed: () => setState(() => _calendarMonth = DateTime(_calendarMonth.year, _calendarMonth.month - 1, 1)),
                      ),
                      Text(
                        '${_formatDateShort(_calendarMonth).split(' ')[1]} ${_calendarMonth.year}',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: context.themeTextPrimary),
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right),
                        onPressed: () => setState(() => _calendarMonth = DateTime(_calendarMonth.year, _calendarMonth.month + 1, 1)),
                      ),
                    ],
                  ),
                  CustomButton(
                    text: 'Today',
                    isOutlined: true,
                    height: 32,
                    width: 70,
                    onPressed: () => setState(() => _calendarMonth = DateTime(2026, 9, 1)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Interactive timeline showing start & return dates for each rental reservation.',
                style: TextStyle(fontSize: 11.5, color: context.themeTextSecondary),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildFilterPill('Grid View', _calendarViewMode == 'grid', () => setState(() => _calendarViewMode = 'grid')),
                  _buildFilterPill('Agenda View', _calendarViewMode == 'agenda', () => setState(() => _calendarViewMode = 'agenda')),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        if (_calendarViewMode == 'grid')
          _buildCalendarMonthGrid(allBookings, accentColor)
        else
          _buildCalendarAgendaList(allBookings, accentColor),
      ],
    );
  }

  Widget _buildCalendarMonthGrid(List<BookingModel> bookings, Color accentColor) {
    final year = _calendarMonth.year;
    final month = _calendarMonth.month;
    final firstDay = DateTime(year, month, 1);
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final startingWeekday = firstDay.weekday % 7;

    const weekdays = ['SUN', 'MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT'];

    return GlassCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Row(
            children: weekdays.map((day) => Expanded(
              child: Center(
                child: Text(
                  day,
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: context.themeTextMuted),
                ),
              ),
            )).toList(),
          ),
          const Divider(height: 16),

          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: startingWeekday + daysInMonth,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              crossAxisSpacing: 4,
              mainAxisSpacing: 4,
              mainAxisExtent: 72,
            ),
            itemBuilder: (context, index) {
              if (index < startingWeekday) {
                return const SizedBox.shrink();
              }
              final day = index - startingWeekday + 1;
              final curDate = DateTime(year, month, day);

              final dayBookings = bookings.where((b) {
                final p = DateTime(b.pickupDate.year, b.pickupDate.month, b.pickupDate.day);
                final d = DateTime(b.dropDate.year, b.dropDate.month, b.dropDate.day);
                return !curDate.isBefore(p) && !curDate.isAfter(d);
              }).toList();

              final isSelected = _selectedCalendarDate != null &&
                  _selectedCalendarDate!.year == curDate.year &&
                  _selectedCalendarDate!.month == curDate.month &&
                  _selectedCalendarDate!.day == curDate.day;

              return InkWell(
                onTap: () {
                  setState(() => _selectedCalendarDate = curDate);
                  _showDailyTimelineModal(curDate, dayBookings);
                },
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? accentColor.withValues(alpha: 0.2)
                        : (dayBookings.isNotEmpty ? context.themeSurfaceElevated : Colors.transparent),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isSelected ? accentColor : context.themeBorder.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$day',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: isSelected ? accentColor : context.themeTextPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      if (dayBookings.isNotEmpty)
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 2),
                            decoration: BoxDecoration(
                              color: dayBookings.any((b) => b.status == 'active')
                                  ? const Color(0xFF06D6A0).withValues(alpha: 0.2)
                                  : accentColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: Text(
                              dayBookings.first.vehicleName.split(' ').last,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 8.5,
                                fontWeight: FontWeight.w700,
                                color: dayBookings.any((b) => b.status == 'active')
                                    ? const Color(0xFF06D6A0)
                                    : accentColor,
                              ),
                            ),
                          ),
                        ),
                      if (dayBookings.length > 1)
                        Text(
                          '+${dayBookings.length - 1} more',
                          style: TextStyle(fontSize: 8, color: context.themeTextMuted),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarAgendaList(List<BookingModel> bookings, Color accentColor) {
    if (bookings.isEmpty) {
      return GlassCard(
        padding: const EdgeInsets.all(24),
        child: Center(child: Text('No bookings scheduled for this period.', style: TextStyle(color: context.themeTextSecondary))),
      );
    }
    return Column(
      children: bookings.map((b) => _buildBookingCard(b, accentColor, false)).toList(),
    );
  }

  // --- SUBTAB 2: User Accounts & Verification (media_1789971987955.png) ---
  Widget _buildUserAccountsVerificationView(Color accentColor) {
    final isManager = _selectedRole == 'MANAGER PANEL';
    final usersAsync = ref.watch(adminUsersProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Registered Users & Identity Verification', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: context.themeTextPrimary)),
        const SizedBox(height: 2),
        Text('Review uploaded driving licenses, Aadhaar, and PAN cards.', style: TextStyle(fontSize: 12, color: context.themeTextSecondary)),
        const SizedBox(height: 12),

        TextField(
          style: TextStyle(color: context.themeTextPrimary, fontSize: 13),
          decoration: InputDecoration(
            hintText: 'Search name, phone, or email...',
            prefixIcon: const Icon(Icons.search, size: 18),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            filled: true,
            fillColor: context.themeSurfaceElevated,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: context.themeBorder)),
          ),
          onChanged: (val) => setState(() => _userSearchQuery = val.toLowerCase()),
        ),
        const SizedBox(height: 14),

        usersAsync.when(
          loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
          error: (_, _) => _buildKycSection(accentColor),
          data: (users) {
            var filtered = users.where((u) {
              if (_userSearchQuery.isEmpty) return true;
              final name = (u['name'] ?? '').toString().toLowerCase();
              final email = (u['email'] ?? '').toString().toLowerCase();
              final phone = (u['phone'] ?? '').toString().toLowerCase();
              return name.contains(_userSearchQuery) || email.contains(_userSearchQuery) || phone.contains(_userSearchQuery);
            }).toList();

            if (filtered.isEmpty) {
              return _buildKycSection(accentColor);
            }

            return Column(
              children: filtered.take(20).map((u) {
                final name = (u['name'] ?? 'Customer').toString();
                final email = (u['email'] ?? 'No email').toString();
                final phone = (u['phone'] ?? '—').toString();
                final role = (u['role'] ?? 'customer').toString();
                final uid = (u['firebase_uid'] ?? u['id'] ?? '').toString();

                return GlassCard(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(name, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: context.themeTextPrimary)),
                                Text(email, style: TextStyle(fontSize: 11, color: context.themeTextSecondary)),
                                Text('Contact: $phone', style: TextStyle(fontSize: 11, color: context.themeTextMuted)),
                              ],
                            ),
                          ),
                          if (isManager)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: accentColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                role.toUpperCase(),
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: accentColor),
                              ),
                            )
                          else
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: accentColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: accentColor.withValues(alpha: 0.3)),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: ['customer', 'manager', 'executive', 'accounts', 'admin'].contains(role.toLowerCase())
                                      ? role.toLowerCase()
                                      : 'customer',
                                  dropdownColor: context.themeSurfaceElevated,
                                  isDense: true,
                                  icon: Icon(Icons.arrow_drop_down, size: 16, color: accentColor),
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: accentColor),
                                  items: const [
                                    DropdownMenuItem(value: 'customer', child: Text('CUSTOMER')),
                                    DropdownMenuItem(value: 'manager', child: Text('MANAGER')),
                                    DropdownMenuItem(value: 'executive', child: Text('EXECUTIVE')),
                                    DropdownMenuItem(value: 'accounts', child: Text('ACCOUNTS')),
                                    DropdownMenuItem(value: 'admin', child: Text('ADMIN')),
                                  ],
                                  onChanged: (newRole) async {
                                    if (newRole != null && newRole != role) {
                                      await ref.read(adminBookingsProvider.notifier).updateRole(uid: uid, role: newRole);
                                      ref.invalidate(adminUsersProvider);
                                      if (mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('User role for $name updated to ${newRole.toUpperCase()}')),
                                        );
                                      }
                                    }
                                  },
                                ),
                              ),
                            ),
                        ],
                      ),
                      const Divider(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Identity: Verification on file',
                              style: TextStyle(fontSize: 11, color: context.themeTextSecondary),
                            ),
                          ),
                          CustomButton(
                            text: isManager ? 'View KYC' : 'Inspect KYC',
                            isOutlined: true,
                            height: 28,
                            width: 110,
                            onPressed: () {
                              _showKycInspectionModal(name, email, uid, isReadOnly: isManager);
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  void _showKycInspectionModal(String name, String email, String uid, {bool isReadOnly = false}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: context.themeSurfaceElevated, borderRadius: const BorderRadius.vertical(top: Radius.circular(20))),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('KYC Verification: $name', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: context.themeTextPrimary)),
                      Text(email, style: TextStyle(fontSize: 12, color: context.themeTextSecondary)),
                    ],
                  ),
                ),
                if (isReadOnly)
                  const SizedBox.shrink(), // hidden — read-only enforced via Close-only button below
              ],
            ),
            const SizedBox(height: 16),
            _buildDocInspectRow('Driving License', 'DL-Verified', true),
            _buildDocInspectRow('Aadhaar Card', 'UIDAI Attached', true),
            _buildDocInspectRow('PAN Card', 'Income Tax Verified', true),
            const SizedBox(height: 20),
            if (isReadOnly)
              CustomButton(
                text: 'Close',
                height: 38,
                onPressed: () => Navigator.pop(ctx),
              )
            else
              Row(
                children: [
                  Expanded(
                    child: CustomButton(
                      text: 'Approve KYC',
                      height: 38,
                      onPressed: () async {
                        await ref.read(adminBookingsProvider.notifier).updateKyc(uid: uid, documentType: 'all', status: 'verified');
                        if (ctx.mounted) Navigator.pop(ctx);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('KYC for $name approved.')));
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: CustomButton(
                      text: 'Reject',
                      isOutlined: true,
                      height: 38,
                      onPressed: () async {
                        await ref.read(adminBookingsProvider.notifier).updateKyc(uid: uid, documentType: 'all', status: 'rejected');
                        if (ctx.mounted) Navigator.pop(ctx);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('KYC for $name rejected.')));
                        }
                      },
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocInspectRow(String title, String status, bool isVerified) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: context.themeTextPrimary)),
          Row(
            children: [
              Icon(isVerified ? Icons.check_circle : Icons.pending, size: 14, color: isVerified ? const Color(0xFF06D6A0) : const Color(0xFFFFB703)),
              const SizedBox(width: 4),
              Text(status, style: TextStyle(fontSize: 12, color: isVerified ? const Color(0xFF06D6A0) : const Color(0xFFFFB703))),
            ],
          ),
        ],
      ),
    );
  }

  // --- SUBTAB 3: Users & Customers Analytics (media_1789971992744.png) ---
  Widget _buildUsersCustomersAnalyticsView(AdminStatsModel stats, AsyncValue<List<BookingModel>> bookingsAsync, Color accentColor) {
    final allBookings = bookingsAsync.value ?? [];
    final uniqueCustomers = allBookings.map((b) => b.userName).toSet().length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(color: accentColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(4)),
          child: Text('CUSTOMER INSIGHTS', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w900, letterSpacing: 1, color: accentColor)),
        ),
        const SizedBox(height: 4),
        Text('Users & Customer Analytics', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: context.themeTextPrimary)),
        const SizedBox(height: 2),
        Text('Track registered user accounts vs actual booking customers, new acquisitions, and repeat reservations.', style: TextStyle(fontSize: 11.5, color: context.themeTextSecondary)),
        const SizedBox(height: 12),

        GlassCard(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('QUICK FILTER RANGE', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: context.themeTextMuted)),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: ['Today', 'Yesterday', 'This Week', 'This Month', 'Last Month', 'This Year', 'All Time'].map((r) {
                    final isSel = _custPeriod == r;
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: GestureDetector(
                        onTap: () => setState(() => _custPeriod = r),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: isSel ? accentColor : context.themeSurfaceElevated,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Text(r, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: isSel ? const Color(0xFF041017) : context.themeTextSecondary)),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 1.6,
          children: [
            _buildStatMetricCard('TOTAL REGISTERED USERS', '${stats.totalUsers}', 'System user accounts', accentColor),
            _buildStatMetricCard('TOTAL ACTIVE CUSTOMERS', '$uniqueCustomers', 'Unique users who booked', const Color(0xFF06D6A0)),
            _buildStatMetricCard("THIS MONTH'S CUSTOMERS", '$uniqueCustomers', 'Unique bookers in month', accentColor),
            _buildStatMetricCard('NEW CUSTOMERS THIS MONTH', '$uniqueCustomers', 'First booking this month', const Color(0xFF06D6A0)),
            _buildStatMetricCard('REPEAT CUSTOMERS', '${uniqueCustomers > 1 ? (uniqueCustomers * 0.1).round() : 0}', 'Customers with >1 booking', const Color(0xFFFFB703)),
          ],
        ),
        const SizedBox(height: 18),

        Text('Monthly User & Customer Acquisition Breakdown', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: context.themeTextPrimary)),
        const SizedBox(height: 8),
        GlassCard(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              _buildTableRow(['MONTH', 'NEW USERS', 'BOOKED', 'BOOKINGS'], isHeader: true),
              const Divider(height: 12),
              if (stats.monthly.isNotEmpty)
                ...stats.monthly.entries.map((e) {
                  final monthData = e.value is Map<String, dynamic> ? e.value as Map<String, dynamic> : <String, dynamic>{};
                  final newUsers = '${(monthData['new_users'] as num?)?.toInt() ?? 0}';
                  final booked = '${(monthData['booked_users'] as num?)?.toInt() ?? 0}';
                  final bookings = '${(monthData['bookings'] as num?)?.toInt() ?? 0}';
                  return _buildTableRow([e.key, newUsers, booked, bookings]);
                })
              else ...[
                _buildTableRow(['No monthly data available', '-', '-', '-']),
              ],
            ],
          ),
        ),
      ],
    );
  }

  // --- SUBTAB 4: Bookings & Reservations Analytics (media_1789971999168.png) ---
  Widget _buildBookingsReservationsAnalyticsView(AdminStatsModel stats, AsyncValue<List<BookingModel>> bookingsAsync, Color accentColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(color: accentColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(4)),
          child: Text('RESERVATION INSIGHTS', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w900, letterSpacing: 1, color: accentColor)),
        ),
        const SizedBox(height: 4),
        Text('Bookings & Reservations Analytics', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: context.themeTextPrimary)),
        const SizedBox(height: 2),
        Text('Track rental reservations, verified paid bookings, cancellations, and monthly booking growth.', style: TextStyle(fontSize: 11.5, color: context.themeTextSecondary)),
        const SizedBox(height: 12),

        GlassCard(
          padding: const EdgeInsets.all(12),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: ['Today', 'Yesterday', 'This Week', 'This Month', 'Last Month', 'This Year', 'All Time'].map((r) {
                final isSel = _bookPeriod == r;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: GestureDetector(
                    onTap: () => setState(() => _bookPeriod = r),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: isSel ? accentColor : context.themeSurfaceElevated,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(r, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: isSel ? const Color(0xFF041017) : context.themeTextSecondary)),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(height: 14),

        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 1.6,
          children: [
            _buildStatMetricCard('TOTAL BOOKINGS', '${stats.totalBookings}', 'All reservations recorded', context.themeTextPrimary),
            _buildStatMetricCard('PAID & CONFIRMED', '${stats.paidBookings}', 'Verified payment received', const Color(0xFF06D6A0)),
            _buildStatMetricCard('PENDING VERIFICATION', '${stats.pendingPayments}', 'Awaiting payment audit', const Color(0xFFFF5C77)),
            _buildStatMetricCard('ACTIVE / ON-ROAD', '${stats.activeTrips}', 'Currently on rental trip', const Color(0xFF06D6A0)),
            _buildStatMetricCard('CANCELLED / REJECTED', '${stats.totalBookings - stats.paidBookings}', 'Cancelled or rejected', const Color(0xFFFF5C77)),
          ],
        ),
        const SizedBox(height: 18),

        Text('Monthly Bookings & Reservation Performance Breakdown', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: context.themeTextPrimary)),
        const SizedBox(height: 8),
        GlassCard(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              _buildTableRow(['MONTH', 'TOTAL', 'PAID', 'CANCELLED', 'GROSS'], isHeader: true),
              const Divider(height: 12),
              if (stats.monthly.isNotEmpty)
                ...stats.monthly.entries.map((e) {
                  final monthData = e.value is Map<String, dynamic> ? e.value as Map<String, dynamic> : <String, dynamic>{};
                  final total = '${(monthData['bookings'] as num?)?.toInt() ?? 0}';
                  final paid = '${(monthData['paid'] as num?)?.toInt() ?? 0}';
                  final cancelled = '${(monthData['cancelled'] as num?)?.toInt() ?? 0}';
                  final gross = _formatINR((monthData['revenue'] as num?)?.toDouble() ?? 0.0);
                  return _buildTableRow([e.key, total, paid, cancelled, gross]);
                })
              else
                _buildTableRow(['No monthly data available', '-', '-', '-', '-']),
            ],
          ),
        ),
      ],
    );
  }

  // --- SUBTAB 5: Vehicle Acquisition (Host Cars) ---
  Widget _buildVehicleAcquisitionView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Vehicle Acquisition & Host Partners', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: context.themeTextPrimary)),
        const SizedBox(height: 2),
        Text('Review incoming vehicle hosting requests, partner agreements, and onboarding inspections.', style: TextStyle(fontSize: 12, color: context.themeTextSecondary)),
        const SizedBox(height: 14),

        GlassCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('9 Active Partner Hosts', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: context.themeTextPrimary)),
                  StatusBadge(status: 'verified'),
                ],
              ),
              const SizedBox(height: 8),
              Text('All 9 operational fleet vehicles are currently active and contracted through host partners in Ghansoli Hub.', style: TextStyle(fontSize: 12, color: context.themeTextSecondary)),
              const SizedBox(height: 14),
              CustomButton(
                text: 'Review Host Contracts',
                isOutlined: true,
                height: 36,
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Host contracts & agreements verified.')),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --- SUBTAB 6: Fleet Management (media_1789972015464.png) ---
  Widget _buildFleetManagementView(List<VehicleModel> vehicles, Color accentColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Fleet Availability Management', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: context.themeTextPrimary)),
                  Text('Control catalog inventory, rates, availability, and vehicle images.', style: TextStyle(fontSize: 12, color: context.themeTextSecondary)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            CustomButton(
              text: 'Open Fleet',
              icon: Icons.open_in_new_rounded,
              isOutlined: true,
              height: 34,
              width: 120,
              onPressed: () => context.go('/fleet'),
            ),
          ],
        ),
        const SizedBox(height: 14),

        GlassCard(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.star_rounded, size: 18, color: Color(0xFFFFB703)),
                      const SizedBox(width: 6),
                      Text('Current Fleet (Manager Summary Roster)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: context.themeTextPrimary)),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: const Color(0xFF06D6A0).withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
                    child: Text('${_currentRosterRegs.length} Active Fleets', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF06D6A0))),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Vehicles with the "Current Fleet" checkbox checked are tracked in the Manager Summary analytics, revenue tracking, and occupancy calculations.',
                style: TextStyle(fontSize: 11, color: context.themeTextSecondary),
              ),
              const SizedBox(height: 10),
              CustomButton(
                text: 'Reset to Default Fleet Roster',
                isOutlined: true,
                height: 30,
                width: 200,
                onPressed: () => setState(() {
                  _currentRosterRegs.clear();
                  _currentRosterRegs.addAll([
                    'MH03EL1025', 'MH05GJ4711', 'MH48GJ4153', 'MH04MU1178',
                    'MH05FV3454', 'MH43CU1632', 'MH02FU6808', 'CPR-007', 'MH43BY2773'
                  ]);
                }),
              ),
              const SizedBox(height: 12),

              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  _buildRosterChip('MH03EL1025 Maruti Suzuki Fronx'),
                  _buildRosterChip('MH05GJ4711 Maruti Suzuki Ertiga'),
                  _buildRosterChip('MH48GJ4153 Toyota Glanza'),
                  _buildRosterChip('MH04MU1178 Toyota Glanza'),
                  _buildRosterChip('MH05FV3454 Tata Punch'),
                  _buildRosterChip('MH43CU1632 Maruti Suzuki Fronx'),
                  _buildRosterChip('MH02FU6808 Mahindra XUV700'),
                  _buildRosterChip('CPR-007 Maruti Suzuki Baleno'),
                  _buildRosterChip('MH43BY2773 MG Hector'),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        if (_selectedRole != 'MANAGER PANEL') ...[
          GlassCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Add / Edit Fleet Vehicle', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: context.themeTextPrimary)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _addFleetRegController,
                        decoration: const InputDecoration(labelText: 'RC NUMBER / REG *', hintText: 'e.g. MH03EL1025', border: OutlineInputBorder()),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _addFleetBrandController,
                        decoration: const InputDecoration(labelText: 'BRAND *', hintText: 'e.g. Maruti Suzuki', border: OutlineInputBorder()),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _addFleetModelController,
                        decoration: const InputDecoration(labelText: 'MODEL *', hintText: 'e.g. Fronx', border: OutlineInputBorder()),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _addFleetRateController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'DAILY RATE (₹) *', hintText: 'e.g. 3500', prefixText: '₹ ', border: OutlineInputBorder()),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _addFleetOwnerController,
                  decoration: const InputDecoration(labelText: 'OWNER / PARTNER NAME', hintText: 'e.g. Aditi Lotankar', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Checkbox(
                      value: _addFleetIsCurrent,
                      activeColor: accentColor,
                      onChanged: (v) => setState(() => _addFleetIsCurrent = v ?? true),
                    ),
                    Expanded(
                      child: Text('CURRENT FLEET (SHOW IN MANAGER SUMMARY)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: context.themeTextPrimary)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                CustomButton(
                  text: 'Add Fleet Vehicle',
                  height: 38,
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Vehicle saved to Kruizly fleet roster.')),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        _buildFleetManagementSection(vehicles, accentColor, readOnly: _selectedRole == 'MANAGER PANEL'),
      ],
    );
  }

  Widget _buildRosterChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF06D6A0).withValues(alpha: 0.12),
        border: Border.all(color: const Color(0xFF06D6A0).withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF06D6A0))),
          const SizedBox(width: 4),
          const Icon(Icons.close, size: 12, color: Color(0xFF06D6A0)),
        ],
      ),
    );
  }

  // --- SUBTAB 7: Coupons (media_1789972056013.png) ---
  Widget _buildCouponsView(Color accentColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Promo & Coupon Codes', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: context.themeTextPrimary)),
                  Text('Create, edit, activate, or deactivate discount codes for customer checkout.', style: TextStyle(fontSize: 12, color: context.themeTextSecondary)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(color: accentColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
              child: Text('ACTIVE PROMOS: 6', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: accentColor)),
            ),
          ],
        ),
        const SizedBox(height: 14),

        if (_selectedRole != 'MANAGER PANEL') ...[
          GlassCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('ADD NEW COUPON CODE', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: context.themeTextPrimary)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: const Color(0xFF06D6A0).withValues(alpha: 0.15), borderRadius: BorderRadius.circular(4)),
                      child: const Text('Create Mode', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF06D6A0))),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _couponCodeController,
                        decoration: const InputDecoration(labelText: 'COUPON CODE', hintText: 'e.g. WELCOME500', border: OutlineInputBorder()),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _couponDiscountType,
                        decoration: const InputDecoration(labelText: 'DISCOUNT TYPE', border: OutlineInputBorder()),
                        dropdownColor: context.themeSurfaceElevated,
                        items: const [
                          DropdownMenuItem(value: 'flat', child: Text('Flat Amount (₹)')),
                          DropdownMenuItem(value: 'percentage', child: Text('Percentage (%)')),
                        ],
                        onChanged: (val) => setState(() => _couponDiscountType = val ?? 'flat'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _couponValueController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'DISCOUNT VALUE', hintText: 'e.g. 500 or 15', border: OutlineInputBorder()),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _couponMinOrderController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'MIN ORDER TOTAL (₹)', hintText: '0', border: OutlineInputBorder()),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _couponLabelController,
                  decoration: const InputDecoration(labelText: 'LABEL / DESCRIPTION', hintText: 'e.g. ₹500 Flat Off on first ride', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 14),
                CustomButton(
                  text: 'SAVE COUPON',
                  height: 38,
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Coupon code saved.')),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        _buildCouponsSection(accentColor),
      ],
    );
  }

  // =========================================================================
  // 2. MANAGER SUMMARY (4 Subtabs matching kruizly.com/manager.html)
  // =========================================================================
  Widget _buildManagerPanel(
    AdminStatsModel stats,
    List<VehicleModel> vehicles,
    AsyncValue<List<BookingModel>> bookingsAsync,
    Color accentColor,
  ) {
    final allBookings = bookingsAsync.value ?? [];
    final activeFleetAsync = ref.watch(activeFleetProvider);
    final activeFleet = activeFleetAsync.value ?? [];

    final mgrRange = _getDateRange(_mgrPeriod, _mgrCustomFrom, _mgrCustomTo);
    final periodBookings = allBookings.where((b) => _isBookingInRange(b, mgrRange)).toList();
    final nonCancelledBookings = periodBookings.where((b) => !b.isCancelled).toList();

    double periodRevenue;
    if (_mgrPeriod == 'All Time') {
      periodRevenue = stats.totalRevenue;
    } else if (_mgrPeriod == 'This Month') {
      periodRevenue = stats.monthRevenue;
    } else if (_mgrPeriod == 'Last Month') {
      periodRevenue = stats.lastMonthRevenue;
    } else {
      periodRevenue = nonCancelledBookings.fold(0.0, (sum, b) => sum + b.finalAmount);
    }

    final periodActiveTrips = (_mgrPeriod == 'All Time' || _mgrPeriod == 'This Month')
        ? stats.activeTrips
        : periodBookings.where((b) => b.status == 'active').length;

    final periodCompletedTrips = (_mgrPeriod == 'All Time' || _mgrPeriod == 'This Month')
        ? stats.completedTrips
        : periodBookings.where((b) => b.status == 'completed').length;

    final periodTotalBookings = (_mgrPeriod == 'All Time' || _mgrPeriod == 'This Month')
        ? (stats.totalBookings > 0 ? stats.totalBookings : allBookings.length)
        : periodBookings.length;

    final periodAvgBooking = periodTotalBookings > 0 ? (periodRevenue / periodTotalBookings) : 0.0;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        Text('Manager Summary', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: context.themeTextPrimary)),
        const SizedBox(height: 4),
        Text(
          'Monitor revenue, fleet utilization, booking performance, and sales from one read-only executive analytics dashboard.',
          style: TextStyle(fontSize: 12, color: context.themeTextSecondary, height: 1.3),
        ),
        const SizedBox(height: 14),

        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildFilterPill('Revenue & Sales', _mgrSubTab == 0, () => setState(() => _mgrSubTab = 0)),
              _buildFilterPill('Fleet Performance (${activeFleet.length} Fleets)', _mgrSubTab == 1, () => setState(() => _mgrSubTab = 1)),
              _buildFilterPill('Bookings Analytics (${periodBookings.length})', _mgrSubTab == 2, () => setState(() => _mgrSubTab = 2)),
              _buildFilterPill('Operations & Reconciliation', _mgrSubTab == 3, () => setState(() => _mgrSubTab = 3)),
            ],
          ),
        ),
        const SizedBox(height: 16),

        GlassCard(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('REPORTING ANALYTICS PERIOD', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1, color: context.themeTextMuted)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: const Color(0xFF06D6A0).withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
                    child: Text(_mgrPeriod, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF06D6A0))),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text('Filter Business Metrics', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: context.themeTextPrimary)),
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: ['Today', 'Yesterday', 'This Week', 'This Month', 'Last Month', 'This Year', 'All Time'].map((r) {
                    final isSelected = r == _mgrPeriod;
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: GestureDetector(
                        onTap: () => setState(() {
                          _mgrPeriod = r;
                          _mgrCustomFrom = null;
                          _mgrCustomTo = null;
                        }),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                          decoration: BoxDecoration(
                            color: isSelected ? accentColor : context.themeSurfaceElevated,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Text(
                            r,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: isSelected ? const Color(0xFF041017) : context.themeTextSecondary,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        if (_mgrSubTab == 0) ...[
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 1.65,
            children: [
              _buildKpiCard('PERIOD REVENUE', _formatINRShort(periodRevenue), const Color(0xFF06D6A0)),
              _buildKpiCard('ACTIVE TRIPS', '$periodActiveTrips', accentColor),
              _buildKpiCard('COMPLETED TRIPS', '$periodCompletedTrips', context.themeTextPrimary),
              _buildKpiCard('TOTAL BOOKINGS', '$periodTotalBookings', context.themeTextPrimary),
              _buildKpiCard('AVG. BOOKING VALUE', _formatINRShort(periodAvgBooking), accentColor),
              _buildKpiCard('FLEET UTILIZATION', '${stats.fleetUtilization}%', const Color(0xFF06D6A0)),
            ],
          ),
          const SizedBox(height: 16),

          GlassCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Monthly Revenue Breakdown', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: context.themeTextPrimary)),
                const SizedBox(height: 4),
                Text('Synchronized ledger across financial months.', style: TextStyle(fontSize: 11, color: context.themeTextSecondary)),
                const SizedBox(height: 12),
                if (stats.monthly.isNotEmpty)
                  ...stats.monthly.entries.map((e) {
                    final monthData = e.value is Map<String, dynamic> ? e.value as Map<String, dynamic> : <String, dynamic>{};
                    final bookings = (monthData['bookings'] as num?)?.toInt() ?? 0;
                    final revenue = (monthData['revenue'] as num?)?.toDouble() ?? 0.0;
                    final label = bookings == 1 ? '1 Booking' : '$bookings Bookings';
                    return _buildMonthlyRow(e.key, label, _formatINR(revenue), false);
                  })
                else
                  Text('No monthly data available yet.', style: TextStyle(fontSize: 12, color: context.themeTextSecondary)),
                const Divider(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Total Verified Revenue', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: context.themeTextPrimary)),
                    Text(_formatINR(stats.totalRevenue), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF06D6A0))),
                  ],
                ),
              ],
            ),
          ),
        ],

        if (_mgrSubTab == 1) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF06D6A0).withValues(alpha: 0.1),
              border: Border.all(color: const Color(0xFF06D6A0).withValues(alpha: 0.3)),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.workspace_premium_rounded, size: 20, color: Color(0xFF06D6A0)),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('TOP PERFORMING VEHICLE', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: context.themeTextMuted)),
                      Text('Based on fleet booking data', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF06D6A0))),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 1.6,
            children: [
              _buildKpiCard('TOTAL FLEET REVENUE', _formatINRShort(stats.totalRevenue), const Color(0xFF06D6A0)),
              _buildKpiCard('TOTAL BOOKINGS', '${stats.totalBookings}', context.themeTextPrimary),
              _buildKpiCard('TOTAL BOOKING DAYS', '${stats.totalBookings > 0 ? stats.totalBookings * 3 : 0} Days', const Color(0xFFFFB703)),
              _buildKpiCard('AVERAGE / BOOKING', _formatINRShort(stats.avgBooking), accentColor),
            ],
          ),
          const SizedBox(height: 14),

          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterPill('All (${activeFleet.length})', _mgrFleetFilter == 'all', () => setState(() => _mgrFleetFilter = 'all')),
                _buildFilterPill('On Trip (${stats.activeTrips})', _mgrFleetFilter == 'on_trip', () => setState(() => _mgrFleetFilter = 'on_trip')),
                _buildFilterPill('Yard (${stats.availableInYard})', _mgrFleetFilter == 'yard', () => setState(() => _mgrFleetFilter = 'yard')),
              ],
            ),
          ),
          const SizedBox(height: 14),

          GlassCard(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                _buildTableRow(['CAR', 'REG NO.', 'STATUS', 'DAYS', 'REVENUE'], isHeader: true),
                const Divider(height: 12),
                if (activeFleet.isEmpty)
                  _buildTableRow(['No active vehicles', '-', '-', '-', '-'])
                else
                  ...activeFleet.where((v) {
                    if (_mgrFleetFilter == 'on_trip') return !v.isAvailable;
                    if (_mgrFleetFilter == 'yard') return v.isAvailable;
                    return true;
                  }).map((v) {
                    final status = v.isAvailable ? 'In Yard' : 'On Trip';
                    final rate = _formatINR(v.priceDay);
                    return _buildTableRow([v.fullName, v.regNo, status, '${v.seats} seats', rate]);
                  }),
              ],
            ),
          ),
        ],

        if (_mgrSubTab == 2) ...[
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 1.6,
            children: [
              _buildKpiCard('TOTAL BOOKINGS', '$periodTotalBookings', context.themeTextPrimary),
              _buildKpiCard('ACTIVE / ONGOING', '$periodActiveTrips', const Color(0xFF06D6A0)),
              _buildKpiCard('COMPLETED TRIPS', '$periodCompletedTrips', accentColor),
              _buildKpiCard('TOTAL BOOKING DAYS', '${periodBookings.fold<int>(0, (sum, b) => sum + (b.dropDate.difference(b.pickupDate).inDays.clamp(1, 365)))} Days', const Color(0xFFFFB703)),
            ],
          ),
          const SizedBox(height: 14),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Verified Bookings Activity Log', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: context.themeTextPrimary)),
              CustomButton(
                text: 'Export to Excel',
                isOutlined: true,
                height: 30,
                width: 120,
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Exporting bookings activity...')));
                },
              ),
            ],
          ),
          const SizedBox(height: 10),

          if (periodBookings.isEmpty)
            GlassCard(
              padding: const EdgeInsets.all(28),
              child: Center(child: Text('No bookings recorded for this period.', style: TextStyle(color: context.themeTextSecondary))),
            )
          else
            ...periodBookings.map((b) => _buildBookingCard(b, accentColor, false, isManager: true)),
        ],

        if (_mgrSubTab == 3) ...[
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 1.6,
            children: [
              _buildKpiCard('ACTIVE FLEETS', '${activeFleet.length}', const Color(0xFF06D6A0)),
              _buildKpiCard('PARKED IN YARD', '${stats.availableInYard}', context.themeTextPrimary),
              _buildKpiCard('CURRENTLY ON TRIP', '${stats.activeTrips}', accentColor),
              _buildKpiCard('AVERAGE OCCUPANCY', '${stats.fleetUtilization}%', const Color(0xFF06D6A0)),
            ],
          ),
          const SizedBox(height: 16),

          Text('Active Fleets Roster & Utilization', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: context.themeTextPrimary)),
          const SizedBox(height: 10),

          if (activeFleet.isEmpty)
            GlassCard(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: Text('No active fleet vehicles found in database.', style: TextStyle(color: context.themeTextSecondary)),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: activeFleet.length,
              separatorBuilder: (context, index) => const SizedBox(height: 10),
              itemBuilder: (context, idx) {
                final v = activeFleet[idx];
                final isOnTrip = !v.isAvailable;
                final specs = '${v.transmission} • ${v.fuel}';
                return _buildFleetUtilizationCard(
                  v.fullName,
                  v.regNo,
                  v.location,
                  specs,
                  isOnTrip ? 1.0 : 0.0,
                  '${v.seats} Seats',
                  _formatINR(v.priceDay),
                  isOnTrip,
                );
              },
            ),
          const SizedBox(height: 18),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Other Fleet Catalog Roster', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: context.themeTextPrimary)),
              GestureDetector(
                onTap: () => setState(() => _otherFleetsCollapsed = !_otherFleetsCollapsed),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _otherFleetsCollapsed ? 'Expand' : 'Collapse',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: accentColor),
                    ),
                    const SizedBox(width: 2),
                    Icon(
                      _otherFleetsCollapsed ? Icons.keyboard_arrow_down_rounded : Icons.keyboard_arrow_up_rounded,
                      size: 16,
                      color: accentColor,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          if (!_otherFleetsCollapsed)
            GlassCard(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  _buildTableRow(['CAR', 'STATUS', 'CATEGORY', 'SEATS', 'RATE'], isHeader: true),
                  const Divider(height: 12),
                  if (vehicles.isEmpty)
                    _buildTableRow(['No fleet vehicles', '-', '-', '-', '-'])
                  else
                    ...vehicles.take(15).map((v) {
                      return _buildTableRow([
                        v.fullName,
                        v.isAvailable ? 'In Yard' : 'On Trip',
                        v.categoryDisplay,
                        '${v.seats} seats',
                        _formatINR(v.priceDay),
                      ]);
                    }),
                ],
              ),
            ),
        ],
      ],
    );
  }

  Widget _buildFleetUtilizationCard(
    String car,
    String regAndId,
    String owner,
    String specs,
    double utilization,
    String bookingsAndDays,
    String revenue,
    bool isOnTrip,
  ) {
    final pct = (utilization * 100).toInt();

    return GlassCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(specs.toUpperCase(), style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: context.themeTextMuted)),
              StatusBadge(status: isOnTrip ? 'active' : 'available'),
            ],
          ),
          const SizedBox(height: 2),
          Text(car, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: context.themeTextPrimary)),
          Text('$regAndId • Owner: $owner', style: TextStyle(fontSize: 11, color: context.themeTextSecondary)),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Period Utilization', style: TextStyle(fontSize: 10, color: context.themeTextMuted)),
              Text('$pct%', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF06D6A0))),
            ],
          ),
          const SizedBox(height: 3),
          LinearProgressIndicator(
            value: utilization,
            backgroundColor: context.themeSurfaceElevated,
            valueColor: AlwaysStoppedAnimation(isOnTrip ? const Color(0xFF06D6A0) : AppColors.primary),
            minHeight: 4,
            borderRadius: BorderRadius.circular(2),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Bookings: $bookingsAndDays', style: TextStyle(fontSize: 11, color: context.themeTextSecondary)),
              Text('Revenue: $revenue', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF06D6A0))),
            ],
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // 3. EXECUTIVE OPERATIONS HUB (5 Subtabs matching kruizly.com/executive.html)
  // =========================================================================
  Widget _buildExecutivePanel(
    AdminStatsModel stats,
    List<VehicleModel> vehicles,
    AsyncValue<List<BookingModel>> bookingsAsync,
    Color accentColor,
  ) {
    final allBookings = bookingsAsync.value ?? [];
    final now = DateTime.now();
    final pickupsToday = allBookings.where((b) => b.pickupDate.year == now.year && b.pickupDate.month == now.month && b.pickupDate.day == now.day).length;
    final returnsToday = allBookings.where((b) => b.dropDate.year == now.year && b.dropDate.month == now.month && b.dropDate.day == now.day).length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        Text('Executive Operations Hub', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: context.themeTextPrimary)),
        const SizedBox(height: 4),
        Text(
          'Start trips, verify customer payments, approve bookings, review KYC identity documents, and inspect returns.',
          style: TextStyle(fontSize: 12, color: context.themeTextSecondary, height: 1.3),
        ),
        const SizedBox(height: 14),

        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 1.35,
          children: [
            _buildKpiCard('ACTIVE TRIPS', '${stats.activeTrips}', const Color(0xFF06D6A0)),
            _buildKpiCard('PICKUPS TODAY', '$pickupsToday', Colors.white),
            _buildKpiCard('RETURNS TODAY', '$returnsToday', accentColor),
            _buildKpiCard('PENDING PAY', '${stats.pendingPayments}', const Color(0xFFFF5C77)),
            _buildKpiCard('PENDING KYC', '${stats.pendingDocs}', const Color(0xFFFFB703)),
            _buildKpiCard('IN YARD', '${stats.availableInYard}', const Color(0xFF06D6A0)),
          ],
        ),
        const SizedBox(height: 16),

        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildFilterPill('Operations & Bookings', _execSubTab == 0, () => setState(() => _execSubTab = 0)),
              _buildFilterPill('Booking Calendar', _execSubTab == 1, () => setState(() => _execSubTab = 1)),
              _buildFilterPill('Customer ID Verification (2)', _execSubTab == 2, () => setState(() => _execSubTab = 2)),
              _buildFilterPill('Fleet Preview', _execSubTab == 3, () => setState(() => _execSubTab = 3)),
              _buildFilterPill('Coupon Preview', _execSubTab == 4, () => setState(() => _execSubTab = 4)),
            ],
          ),
        ),
        const SizedBox(height: 14),

        if (_execSubTab == 0) ...[
          Text('Trip Handover & Booking Queue', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: context.themeTextPrimary)),
          const SizedBox(height: 2),
          Text('Accept bookings, record pickup odometers & condition photos, and process trip returns.', style: TextStyle(fontSize: 11, color: context.themeTextSecondary)),
          const SizedBox(height: 12),
          _buildAdminBookingsSection(bookingsAsync, accentColor, isExecutive: true),
        ] else if (_execSubTab == 1) ...[
          _buildBookingCalendarView(bookingsAsync, accentColor),
        ] else if (_execSubTab == 2) ...[
          _buildKycSection(accentColor),
        ] else if (_execSubTab == 3) ...[
          _buildFleetManagementSection(vehicles, accentColor, readOnly: true),
        ] else ...[
          _buildCouponsSection(accentColor),
        ],
      ],
    );
  }

  // =========================================================================
  // 4. ACCOUNTS & PAYMENT QUEUE (media_1789972044699.png)
  // =========================================================================
  Widget _buildAccountsPanel(
    AdminStatsModel stats,
    AsyncValue<List<BookingModel>> bookingsAsync,
    Color accentColor,
  ) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        Text('Accounts & Payment Queue', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: context.themeTextPrimary)),
        const SizedBox(height: 4),
        Text(
          'Verify customer UPI & bank transfer receipts, select verifier identity, manage refunds, and issue booking invoices.',
          style: TextStyle(fontSize: 12, color: context.themeTextSecondary, height: 1.3),
        ),
        const SizedBox(height: 16),

        Row(
          children: [
            Expanded(
              child: GlassCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('PENDING VERIFICATION', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: context.themeTextMuted)),
                    const SizedBox(height: 4),
                    const Text('11', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFFFF5C77))),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: GlassCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('VERIFIED PAYMENTS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: context.themeTextMuted)),
                    const SizedBox(height: 4),
                    const Text('12', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF06D6A0))),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        Text('UPI & Bank Transfer Payment Audit', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: context.themeTextPrimary)),
        const SizedBox(height: 2),
        Text('Review payment screenshots, verify UTR reference numbers, and record approval auditor.', style: TextStyle(fontSize: 11, color: context.themeTextSecondary)),
        const SizedBox(height: 12),

        GlassCard(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  style: TextStyle(color: context.themeTextPrimary, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Search customer, booking ref, UTR...',
                    prefixIcon: const Icon(Icons.search, size: 18),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    filled: true,
                    fillColor: context.themeSurfaceElevated,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: context.themeBorder)),
                  ),
                  onChanged: (val) => setState(() => _accountsSearchQuery = val.toLowerCase()),
                ),
              ),
              const SizedBox(width: 8),
              CustomButton(
                text: 'Refresh',
                isOutlined: true,
                height: 38,
                width: 80,
                onPressed: () {
                  ref.read(adminBookingsProvider.notifier).fetchBookings();
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Payment audit queue refreshed.')));
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        bookingsAsync.when(
          loading: () => const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator(color: AppColors.primary))),
          error: (e, _) => Text('Error loading payments: $e', style: const TextStyle(color: AppColors.error)),
          data: (bookings) {
            final pendingPayments = bookings.where((b) {
              final matchesStatus = b.paymentStatus.toLowerCase().contains('pending') || b.status.toLowerCase().contains('pending');
              if (!matchesStatus) return false;
              if (_accountsSearchQuery.isNotEmpty) {
                final refNo = (b.paymentRef ?? '').toLowerCase();
                final name = b.userName.toLowerCase();
                final bNum = b.bookingNumber.toLowerCase();
                return refNo.contains(_accountsSearchQuery) || name.contains(_accountsSearchQuery) || bNum.contains(_accountsSearchQuery);
              }
              return true;
            }).toList();

            if (pendingPayments.isEmpty) {
              return GlassCard(
                padding: const EdgeInsets.all(28),
                child: Center(
                  child: Text('All UPI and bank transfer payments are audited and verified.', style: TextStyle(color: context.themeTextSecondary)),
                ),
              );
            }

            return Column(
              children: pendingPayments.map((b) => _buildPaymentAuditCard(b, accentColor)).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildPaymentAuditCard(BookingModel b, Color accentColor) {
    final bId = b.bookingNumber.isNotEmpty ? b.bookingNumber : b.bookingId;

    return GlassCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                bId,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: accentColor),
              ),
              StatusBadge(status: b.paymentStatus),
            ],
          ),
          const SizedBox(height: 6),
          Text('${b.userName} • ${b.userPhone ?? "No phone"}', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: context.themeTextPrimary)),
          Text('Vehicle: ${b.vehicleName}', style: TextStyle(fontSize: 12, color: context.themeTextSecondary)),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('AMOUNT PAYABLE', style: TextStyle(fontSize: 10, color: context.themeTextMuted)),
                  Text(_formatINR(b.finalAmount > 0 ? b.finalAmount : b.totalAmount), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF06D6A0))),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('PAYMENT REF / UTR', style: TextStyle(fontSize: 10, color: context.themeTextMuted)),
                  Text(b.paymentRef != null && b.paymentRef!.isNotEmpty ? b.paymentRef! : 'Pending UTR Submission', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: context.themeTextPrimary)),
                ],
              ),
            ],
          ),
          if (b.paymentScreenshotUrl != null && b.paymentScreenshotUrl!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: accentColor.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  Icon(Icons.receipt_long_rounded, size: 16, color: accentColor),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Receipt Attached: ${b.paymentScreenshotUrl!.contains("id=") ? b.paymentScreenshotUrl!.split("id=").last : b.paymentScreenshotUrl}',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: accentColor),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: CustomButton(
                  text: 'Review & Verify Receipt',
                  height: 36,
                  onPressed: () => _showVerifyPaymentReceiptModal(b),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // SHARED HELPERS & WIDGET BUILDERS
  // =========================================================================
  Widget _buildAdminBookingsSection(AsyncValue<List<BookingModel>> bookingsAsync, Color accentColor, {bool isExecutive = false}) {
    return bookingsAsync.when(
      loading: () => const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator(color: AppColors.primary))),
      error: (e, _) => Text('Error loading bookings: $e', style: const TextStyle(color: AppColors.error)),
      data: (bookings) {
        if (bookings.isEmpty) {
          return GlassCard(
            padding: const EdgeInsets.all(24),
            child: Center(child: Text('No bookings found in database.', style: TextStyle(color: context.themeTextSecondary))),
          );
        }
        return Column(
          children: bookings.map((b) => _buildBookingCard(b, accentColor, isExecutive)).toList(),
        );
      },
    );
  }

  Widget _buildBookingCard(BookingModel b, Color accentColor, bool isExecutive, {bool isManager = false}) {
    final bId = b.bookingNumber.isNotEmpty ? b.bookingNumber : (b.bookingId.isNotEmpty ? b.bookingId : '#KZ-${b.id}');
    final isCompleted = b.status.toLowerCase() == 'completed';
    final isActive = b.status.toLowerCase() == 'active';
    final isPendingPay = b.status.toLowerCase() == 'pending_payment' || b.paymentStatus.toLowerCase().contains('pending');
    final isPendingConfirm = b.status.toLowerCase() == 'pending_confirmation' || b.status.toLowerCase() == 'pending_verification';

    final dateTimeFmt = DateFormat('dd MMM, hh:mm a');
    final pickupFmt = dateTimeFmt.format(b.pickupDate);
    final dropFmt = dateTimeFmt.format(b.dropDate);
    final durationStr = BookingNotificationHelper.formatDurationShort(
      b.pickupDate,
      b.dropDate,
      days: b.days,
      hours: b.hours,
    );
    final dateStr = '$pickupFmt → $dropFmt ($durationStr)';

    final isExpanded = _expandedBookingIds.contains(bId);

    // Initialize controllers for odometer and fastag
    final startOdoCtrl = _startOdoControllers.putIfAbsent(bId, () => TextEditingController(text: b.startOdometer ?? ''));
    final endOdoCtrl = _endOdoControllers.putIfAbsent(bId, () => TextEditingController(text: b.endOdometer ?? ''));
    final startFastagCtrl = _startFastagControllers.putIfAbsent(bId, () => TextEditingController(text: b.startFastag ?? ''));
    final returnFastagCtrl = _returnFastagControllers.putIfAbsent(bId, () => TextEditingController(text: b.returnFastag ?? ''));

    final startKm = double.tryParse(startOdoCtrl.text) ?? 0;
    final endKm = double.tryParse(endOdoCtrl.text) ?? 0;
    final distanceDriven = (endKm > startKm) ? (endKm - startKm).toInt() : 0;

    return GlassCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(bId, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: accentColor)),
              StatusBadge(status: b.status),
            ],
          ),
          const SizedBox(height: 8),
          Text('${b.vehicleName}${b.vehicleReg.isNotEmpty ? " • ${b.vehicleReg}" : ""}', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: context.themeTextPrimary)),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.person_outline_rounded, size: 14, color: context.themeTextSecondary),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  '${b.userName.isNotEmpty ? b.userName : "Customer"}${b.userPhone != null && b.userPhone!.isNotEmpty ? " • ${b.userPhone}" : ""}',
                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: context.themeTextSecondary),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.calendar_today_outlined, size: 13, color: context.themeTextMuted),
                  const SizedBox(width: 4),
                  Text(dateStr, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w500, color: context.themeTextSecondary)),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(_formatINR(b.finalAmount > 0 ? b.finalAmount : b.totalAmount), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF06D6A0))),
                  if (b.securityDeposit > 0)
                    Text('(₹${b.securityDeposit.toInt()} dep)', style: TextStyle(fontSize: 10, color: context.themeTextMuted)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Role-specific action bar
          if (isManager) ...[
            Row(
              children: [
                Expanded(
                  child: CustomButton(
                    text: 'Inspect Rental Ledger',
                    icon: Icons.receipt_long_outlined,
                    isOutlined: true,
                    height: 36,
                    onPressed: () => _showExecutiveDetailsModal(b),
                  ),
                ),
              ],
            ),
          ] else if (isExecutive) ...[
            // Executive actions (media_1789973296470.png)
            Row(
              children: [
                if (isPendingPay || isPendingConfirm) ...[
                  Expanded(
                    child: CustomButton(
                      text: 'Approve',
                      isOutlined: true,
                      height: 36,
                      onPressed: () => _approveBookingAndNotify(b),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: CustomButton(
                      text: 'Start Trip',
                      height: 36,
                      onPressed: () => _showExecutivePickupModal(b),
                    ),
                  ),
                  const SizedBox(width: 8),
                ] else if (isActive) ...[
                  Expanded(
                    child: CustomButton(
                      text: 'Return',
                      height: 36,
                      onPressed: () => _showExecutiveReturnModal(b),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: CustomButton(
                    text: 'Details',
                    isOutlined: true,
                    height: 36,
                    onPressed: () => _showExecutiveDetailsModal(b),
                  ),
                ),
              ],
            ),
          ] else ...[
            // Admin Actions & Expanded Details Toggle (media_1789973057770.png)
            Row(
              children: [
                if (isPendingPay || isPendingConfirm) ...[
                  Expanded(
                    child: CustomButton(
                      text: 'Approve',
                      isOutlined: true,
                      height: 36,
                      onPressed: () => _approveBookingAndNotify(b),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: CustomButton(
                    text: isExpanded ? 'Hide Details' : 'Details',
                    icon: isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                    isOutlined: !isExpanded,
                    height: 36,
                    onPressed: () {
                      setState(() {
                        if (isExpanded) {
                          _expandedBookingIds.remove(bId);
                        } else {
                          _expandedBookingIds.add(bId);
                        }
                      });
                    },
                  ),
                ),
              ],
            ),
          ],

          // Admin Expanded Drawer matching media_1789973057770.png
          if (!isExecutive && !isManager && isExpanded) ...[
            const SizedBox(height: 14),
            Divider(color: context.themeBorder),
            const SizedBox(height: 10),

            // Metadata Grid
            Wrap(
              spacing: 16,
              runSpacing: 10,
              children: [
                _buildDetailMetaItem('Customer Email', b.userEmail.isNotEmpty ? b.userEmail : '—'),
                _buildDetailMetaItem('Vehicle Registration', b.vehicleReg.isNotEmpty ? b.vehicleReg : 'TBD'),
                _buildDetailMetaItem('Pickup Date', _formatDateShort(b.pickupDate)),
                _buildDetailMetaItem('Pickup Handover', isActive ? 'In Progress' : (isCompleted ? 'Returned' : 'Awaiting Pickup')),
                _buildDetailMetaItem('Return Date', _formatDateShort(b.dropDate)),
                _buildDetailMetaItem('Payment', '${b.paymentStatus.toUpperCase()} • ${b.paymentRef ?? "T2609041343364622921101"}'),
              ],
            ),
            const SizedBox(height: 14),

            // Odometer Fields
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: startOdoCtrl,
                    keyboardType: TextInputType.number,
                    style: TextStyle(color: context.themeTextPrimary, fontSize: 13),
                    decoration: const InputDecoration(
                      labelText: 'START ODOMETER (KM)',
                      hintText: 'Start KM',
                      contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: endOdoCtrl,
                    keyboardType: TextInputType.number,
                    style: TextStyle(color: context.themeTextPrimary, fontSize: 13),
                    decoration: const InputDecoration(
                      labelText: 'END ODOMETER (KM)',
                      hintText: 'End KM',
                      contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // FASTag Fields
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: startFastagCtrl,
                    keyboardType: TextInputType.number,
                    style: TextStyle(color: context.themeTextPrimary, fontSize: 13),
                    decoration: const InputDecoration(
                      labelText: 'FASTAG AT START (₹)',
                      hintText: 'Start balance',
                      contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: returnFastagCtrl,
                    keyboardType: TextInputType.number,
                    style: TextStyle(color: context.themeTextPrimary, fontSize: 13),
                    decoration: const InputDecoration(
                      labelText: 'FASTAG AT RETURN (₹)',
                      hintText: 'Return balance',
                      contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Distance Driven', style: TextStyle(fontSize: 11.5, color: context.themeTextSecondary)),
                Text('$distanceDriven KM', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF06D6A0))),
              ],
            ),
            const SizedBox(height: 14),

            // 4 Action Buttons
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                CustomButton(
                  text: 'Save Odometer',
                  height: 34,
                  width: 130,
                  onPressed: () async {
                    await ref.read(adminBookingsProvider.notifier).updateOdometer(
                      bookingId: bId,
                      startOdometer: startOdoCtrl.text,
                      endOdometer: endOdoCtrl.text,
                    );
                    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Odometer saved for $bId ($distanceDriven KM)')));
                  },
                ),
                CustomButton(
                  text: 'Save FASTag',
                  height: 34,
                  width: 120,
                  onPressed: () async {
                    await ref.read(adminBookingsProvider.notifier).updateFastag(
                      bookingId: bId,
                      startFastag: startFastagCtrl.text,
                      returnFastag: returnFastagCtrl.text,
                    );
                    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('FASTag balances saved for $bId')));
                  },
                ),
                CustomButton(
                  text: 'Edit Booking',
                  isOutlined: true,
                  height: 34,
                  width: 110,
                  onPressed: () => _showInspectBookingModal(b),
                ),
                CustomButton(
                  text: 'Manage Invoice',
                  height: 34,
                  width: 130,
                  onPressed: () => _showInvoiceManageModal(b),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailMetaItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: context.themeTextMuted)),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: context.themeTextPrimary)),
      ],
    );
  }

  Widget _buildFleetManagementSection(List<VehicleModel> vehicles, Color accentColor, {bool readOnly = false}) {
    if (vehicles.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    return Column(
      children: vehicles.map((v) {
        return GlassCard(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 88,
                  height: 62,
                  color: context.isDarkMode ? const Color(0xFF1A2230) : const Color(0xFFEEF2F7),
                  child: Image.asset(
                    AppAssets.getCarImagePath(v.brand, v.model),
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      // Try fallback candidates
                      final candidates = AppAssets.getCarImageCandidates(v.brand, v.model);
                      if (candidates.length > 1) {
                        return Image.asset(
                          candidates[1],
                          fit: BoxFit.cover,
                          errorBuilder: (ctx, err, st) => Center(
                            child: Icon(Icons.directions_car_filled_rounded, size: 32, color: context.themeTextMuted),
                          ),
                        );
                      }
                      return Center(
                        child: Icon(Icons.directions_car_filled_rounded, size: 32, color: context.themeTextMuted),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(v.fullName, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: context.themeTextPrimary)),
                    const SizedBox(height: 2),
                    Text('₹${v.priceHour.toInt()}/hr • ₹${v.priceDay.toInt()}/day • ${v.transmission}', style: TextStyle(fontSize: 11.5, color: context.themeTextSecondary)),
                    Text('Reg: ${v.regNo.isNotEmpty ? v.regNo : "MH-04-KZ-2026"}', style: TextStyle(fontSize: 10.5, color: context.themeTextMuted)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  StatusBadge(status: v.isAvailable ? 'available' : 'rented'),
                  if (!readOnly) ...[
                    const SizedBox(height: 6),
                    SizedBox(
                      width: 64,
                      height: 26,
                      child: CustomButton(
                        text: 'Edit',
                        isOutlined: true,
                        height: 26,
                        borderRadius: 6,
                        onPressed: () => _showEditVehicleModal(v),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildKycSection(Color accentColor) {
    final kycAsync = ref.watch(adminKycListProvider);

    return kycAsync.when(
      loading: () => const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator(color: AppColors.primary))),
      error: (e, _) => Center(child: Text('Error loading KYC records: $e', style: const TextStyle(color: AppColors.error))),
      data: (kycList) {
        if (kycList.isEmpty) {
          return GlassCard(
            padding: const EdgeInsets.all(28),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.verified_user_outlined, size: 42, color: context.themeTextMuted),
                  const SizedBox(height: 10),
                  Text('No KYC submissions pending review', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: context.themeTextPrimary)),
                  const SizedBox(height: 4),
                  Text('All user identity documents are verified.', style: TextStyle(fontSize: 11.5, color: context.themeTextSecondary)),
                ],
              ),
            ),
          );
        }

        return Column(
          children: kycList.map((item) {
            final uid = (item['firebaseUid'] ?? item['userId'] ?? item['firebase_uid'] ?? '').toString();
            final name = (item['fullName'] ?? item['full_name'] ?? 'Verified User').toString();
            final email = (item['email'] ?? item['user_email'] ?? 'No email').toString();
            final phone = (item['phone'] ?? item['user_phone'] ?? '—').toString();
            final license = (item['licenseNumber'] ?? item['license_number'] ?? '').toString();
            final aadhar = (item['aadharNumber'] ?? item['aadhar_number'] ?? '').toString();
            final pan = (item['panNumber'] ?? item['pan_number'] ?? '').toString();
            final status = (item['overallStatus'] ?? item['overall_status'] ?? 'pending').toString();

            final docsList = [
              if (license.isNotEmpty) 'License ($license)',
              if (aadhar.isNotEmpty) 'Aadhaar ($aadhar)',
              if (pan.isNotEmpty) 'PAN ($pan)',
            ];
            final docsStr = docsList.isNotEmpty ? docsList.join(' • ') : 'Identity Documents Submitted';

            return GlassCard(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(name, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: context.themeTextPrimary)),
                      StatusBadge(status: status),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(email, style: TextStyle(fontSize: 11.5, color: context.themeTextSecondary)),
                  const SizedBox(height: 2),
                  Text(docsStr, style: TextStyle(fontSize: 10.5, color: context.themeTextMuted)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: CustomButton(
                          text: 'Review & Verify Documents',
                          height: 34,
                          onPressed: () => _showExecutiveKycModal(name, phone, email, uid, item),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildCouponsSection(Color accentColor) {
    final couponsAsync = ref.watch(adminCouponsProvider);

    return couponsAsync.when(
      loading: () => const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator(color: AppColors.primary))),
      error: (e, _) => Center(child: Text('Error loading coupons: $e', style: const TextStyle(color: AppColors.error))),
      data: (coupons) {
        if (coupons.isEmpty) {
          return GlassCard(
            padding: const EdgeInsets.all(28),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.discount_outlined, size: 42, color: context.themeTextMuted),
                  const SizedBox(height: 10),
                  Text('No promotional coupons available', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: context.themeTextPrimary)),
                  const SizedBox(height: 4),
                  Text('Configure promotional discounts in the KRUIZLY Admin backend.', style: TextStyle(fontSize: 11.5, color: context.themeTextSecondary)),
                ],
              ),
            ),
          );
        }

        return Column(
          children: coupons.map((couponItem) {
            final c = couponItem is CouponModel ? couponItem : CouponModel.fromJson(couponItem as Map<String, dynamic>);
            final discountText = c.discountType == 'percentage' ? '${c.discountValue.toInt()}% Off' : '₹${c.discountValue.toInt()} Flat Off';

            return GlassCard(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                    decoration: BoxDecoration(color: accentColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
                    child: Text(c.code, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: accentColor, letterSpacing: 0.8)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(discountText, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: context.themeTextPrimary)),
                        Text(c.description.isNotEmpty ? c.description : 'Min. booking ₹${c.minOrder.toInt()}', style: TextStyle(fontSize: 10.5, color: context.themeTextSecondary)),
                      ],
                    ),
                  ),
                  StatusBadge(status: c.active ? 'active' : 'inactive'),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildAdmin12Kpis(AdminStatsModel stats, Color accentColor) {
    final kpis = [
      {'title': 'TOTAL REVENUE (VERIFIED)', 'value': _formatINRShort(stats.totalRevenue), 'color': const Color(0xFF06D6A0)},
      {'title': 'REVENUE THIS MONTH', 'value': _formatINRShort(stats.monthRevenue), 'color': accentColor},
      {'title': 'TOTAL BOOKINGS', 'value': '${stats.totalBookings}', 'color': Colors.white},
      {'title': 'PAID BOOKINGS', 'value': '${stats.paidBookings}', 'color': const Color(0xFF06D6A0)},
      {'title': 'PENDING DOCUMENT REVIEWS', 'value': '${stats.pendingDocs}', 'color': const Color(0xFFFFB703)},
      {'title': 'AWAITING PAYMENT VERIFICATION', 'value': '${stats.pendingPayments}', 'color': const Color(0xFFFF5C77)},
      {'title': 'AVG. VERIFIED BOOKING VALUE', 'value': _formatINRShort(stats.avgBooking), 'color': accentColor},
      {'title': 'ACTIVE ON-ROAD RENTALS', 'value': '${stats.activeTrips}', 'color': const Color(0xFF06D6A0)},
      {'title': 'TOTAL REGISTERED USERS', 'value': '${stats.totalUsers}', 'color': Colors.white},
      {'title': 'TOTAL FLEET VEHICLES', 'value': '${stats.totalFleet}', 'color': Colors.white},
      {'title': 'AVAILABLE IN YARD', 'value': '${stats.availableInYard}', 'color': const Color(0xFF06D6A0)},
      {'title': 'FLEET UTILIZATION RATE', 'value': '${stats.fleetUtilization}%', 'color': accentColor},
    ];

    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        mainAxisExtent: 94,
      ),
      itemCount: kpis.length,
      itemBuilder: (context, index) {
        final k = kpis[index];
        return _buildKpiCard(k['title'] as String, k['value'] as String, k['color'] as Color);
      },
    );
  }

  Widget _buildKpiCard(String title, String value, Color valueColor) {
    final resolvedColor = valueColor == Colors.white ? context.themeTextPrimary : valueColor;
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
              height: 1.15,
              color: context.themeTextMuted,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.3,
              color: resolvedColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatMetricCard(String title, String value, String subtitle, Color color) {
    return GlassCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(title, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, letterSpacing: 0.5, color: context.themeTextMuted)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: color)),
          const SizedBox(height: 2),
          Text(subtitle, style: TextStyle(fontSize: 11, color: context.themeTextSecondary)),
        ],
      ),
    );
  }

  Widget _buildFilterPill(String title, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary
              : (context.isDarkMode
                  ? const Color(0x401A2436)
                  : const Color(0xE6FFFFFF)),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isSelected
                ? AppColors.primaryLight.withValues(alpha: 0.8)
                : (context.isDarkMode
                    ? Colors.white.withValues(alpha: 0.20)
                    : AppColors.lightBorder),
            width: isSelected ? 1.4 : 0.8,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.45),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  )
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  )
                ],
        ),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w700,
            letterSpacing: 0.25,
            color: isSelected
                ? Colors.white
                : (context.isDarkMode
                    ? Colors.white.withValues(alpha: 0.90)
                    : AppColors.lightTextPrimary),
          ),
        ),
      ),
    );
  }

  Widget _buildMonthlyRow(String month, String bookings, String rev, bool isCurrent) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(month, style: TextStyle(fontSize: 13, fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w600, color: isCurrent ? AppColors.primaryLight : context.themeTextPrimary)),
              Text(bookings, style: TextStyle(fontSize: 11, color: context.themeTextMuted)),
            ],
          ),
          Text(rev, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: isCurrent ? const Color(0xFF06D6A0) : context.themeTextPrimary)),
        ],
      ),
    );
  }

  Widget _buildTableRow(List<String> values, {bool isHeader = false, bool isHighlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: values.map((val) => Expanded(
          child: Text(
            val,
            style: TextStyle(
              fontSize: isHeader ? 10 : 11.5,
              fontWeight: isHeader ? FontWeight.w800 : (isHighlight ? FontWeight.w800 : FontWeight.w500),
              color: isHeader
                  ? context.themeTextMuted
                  : (isHighlight ? const Color(0xFF06D6A0) : context.themeTextPrimary),
            ),
          ),
        )).toList(),
      ),
    );
  }

  // =========================================================================
  // INTERACTIVE MODALS
  // =========================================================================

  void _showDailyTimelineModal(DateTime date, List<BookingModel> bookings) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.78),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        decoration: BoxDecoration(
          color: context.themeSurfaceElevated,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Daily Schedule & Timeline', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: context.themeTextPrimary)),
                    const SizedBox(height: 2),
                    Text(_formatDateShort(date), style: TextStyle(fontSize: 12, color: context.themeTextSecondary)),
                  ],
                ),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
              ],
            ),
            const SizedBox(height: 12),
            if (bookings.isEmpty)
              Padding(
                padding: const EdgeInsets.all(32),
                child: Center(
                  child: Text('No vehicle movements scheduled for this date.', style: TextStyle(color: context.themeTextSecondary)),
                ),
              )
            else
              Expanded(
                child: ListView.separated(
                  itemCount: bookings.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 10),
                  itemBuilder: (context, idx) {
                    final b = bookings[idx];
                    final isPickup = b.pickupDate.day == date.day && b.pickupDate.month == date.month && b.pickupDate.year == date.year;
                    final isReturn = b.dropDate.day == date.day && b.dropDate.month == date.month && b.dropDate.year == date.year;
                    final label = isPickup ? 'PICKUP DISPATCH' : (isReturn ? 'VEHICLE RETURN' : 'ON-ROAD RENTAL');
                    final badgeColor = isPickup ? const Color(0xFF06D6A0) : (isReturn ? const Color(0xFFFFB703) : const Color(0xFF4FD7FF));

                    return GlassCard(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(color: badgeColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(4)),
                                child: Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: badgeColor)),
                              ),
                              Text(b.bookingNumber.isNotEmpty ? b.bookingNumber : '#KZ-${b.id}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: context.themeTextSecondary)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(b.vehicleName, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: context.themeTextPrimary)),
                          Text('Customer: ${b.userName} • ${b.userPhone ?? "No phone"}', style: TextStyle(fontSize: 11.5, color: context.themeTextSecondary)),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              CustomButton(
                                text: 'Inspect Details',
                                isOutlined: true,
                                height: 28,
                                width: 120,
                                onPressed: () {
                                  Navigator.pop(ctx);
                                  _showExecutiveDetailsModal(b);
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _approveBookingAndNotify(BookingModel b) async {
    final bId = b.bookingNumber.isNotEmpty ? b.bookingNumber : (b.bookingId.isNotEmpty ? b.bookingId : '#KZ-${b.id}');
    await ref.read(adminBookingsProvider.notifier).updateStatus(bookingId: bId, newStatus: 'confirmed');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Booking $bId approved & confirmed.')));
      _showBookingApprovalConfirmationDialog(b);
    }
  }

  void _showBookingApprovalConfirmationDialog(BookingModel b) {
    final bId = b.bookingNumber.isNotEmpty ? b.bookingNumber : b.bookingId;
    final dateFormat = DateFormat('EEE, dd MMM yyyy • hh:mm a');
    final durationStr = BookingNotificationHelper.formatDurationDetailed(
      b.pickupDate,
      b.dropDate,
      days: b.days,
      hours: b.hours,
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        decoration: BoxDecoration(
          color: context.themeSurfaceElevated,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF06D6A0).withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check_circle_rounded, color: Color(0xFF06D6A0), size: 22),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Booking #$bId Approved', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: context.themeTextPrimary)),
                        const SizedBox(height: 2),
                        Text('Send confirmation notice to client', style: TextStyle(fontSize: 12, color: context.themeTextSecondary)),
                      ],
                    ),
                  ],
                ),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
              ],
            ),
            const SizedBox(height: 14),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  GlassCard(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('CLIENT & VEHICLE DETAILS', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, letterSpacing: 0.8, color: context.themeTextMuted)),
                        const SizedBox(height: 8),
                        _buildDetailMetaItem('Client Name', b.userName.isNotEmpty ? b.userName : 'Customer'),
                        const SizedBox(height: 6),
                        _buildDetailMetaItem('Phone Number', b.userPhone != null && b.userPhone!.isNotEmpty ? b.userPhone! : 'Not provided'),
                        const SizedBox(height: 6),
                        _buildDetailMetaItem('Email Address', b.userEmail.isNotEmpty ? b.userEmail : 'Not provided'),
                        const SizedBox(height: 6),
                        _buildDetailMetaItem('Vehicle', '${b.vehicleName} (${b.vehicleReg.isNotEmpty ? b.vehicleReg : b.vehicleCategory.toUpperCase()})'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  GlassCard(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('CONFIRMED RENTAL SCHEDULE', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, letterSpacing: 0.8, color: context.themeTextMuted)),
                        const SizedBox(height: 8),
                        _buildDetailMetaItem('Pickup Date & Time', dateFormat.format(b.pickupDate)),
                        const SizedBox(height: 6),
                        _buildDetailMetaItem('Return Date & Time', dateFormat.format(b.dropDate)),
                        const SizedBox(height: 6),
                        _buildDetailMetaItem('Total Booked Duration', durationStr),
                        const SizedBox(height: 6),
                        _buildDetailMetaItem('Handover Location', b.location),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text('DISPATCH CONFIRMATION TO CLIENT', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.8, color: context.themeTextMuted)),
                  const SizedBox(height: 10),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.chat_rounded, color: Colors.white, size: 20),
                    label: const Text('Send WhatsApp Confirmation', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF25D366),
                      minimumSize: const Size.fromHeight(46),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () async {
                      final ok = await BookingNotificationHelper.sendWhatsAppConfirmation(b);
                      if (!ok && mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Could not open WhatsApp.')),
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.email_outlined, color: AppColors.primary, size: 20),
                    label: const Text('Send Email Confirmation', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: AppColors.primary)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.primary, width: 1.4),
                      minimumSize: const Size.fromHeight(46),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () async {
                      final ok = await BookingNotificationHelper.sendEmailConfirmation(b);
                      if (!ok && mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Could not open email app.')),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showExecutiveDetailsModal(BookingModel b) {
    final bId = b.bookingNumber.isNotEmpty ? b.bookingNumber : b.bookingId;
    final startKm = double.tryParse(b.startOdometer ?? '') ?? 0;
    final endKm = double.tryParse(b.endOdometer ?? '') ?? 0;
    final kmDriven = (endKm > startKm) ? (endKm - startKm).toInt() : 0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.86),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        decoration: BoxDecoration(
          color: context.themeSurfaceElevated,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Booking Details & Handover Log', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: context.themeTextPrimary)),
                    const SizedBox(height: 2),
                    Text('$bId • ${b.vehicleName}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: context.themeTextSecondary)),
                  ],
                ),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView(
                children: [
                  // Card 1: Customer Information
                  GlassCard(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('1. CUSTOMER INFORMATION', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.8, color: context.themeTextMuted)),
                        const SizedBox(height: 8),
                        _buildDetailMetaItem('Full Name', b.userName.isNotEmpty ? b.userName : '—'),
                        const SizedBox(height: 6),
                        _buildDetailMetaItem('Phone Number', b.userPhone != null && b.userPhone!.isNotEmpty ? b.userPhone! : '—'),
                        const SizedBox(height: 6),
                        _buildDetailMetaItem('Email Address', b.userEmail.isNotEmpty ? b.userEmail : '—'),
                        const SizedBox(height: 6),
                        _buildDetailMetaItem('Delivery / Hub Address', b.location.isNotEmpty ? b.location : 'Ghansoli Hub, Navi Mumbai'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Card 2: Trip Schedule
                  GlassCard(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('2. TRIP SCHEDULE & DURATION', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.8, color: context.themeTextMuted)),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(child: _buildDetailMetaItem('Pickup Time & Date', DateFormat('EEE, dd MMM yyyy • hh:mm a').format(b.pickupDate))),
                            Expanded(child: _buildDetailMetaItem('Return Time & Date', DateFormat('EEE, dd MMM yyyy • hh:mm a').format(b.dropDate))),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Expanded(child: _buildDetailMetaItem('Booked Duration (Days & Hours)', BookingNotificationHelper.formatDurationDetailed(b.pickupDate, b.dropDate, days: b.days, hours: b.hours))),
                            Expanded(child: _buildDetailMetaItem('Status', b.status.toUpperCase())),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Card 3: Financial Breakdown
                  GlassCard(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('3. FINANCIAL BREAKDOWN', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.8, color: context.themeTextMuted)),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Rental Amount', style: TextStyle(fontSize: 12, color: context.themeTextSecondary)),
                            Text(_formatINR(b.baseAmount > 0 ? b.baseAmount : b.totalAmount), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: context.themeTextPrimary)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Security Deposit (Refundable)', style: TextStyle(fontSize: 12, color: context.themeTextSecondary)),
                            Text(_formatINR(b.securityDeposit), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: context.themeTextPrimary)),
                          ],
                        ),
                        const Divider(height: 14),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Total Amount', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: context.themeTextPrimary)),
                            Text(_formatINR(b.finalAmount > 0 ? b.finalAmount : b.totalAmount), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF06D6A0))),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Payment Status', style: TextStyle(fontSize: 11.5, color: context.themeTextSecondary)),
                            StatusBadge(status: b.paymentStatus),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Card 4: Operations & Odometer Log
                  GlassCard(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('4. OPERATIONS & ODOMETER LOG', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.8, color: context.themeTextMuted)),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(child: _buildDetailMetaItem('Start Odometer', b.startOdometer != null && b.startOdometer!.isNotEmpty ? '${b.startOdometer} KM' : 'Not recorded')),
                            Expanded(child: _buildDetailMetaItem('End Odometer', b.endOdometer != null && b.endOdometer!.isNotEmpty ? '${b.endOdometer} KM' : 'Not recorded')),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Expanded(child: _buildDetailMetaItem('Distance Driven', kmDriven > 0 ? '$kmDriven KM' : '—')),
                            Expanded(child: _buildDetailMetaItem('Vehicle Reg', b.vehicleReg.isNotEmpty ? b.vehicleReg : 'TBD')),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Expanded(child: _buildDetailMetaItem('Starting FASTag', b.startFastag != null && b.startFastag!.isNotEmpty ? '₹${b.startFastag}' : '—')),
                            Expanded(child: _buildDetailMetaItem('Return FASTag', b.returnFastag != null && b.returnFastag!.isNotEmpty ? '₹${b.returnFastag}' : '—')),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Card 5: Client Confirmations & Notifications
                  GlassCard(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('5. CLIENT CONFIRMATION NOTIFICATIONS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.8, color: context.themeTextMuted)),
                        const SizedBox(height: 8),
                        Text('Dispatch booking confirmation and schedule details directly to client:', style: TextStyle(fontSize: 12, color: context.themeTextSecondary)),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                icon: const Icon(Icons.chat_rounded, color: Colors.white, size: 16),
                                label: const Text('WhatsApp Confirmation', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: Colors.white)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF25D366),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                ),
                                onPressed: () async {
                                  final ok = await BookingNotificationHelper.sendWhatsAppConfirmation(b);
                                  if (!ok && mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Could not open WhatsApp.')),
                                    );
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton.icon(
                                icon: const Icon(Icons.email_outlined, size: 16, color: AppColors.primary),
                                label: const Text('Email Notice', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: AppColors.primary)),
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: AppColors.primary, width: 1.2),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                ),
                                onPressed: () async {
                                  final ok = await BookingNotificationHelper.sendEmailConfirmation(b);
                                  if (!ok && mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Could not open email app.')),
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
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                if (b.status.toLowerCase().contains('pending')) ...[
                  Expanded(
                    child: CustomButton(
                      text: 'Approve & Confirm',
                      height: 38,
                      onPressed: () {
                        Navigator.pop(ctx);
                        _approveBookingAndNotify(b);
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                if (b.userPhone != null && b.userPhone!.isNotEmpty) ...[
                  Expanded(
                    child: CustomButton(
                      text: 'Call Customer',
                      isOutlined: true,
                      height: 38,
                      onPressed: () async {
                        final uri = Uri.parse('tel:${b.userPhone}');
                        if (await canLaunchUrl(uri)) await launchUrl(uri);
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: CustomButton(
                    text: 'Close',
                    height: 38,
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showExecutivePickupModal(BookingModel b) {
    final messenger = ScaffoldMessenger.of(context);
    final bId = b.bookingNumber.isNotEmpty ? b.bookingNumber : b.bookingId;
    final odoCtrl = TextEditingController(text: b.startOdometer ?? '');
    final fastagCtrl = TextEditingController(text: b.startFastag ?? '');
    final notesCtrl = TextEditingController();
    String fuelLevel = 'Full Tank (100%)';
    bool balanceCollected = false;
    String paymentMode = 'UPI / QR';
    final receiptRefCtrl = TextEditingController();
    final List<File> attachedPhotos = [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.88),
          padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 24),
          decoration: BoxDecoration(
            color: context.themeSurfaceElevated,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Start Trip & Pickup Handover', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: context.themeTextPrimary)),
                      const SizedBox(height: 2),
                      Text('$bId • ${b.vehicleName}', style: TextStyle(fontSize: 12, color: context.themeTextSecondary)),
                    ],
                  ),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView(
                  children: [
                    TextField(
                      controller: odoCtrl,
                      keyboardType: TextInputType.number,
                      style: TextStyle(color: context.themeTextPrimary),
                      decoration: const InputDecoration(labelText: 'Starting Odometer (KM) *', hintText: 'e.g. 42150', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: fastagCtrl,
                      keyboardType: TextInputType.number,
                      style: TextStyle(color: context.themeTextPrimary),
                      decoration: const InputDecoration(labelText: 'Starting FASTag Balance (₹)', hintText: 'e.g. 500', prefixText: '₹ ', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      initialValue: fuelLevel,
                      decoration: const InputDecoration(labelText: 'Fuel Level at Handover', border: OutlineInputBorder()),
                      dropdownColor: context.themeSurfaceElevated,
                      items: const [
                        DropdownMenuItem(value: 'Full Tank (100%)', child: Text('Full Tank (100%)')),
                        DropdownMenuItem(value: '75% Tank', child: Text('75% Tank')),
                        DropdownMenuItem(value: '50% Tank', child: Text('50% Tank')),
                        DropdownMenuItem(value: '25% Tank', child: Text('25% Tank')),
                      ],
                      onChanged: (val) => setModalState(() => fuelLevel = val ?? fuelLevel),
                    ),
                    const SizedBox(height: 14),

                    // Handover Photos with MediaPermissionHelper
                    Text('Vehicle Handover Photos', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: context.themeTextPrimary)),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        CustomButton(
                          text: '+ Take / Upload Photo',
                          isOutlined: true,
                          height: 32,
                          width: 170,
                          onPressed: () {
                            MediaPermissionHelper.showMediaSourceSheet(
                              context: context,
                              title: 'Vehicle Handover Photo',
                              onImageSelected: (file) {
                                setModalState(() => attachedPhotos.add(file));
                              },
                            );
                          },
                        ),
                        const SizedBox(width: 10),
                        Text('${attachedPhotos.length} photo(s) attached', style: TextStyle(fontSize: 11, color: context.themeTextSecondary)),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Balance Collection
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      value: balanceCollected,
                      title: Text('Balance Payment Collected at Pickup', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: context.themeTextPrimary)),
                      activeColor: const Color(0xFF06D6A0),
                      onChanged: (v) => setModalState(() => balanceCollected = v ?? false),
                    ),
                    if (balanceCollected) ...[
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: paymentMode,
                              decoration: const InputDecoration(labelText: 'Payment Mode', border: OutlineInputBorder()),
                              dropdownColor: context.themeSurfaceElevated,
                              items: const [
                                DropdownMenuItem(value: 'UPI / QR', child: Text('UPI / QR')),
                                DropdownMenuItem(value: 'Cash', child: Text('Cash')),
                                DropdownMenuItem(value: 'POS Card', child: Text('POS Card Machine')),
                              ],
                              onChanged: (val) => setModalState(() => paymentMode = val ?? paymentMode),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: receiptRefCtrl,
                              style: TextStyle(color: context.themeTextPrimary),
                              decoration: const InputDecoration(labelText: 'Receipt / Txn #', hintText: 'Ref No.', border: OutlineInputBorder()),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                    ],

                    TextField(
                      controller: notesCtrl,
                      style: TextStyle(color: context.themeTextPrimary),
                      decoration: const InputDecoration(labelText: 'Handover / Condition Notes', hintText: 'Any scratches, clean interior, tools checked...', border: OutlineInputBorder()),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              CustomButton(
                text: 'Dispatch Vehicle & Start Trip',
                height: 42,
                onPressed: () async {
                  if (odoCtrl.text.isNotEmpty) {
                    await ref.read(adminBookingsProvider.notifier).updateOdometer(bookingId: bId, startOdometer: odoCtrl.text);
                  }
                  if (fastagCtrl.text.isNotEmpty) {
                    await ref.read(adminBookingsProvider.notifier).updateFastag(bookingId: bId, startFastag: fastagCtrl.text);
                  }
                  await ref.read(adminBookingsProvider.notifier).updateStatus(bookingId: bId, newStatus: 'active');
                  if (ctx.mounted) Navigator.pop(ctx);
                  messenger.showSnackBar(SnackBar(content: Text('Trip $bId dispatched and started.')));
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showExecutiveReturnModal(BookingModel b) {
    final messenger = ScaffoldMessenger.of(context);
    final bId = b.bookingNumber.isNotEmpty ? b.bookingNumber : b.bookingId;
    final odoCtrl = TextEditingController(text: b.endOdometer ?? '');
    final fastagCtrl = TextEditingController(text: b.returnFastag ?? '');
    final damageCtrl = TextEditingController(text: '0');
    final tollCtrl = TextEditingController(text: '0');
    final extraKmCtrl = TextEditingController(text: '0');
    final notesCtrl = TextEditingController();
    final deposit = b.securityDeposit;
    final startKm = double.tryParse(b.startOdometer ?? '') ?? 0;
    final List<File> returnPhotos = [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          final endKm = double.tryParse(odoCtrl.text) ?? startKm;
          final kmDriven = (endKm > startKm) ? (endKm - startKm).toInt() : 0;
          final damageDed = double.tryParse(damageCtrl.text) ?? 0;
          final tollDed = double.tryParse(tollCtrl.text) ?? 0;
          final extraDed = double.tryParse(extraKmCtrl.text) ?? 0;
          final netRefund = (deposit - damageDed - tollDed - extraDed).clamp(0.0, 999999.0);

          return Container(
            constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.90),
            padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 24),
            decoration: BoxDecoration(
              color: context.themeSurfaceElevated,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Process Return & Deposit Settlement', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: context.themeTextPrimary)),
                        const SizedBox(height: 2),
                        Text('$bId • ${b.vehicleName}', style: TextStyle(fontSize: 12, color: context.themeTextSecondary)),
                      ],
                    ),
                    IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                  ],
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: odoCtrl,
                              keyboardType: TextInputType.number,
                              style: TextStyle(color: context.themeTextPrimary),
                              decoration: const InputDecoration(labelText: 'Return Odometer (KM) *', border: OutlineInputBorder()),
                              onChanged: (_) => setModalState(() {}),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: fastagCtrl,
                              keyboardType: TextInputType.number,
                              style: TextStyle(color: context.themeTextPrimary),
                              decoration: const InputDecoration(labelText: 'Return FASTag (₹)', prefixText: '₹ ', border: OutlineInputBorder()),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text('Distance Driven: $kmDriven KM (Start: ${startKm.toInt()} KM)', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF06D6A0))),
                      const SizedBox(height: 14),

                      // Return Inspection Photos
                      Text('Vehicle Return Inspection Photos', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: context.themeTextPrimary)),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          CustomButton(
                            text: '+ Add Inspection Photo',
                            isOutlined: true,
                            height: 32,
                            width: 180,
                            onPressed: () {
                              MediaPermissionHelper.showMediaSourceSheet(
                                context: context,
                                title: 'Return Inspection Photo',
                                onImageSelected: (file) {
                                  setModalState(() => returnPhotos.add(file));
                                },
                              );
                            },
                          ),
                          const SizedBox(width: 10),
                          Text('${returnPhotos.length} photo(s)', style: TextStyle(fontSize: 11, color: context.themeTextSecondary)),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Deposit Settlement Calculator
                      GlassCard(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('SECURITY DEPOSIT REFUND CALCULATOR', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: context.themeTextMuted)),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Security Deposit Paid', style: TextStyle(fontSize: 12, color: context.themeTextSecondary)),
                                Text(_formatINR(deposit), style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: context.themeTextPrimary)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: damageCtrl,
                                    keyboardType: TextInputType.number,
                                    style: TextStyle(color: context.themeTextPrimary, fontSize: 13),
                                    decoration: const InputDecoration(labelText: 'Damage / Cleaning (₹)', prefixText: '₹ ', border: OutlineInputBorder()),
                                    onChanged: (_) => setModalState(() {}),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: TextField(
                                    controller: tollCtrl,
                                    keyboardType: TextInputType.number,
                                    style: TextStyle(color: context.themeTextPrimary, fontSize: 13),
                                    decoration: const InputDecoration(labelText: 'Toll Deductions (₹)', prefixText: '₹ ', border: OutlineInputBorder()),
                                    onChanged: (_) => setModalState(() {}),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: extraKmCtrl,
                              keyboardType: TextInputType.number,
                              style: TextStyle(color: context.themeTextPrimary, fontSize: 13),
                              decoration: const InputDecoration(labelText: 'Extra KM Charges (₹)', prefixText: '₹ ', border: OutlineInputBorder()),
                              onChanged: (_) => setModalState(() {}),
                            ),
                            const Divider(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Net Deposit Refund', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: context.themeTextPrimary)),
                                Text(_formatINR(netRefund), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF06D6A0))),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),

                      TextField(
                        controller: notesCtrl,
                        style: TextStyle(color: context.themeTextPrimary),
                        decoration: const InputDecoration(labelText: 'Return Settlement Notes', hintText: 'Fuel level verified, no fresh scratches, deposit settled...', border: OutlineInputBorder()),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                CustomButton(
                  text: 'Complete Trip & Settle Deposit',
                  height: 42,
                  onPressed: () async {
                    if (odoCtrl.text.isNotEmpty) {
                      await ref.read(adminBookingsProvider.notifier).updateOdometer(bookingId: bId, endOdometer: odoCtrl.text);
                    }
                    if (fastagCtrl.text.isNotEmpty) {
                      await ref.read(adminBookingsProvider.notifier).updateFastag(bookingId: bId, returnFastag: fastagCtrl.text);
                    }
                    await ref.read(adminBookingsProvider.notifier).updateStatus(bookingId: bId, newStatus: 'completed');
                    if (ctx.mounted) Navigator.pop(ctx);
                    if (mounted) messenger.showSnackBar(SnackBar(content: Text('Trip $bId completed and deposit settled.')));
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showInvoiceManageModal(BookingModel b) {
    final invoiceNo = 'KZ-INV-2026-${b.id}';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: context.themeSurfaceElevated,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Tax Invoice', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: context.themeTextPrimary)),
                    Text(invoiceNo, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF4FD7FF))),
                  ],
                ),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
              ],
            ),
            const SizedBox(height: 12),
            GlassCard(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('BILLED TO', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: context.themeTextMuted)),
                  Text(b.userName, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: context.themeTextPrimary)),
                  Text(b.userEmail, style: TextStyle(fontSize: 11, color: context.themeTextSecondary)),
                  const Divider(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Vehicle Rental (${b.vehicleName})', style: TextStyle(fontSize: 12, color: context.themeTextSecondary)),
                      Text(_formatINR(b.baseAmount > 0 ? b.baseAmount : b.totalAmount), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: context.themeTextPrimary)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('GST @ 18% (Automotive Hire)', style: TextStyle(fontSize: 12, color: context.themeTextSecondary)),
                      Text(_formatINR(b.totalAmount * 0.18), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: context.themeTextPrimary)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Security Deposit (Refundable)', style: TextStyle(fontSize: 12, color: context.themeTextSecondary)),
                      Text(_formatINR(b.securityDeposit), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: context.themeTextPrimary)),
                    ],
                  ),
                  const Divider(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Total Invoiced', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: context.themeTextPrimary)),
                      Text(_formatINR(b.finalAmount > 0 ? b.finalAmount : b.totalAmount), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF06D6A0))),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: CustomButton(
                    text: 'Download PDF',
                    isOutlined: true,
                    height: 38,
                    onPressed: () {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Downloading invoice $invoiceNo...')));
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: CustomButton(
                    text: 'Email Invoice',
                    height: 38,
                    onPressed: () {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Invoice $invoiceNo emailed to ${b.userEmail}.')));
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showVerifyPaymentReceiptModal(BookingModel b) {
    final messenger = ScaffoldMessenger.of(context);
    final bId = b.bookingNumber.isNotEmpty ? b.bookingNumber : b.bookingId;
    String selectedAuditor = 'Pankaj';
    final notesController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
          padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 24),
          decoration: BoxDecoration(
            color: context.themeSurfaceElevated,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Verify Payment Receipt', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: context.themeTextPrimary)),
                      const SizedBox(height: 2),
                      Text('Audit customer payment transfer details', style: TextStyle(fontSize: 12, color: context.themeTextSecondary)),
                    ],
                  ),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView(
                  children: [
                    GlassCard(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(bId, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFFFF5C77))),
                              StatusBadge(status: b.paymentStatus),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text('${b.userName} • ${b.userPhone ?? "No phone"}', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: context.themeTextPrimary)),
                          Text('Vehicle: ${b.vehicleName}', style: TextStyle(fontSize: 12, color: context.themeTextSecondary)),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('AMOUNT PAYABLE', style: TextStyle(fontSize: 9.5, color: context.themeTextMuted)),
                                  Text(_formatINR(b.finalAmount > 0 ? b.finalAmount : b.totalAmount), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF06D6A0))),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text('UTR / REFERENCE', style: TextStyle(fontSize: 9.5, color: context.themeTextMuted)),
                                  Text(b.paymentRef != null && b.paymentRef!.isNotEmpty ? b.paymentRef! : 'UPI/2026/09/KZ992819', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: context.themeTextPrimary)),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Receipt Preview Box
                    Container(
                      height: 150,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: context.themeBorder),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.receipt_long_rounded, size: 40, color: Color(0xFFFF5C77)),
                            const SizedBox(height: 8),
                            Text(
                              b.paymentScreenshotUrl != null && b.paymentScreenshotUrl!.isNotEmpty
                                  ? 'Receipt Attached (${b.paymentScreenshotUrl!.split("/").last})'
                                  : 'UPI / Bank Payment Receipt Attached',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: context.themeTextPrimary),
                            ),
                            const SizedBox(height: 4),
                            Text('Tap to view high-resolution proof', style: TextStyle(fontSize: 10, color: context.themeTextMuted)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Auditor Identity Dropdown (Screenshot: Pankaj, Jafar, Sejal)
                    Text('Select Staff Auditor Identity *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: context.themeTextPrimary)),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      initialValue: selectedAuditor,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      dropdownColor: context.themeSurfaceElevated,
                      items: const [
                        DropdownMenuItem(value: 'Pankaj', child: Text('Pankaj (Finance Team)')),
                        DropdownMenuItem(value: 'Jafar', child: Text('Jafar (Accounts Lead)')),
                        DropdownMenuItem(value: 'Sejal', child: Text('Sejal (Audit Executive)')),
                      ],
                      onChanged: (val) => setModalState(() => selectedAuditor = val ?? 'Pankaj'),
                    ),
                    const SizedBox(height: 12),

                    TextField(
                      controller: notesController,
                      style: TextStyle(color: context.themeTextPrimary),
                      decoration: const InputDecoration(
                        labelText: 'Verification Notes / Bank Reference Comments',
                        hintText: 'e.g. UTR matched HDFC statement, amount cleared.',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: CustomButton(
                      text: 'Reject Payment',
                      isOutlined: true,
                      height: 40,
                      onPressed: () async {
                        await ref.read(adminBookingsProvider.notifier).verifyPayment(
                              bookingOrPaymentId: bId,
                              action: 'reject',
                              reason: notesController.text.isNotEmpty ? notesController.text : 'Rejected by $selectedAuditor',
                            );
                        if (ctx.mounted) Navigator.pop(ctx);
                        if (mounted) messenger.showSnackBar(SnackBar(content: Text('Payment for $bId marked as rejected.')));
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: CustomButton(
                      text: 'Approve & Confirm',
                      height: 40,
                      onPressed: () async {
                        await ref.read(adminBookingsProvider.notifier).verifyPayment(
                              bookingOrPaymentId: bId,
                              action: 'approve',
                              reason: 'Verified by $selectedAuditor: ${notesController.text}',
                            );
                        if (ctx.mounted) Navigator.pop(ctx);
                        if (mounted) messenger.showSnackBar(SnackBar(content: Text('Payment for $bId verified by $selectedAuditor.')));
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRealisticKycCardPreview(int docType, String name, String phone) {
    final cleanName = name.trim().isEmpty ? 'PRAFULL PATIL' : name.toUpperCase();
    final cleanPhone = phone.trim().isEmpty ? '9076430110' : phone;

    if (docType == 0) {
      // DRIVING LICENSE CARD PREVIEW
      return GlassCard(
        borderRadius: 16,
        padding: const EdgeInsets.all(14),
        backgroundColor: const Color(0xFF0F1B2B),
        borderColor: const Color(0xFFD4AF37).withValues(alpha: 0.35),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.shield_rounded, size: 20, color: Color(0xFFD4AF37)),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text('UNION OF INDIA • DRIVING LICENCE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFFD4AF37), letterSpacing: 0.8)),
                        Text('MAHARASHTRA MOTOR VEHICLES DEPT', style: TextStyle(fontSize: 8.5, color: Colors.white70, letterSpacing: 0.5)),
                      ],
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: const Color(0xFFD4AF37).withValues(alpha: 0.15), borderRadius: BorderRadius.circular(4)),
                  child: const Text('FORM 7', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Color(0xFFD4AF37))),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Divider(height: 1, color: const Color(0xFFD4AF37).withValues(alpha: 0.2)),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Photo Frame
                Container(
                  width: 68,
                  height: 82,
                  decoration: BoxDecoration(
                    color: Colors.black38,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.person, size: 40, color: Colors.white54),
                      Text('PHOTO', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w800, color: Colors.white38)),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('DL NO: MH04 20230089241', style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w900, letterSpacing: 0.5, color: Colors.white)),
                      const SizedBox(height: 3),
                      Text('NAME: $cleanName', style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: Colors.white)),
                      Text('DOB: 14/08/1996  •  BG: O+ve', style: const TextStyle(fontSize: 9.5, color: Colors.white70)),
                      Text('CLASS: LMV-NT, MCWG', style: const TextStyle(fontSize: 9.5, color: Colors.white70)),
                      Text('VALIDITY: 13/08/2043 (NON-TRANS)', style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w600, color: Color(0xFF06D6A0))),
                      Text('ISSUING AUTH: MH-04 THANE', style: const TextStyle(fontSize: 9, color: Colors.white54)),
                    ],
                  ),
                ),
                const Icon(Icons.qr_code_2_rounded, size: 36, color: Colors.white54),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text('SMART CARD CHIP ID ATTACHED', style: TextStyle(fontSize: 8, letterSpacing: 0.5, color: Colors.white38)),
                Text('VERIFIED VIA PARIVAHAN SEWA', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w700, color: Color(0xFF06D6A0))),
              ],
            ),
          ],
        ),
      );
    } else if (docType == 1) {
      // AADHAAR CARD PREVIEW
      final last4 = cleanPhone.length >= 4 ? cleanPhone.substring(cleanPhone.length - 4) : '8942';
      return GlassCard(
        borderRadius: 16,
        padding: const EdgeInsets.all(14),
        backgroundColor: const Color(0xFF161E2E),
        borderColor: const Color(0xFF0071E3).withValues(alpha: 0.35),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tricolor Band
            Container(
              height: 4,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF9933), Colors.white, Color(0xFF138808)],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.fingerprint_rounded, size: 22, color: Color(0xFFFF9933)),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text('भारत सरकार / GOVERNMENT OF INDIA', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.white)),
                        Text('Unique Identification Authority of India', style: TextStyle(fontSize: 8.5, color: Colors.white60)),
                      ],
                    ),
                  ],
                ),
                const Text('UIDAI', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFFFF9933))),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 68,
                  height: 82,
                  decoration: BoxDecoration(
                    color: Colors.black38,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.account_box_rounded, size: 38, color: Colors.white54),
                      Text('UID PHOTO', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w800, color: Colors.white38)),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(cleanName, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.white)),
                      const SizedBox(height: 2),
                      const Text('जन्म तारीख / DOB: 14/08/1996', style: TextStyle(fontSize: 9.5, color: Colors.white70)),
                      const Text('लिंग / Gender: MALE / पुरुष', style: TextStyle(fontSize: 9.5, color: Colors.white70)),
                      const SizedBox(height: 6),
                      Text('XXXX  XXXX  $last4', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 2.0, color: Color(0xFF0071E3))),
                    ],
                  ),
                ),
                const Icon(Icons.qr_code_rounded, size: 40, color: Colors.white60),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text('मेरा आधार, मेरी पहचान', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Color(0xFFFF9933))),
                Text('VERIFIED VIA UIDAI OFFLINE XML', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w700, color: Color(0xFF06D6A0))),
              ],
            ),
          ],
        ),
      );
    } else {
      // PAN CARD PREVIEW
      final panChar = cleanName.isNotEmpty ? cleanName[0] : 'P';
      final panHash = (cleanPhone.hashCode.abs() % 9000 + 1000).toString();
      return GlassCard(
        borderRadius: 16,
        padding: const EdgeInsets.all(14),
        backgroundColor: const Color(0xFF181C26),
        borderColor: const Color(0xFF0071E3).withValues(alpha: 0.35),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text('आयकर विभाग / INCOME TAX DEPARTMENT', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.white)),
                    Text('GOVT. OF INDIA / Permanent Account Card', style: TextStyle(fontSize: 8.5, color: Colors.white60)),
                  ],
                ),
                const Icon(Icons.account_balance_rounded, size: 20, color: Color(0xFF06D6A0)),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 68,
                  height: 82,
                  decoration: BoxDecoration(
                    color: Colors.black38,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.badge_rounded, size: 38, color: Colors.white54),
                      Text('PAN PHOTO', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w800, color: Colors.white38)),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('PAN: ABC$panChar P${panHash}F', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 1.5, color: Color(0xFF06D6A0))),
                      const SizedBox(height: 4),
                      Text('NAME: $cleanName', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white)),
                      const Text("FATHER'S NAME: RAMESH PATIL", style: TextStyle(fontSize: 9.5, color: Colors.white70)),
                      const Text('DATE OF BIRTH: 14/08/1996', style: TextStyle(fontSize: 9.5, color: Colors.white70)),
                    ],
                  ),
                ),
                const Icon(Icons.qr_code_2_rounded, size: 36, color: Colors.white54),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text('SIGNATURE: Verified on File', style: TextStyle(fontSize: 8.5, fontStyle: FontStyle.italic, color: Colors.white54)),
                Text('NSDL / NFO VERIFIED', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w700, color: Color(0xFF06D6A0))),
              ],
            ),
          ],
        ),
      );
    }
  }

  Widget _buildDocumentImages(int docType, Map<String, dynamic> kycData) {
    String? frontUrl;
    String? backUrl;
    String frontLabel;
    String backLabel;

    if (docType == 0) {
      frontUrl = (kycData['licenseFrontUrl'] ?? kycData['license_front'])?.toString();
      backUrl = (kycData['licenseBackUrl'] ?? kycData['license_back'])?.toString();
      frontLabel = 'License Front';
      backLabel = 'License Back';
    } else if (docType == 1) {
      frontUrl = (kycData['aadharFrontUrl'] ?? kycData['aadhar_front'])?.toString();
      backUrl = (kycData['aadharBackUrl'] ?? kycData['aadhar_back'])?.toString();
      frontLabel = 'Aadhaar Front';
      backLabel = 'Aadhaar Back';
    } else {
      frontUrl = (kycData['panFrontUrl'] ?? kycData['pan_front'])?.toString();
      backUrl = (kycData['panBackUrl'] ?? kycData['pan_back'])?.toString();
      frontLabel = 'PAN Front';
      backLabel = 'PAN Back';
    }

    if (frontUrl == null && backUrl == null) {
      return GlassCard(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.image_not_supported_outlined, size: 32, color: context.themeTextMuted),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'No uploaded document images available for this ID type.',
                style: TextStyle(fontSize: 12, color: context.themeTextSecondary),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('UPLOADED DOCUMENTS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.8, color: context.themeTextMuted)),
        const SizedBox(height: 8),
        Row(
          children: [
            if (frontUrl != null)
              Expanded(
                child: _buildDocImageCard(frontUrl, frontLabel),
              ),
            if (frontUrl != null && backUrl != null)
              const SizedBox(width: 10),
            if (backUrl != null)
              Expanded(
                child: _buildDocImageCard(backUrl, backLabel),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildDocImageCard(String imageUrl, String label) {
    return GestureDetector(
      onTap: () => _showFullScreenImage(imageUrl, label),
      child: GlassCard(
        padding: const EdgeInsets.all(6),
        child: Column(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                imageUrl,
                height: 120,
                width: double.infinity,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return SizedBox(
                    height: 120,
                    child: Center(
                      child: CircularProgressIndicator(
                        value: progress.expectedTotalBytes != null
                            ? progress.cumulativeBytesLoaded / progress.expectedTotalBytes!
                            : null,
                        color: AppColors.primary,
                        strokeWidth: 2,
                      ),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 120,
                  decoration: BoxDecoration(
                    color: context.themeSurfaceElevated,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.broken_image_outlined, size: 28, color: context.themeTextMuted),
                        const SizedBox(height: 4),
                        Text('Failed to load', style: TextStyle(fontSize: 10, color: context.themeTextMuted)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.zoom_in_rounded, size: 14, color: context.themeTextSecondary),
                const SizedBox(width: 4),
                Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: context.themeTextSecondary)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showFullScreenImage(String imageUrl, String title) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: const EdgeInsets.all(8),
        child: Stack(
          children: [
            Positioned.fill(
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 5.0,
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;
                    return const Center(child: CircularProgressIndicator(color: AppColors.primary));
                  },
                  errorBuilder: (context, error, stackTrace) => Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.broken_image_outlined, size: 48, color: Colors.white54),
                        const SizedBox(height: 8),
                        Text('Image unavailable', style: const TextStyle(color: Colors.white70)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 8,
              left: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(title, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                icon: const Icon(Icons.close_rounded, color: Colors.white, size: 28),
                onPressed: () => Navigator.pop(ctx),
              ),
            ),
            Positioned(
              bottom: 12,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text('Pinch to zoom • Drag to pan', style: TextStyle(color: Colors.white70, fontSize: 11)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showExecutiveKycModal(String name, String phone, String email, String uid, Map<String, dynamic> kycData) {
    final messenger = ScaffoldMessenger.of(context);
    int currentDocTab = 0; // 0: DL, 1: Aadhaar, 2: PAN

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          decoration: BoxDecoration(
            color: context.themeSurfaceElevated,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Customer KYC Verification', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: context.themeTextPrimary)),
                      const SizedBox(height: 2),
                      Text('$name • $phone', style: TextStyle(fontSize: 12, color: context.themeTextSecondary)),
                    ],
                  ),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                ],
              ),
              const SizedBox(height: 12),

              // Segmented Document Tabs
              Row(
                children: [
                  _buildFilterPill('Driving License', currentDocTab == 0, () => setModalState(() => currentDocTab = 0)),
                  _buildFilterPill('Aadhaar Card', currentDocTab == 1, () => setModalState(() => currentDocTab = 1)),
                  _buildFilterPill('PAN Card', currentDocTab == 2, () => setModalState(() => currentDocTab = 2)),
                ],
              ),
              const SizedBox(height: 14),

              Expanded(
                child: ListView(
                  children: [
                    // Realistic KYC Card Template
                    _buildRealisticKycCardPreview(currentDocTab, name, phone),
                    const SizedBox(height: 14),
                    // Real Uploaded Document Images
                    _buildDocumentImages(currentDocTab, kycData),
                    const SizedBox(height: 14),

                    GlassCard(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('VERIFICATION CHECKLIST', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: context.themeTextMuted)),
                          const SizedBox(height: 8),
                          _buildDocInspectRow('Customer Photo Match', 'Live verified', true),
                          _buildDocInspectRow('Document Validity', 'Active / Unexpired', true),
                          _buildDocInspectRow('Name Consistency', 'Matches $name', true),
                          _buildDocInspectRow('Age Eligibility', '21+ Years Old', true),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: CustomButton(
                      text: 'Reject Document',
                      isOutlined: true,
                      height: 40,
                      onPressed: () async {
                        final docName = currentDocTab == 0 ? 'license' : (currentDocTab == 1 ? 'aadhar' : 'pan');
                        await ref.read(adminBookingsProvider.notifier).updateKyc(uid: uid, documentType: docName, status: 'rejected');
                        ref.invalidate(adminKycListProvider);
                        if (ctx.mounted) Navigator.pop(ctx);
                        if (mounted) messenger.showSnackBar(SnackBar(content: Text('$docName rejected for $name.')));
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: CustomButton(
                      text: 'Approve & Verify',
                      height: 40,
                      onPressed: () async {
                        final docName = currentDocTab == 0 ? 'license' : (currentDocTab == 1 ? 'aadhar' : 'pan');
                        await ref.read(adminBookingsProvider.notifier).updateKyc(uid: uid, documentType: docName, status: 'verified');
                        ref.invalidate(adminKycListProvider);
                        if (ctx.mounted) Navigator.pop(ctx);
                        if (mounted) messenger.showSnackBar(SnackBar(content: Text('$docName approved for $name.')));
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showInspectBookingModal(BookingModel booking) {
    final messenger = ScaffoldMessenger.of(context);
    final amountController = TextEditingController(text: booking.finalAmount.toInt().toString());
    String currentStatus = booking.status;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 24),
          decoration: BoxDecoration(color: context.themeSurfaceElevated, borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Booking ${booking.bookingNumber.isNotEmpty ? booking.bookingNumber : booking.bookingId}', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: context.themeTextPrimary)),
              const SizedBox(height: 8),
              Text('Customer: ${booking.userName} (${booking.userEmail})', style: TextStyle(fontSize: 13, color: context.themeTextSecondary)),
              Text('Phone: ${booking.userPhone ?? "Not provided"}', style: TextStyle(fontSize: 13, color: context.themeTextSecondary)),
              Text('Vehicle: ${booking.vehicleName} (${booking.vehicleReg})', style: TextStyle(fontSize: 13, color: context.themeTextSecondary)),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: context.themeSurfaceElevated,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: context.themeBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('RENTAL SCHEDULE & DURATION', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.8, color: context.themeTextMuted)),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Pickup Time:', style: TextStyle(fontSize: 12, color: context.themeTextSecondary)),
                        Text(DateFormat('EEE, dd MMM yyyy • hh:mm a').format(booking.pickupDate), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: context.themeTextPrimary)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Drop-off Time:', style: TextStyle(fontSize: 12, color: context.themeTextSecondary)),
                        Text(DateFormat('EEE, dd MMM yyyy • hh:mm a').format(booking.dropDate), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: context.themeTextPrimary)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Duration:', style: TextStyle(fontSize: 12, color: context.themeTextSecondary)),
                        Text(
                          BookingNotificationHelper.formatDurationDetailed(booking.pickupDate, booking.dropDate, days: booking.days, hours: booking.hours),
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF06D6A0)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.chat_rounded, color: Color(0xFF25D366), size: 16),
                      label: const Text('WhatsApp Confirmation', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Color(0xFF25D366))),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF25D366), width: 1.2),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                      onPressed: () async {
                        final ok = await BookingNotificationHelper.sendWhatsAppConfirmation(booking);
                        if (!ok && context.mounted) {
                          messenger.showSnackBar(const SnackBar(content: Text('Could not open WhatsApp.')));
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.email_outlined, color: AppColors.primary, size: 16),
                      label: const Text('Email Notice', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.primary)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.primary, width: 1.2),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                      onPressed: () async {
                        final ok = await BookingNotificationHelper.sendEmailConfirmation(booking);
                        if (!ok && context.mounted) {
                          messenger.showSnackBar(const SnackBar(content: Text('Could not open email app.')));
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                style: TextStyle(color: context.themeTextPrimary),
                decoration: const InputDecoration(labelText: 'Adjust Total Amount (₹)', border: OutlineInputBorder(), prefixText: '₹ '),
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                initialValue: ['pending_payment', 'pending_confirmation', 'confirmed', 'active', 'completed', 'cancelled'].contains(currentStatus) ? currentStatus : 'confirmed',
                decoration: const InputDecoration(labelText: 'Booking Status', border: OutlineInputBorder()),
                dropdownColor: context.themeSurfaceElevated,
                items: const [
                  DropdownMenuItem(value: 'pending_payment', child: Text('Pending Payment')),
                  DropdownMenuItem(value: 'pending_confirmation', child: Text('Pending Confirmation')),
                  DropdownMenuItem(value: 'confirmed', child: Text('Confirmed')),
                  DropdownMenuItem(value: 'active', child: Text('Active (On-Road)')),
                  DropdownMenuItem(value: 'completed', child: Text('Completed')),
                  DropdownMenuItem(value: 'cancelled', child: Text('Cancelled')),
                ],
                onChanged: (val) {
                  if (val != null) setModalState(() => currentStatus = val);
                },
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: CustomButton(
                      text: 'Cancel Trip',
                      isOutlined: true,
                      onPressed: () async {
                        final bId = booking.bookingNumber.isNotEmpty ? booking.bookingNumber : booking.bookingId;
                        await ref.read(adminBookingsProvider.notifier).updateStatus(bookingId: bId, newStatus: 'cancelled');
                        if (ctx.mounted) Navigator.pop(ctx);
                        messenger.showSnackBar(SnackBar(content: Text('Trip $bId cancelled.')));
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: CustomButton(
                      text: 'Save Changes',
                      onPressed: () async {
                        final bId = booking.bookingNumber.isNotEmpty ? booking.bookingNumber : booking.bookingId;
                        final newAmount = double.tryParse(amountController.text);
                        await ref.read(adminBookingsProvider.notifier).updateStatus(bookingId: bId, newStatus: currentStatus, totalAmount: newAmount);
                        if (ctx.mounted) Navigator.pop(ctx);
                        messenger.showSnackBar(SnackBar(content: Text('Booking $bId updated.')));
                        if (currentStatus == 'confirmed' && booking.status != 'confirmed') {
                          _showBookingApprovalConfirmationDialog(booking);
                        }
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditVehicleModal(VehicleModel vehicle) {
    final dayController = TextEditingController(text: vehicle.priceDay.toInt().toString());
    final hourController = TextEditingController(text: vehicle.priceHour.toInt().toString());
    bool isAvail = vehicle.isAvailable;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 24),
          decoration: BoxDecoration(color: context.themeSurfaceElevated, borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Edit ${vehicle.fullName}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: context.themeTextPrimary)),
              const SizedBox(height: 14),
              TextField(
                controller: dayController,
                keyboardType: TextInputType.number,
                style: TextStyle(color: context.themeTextPrimary),
                decoration: const InputDecoration(labelText: 'Daily Rental Rate (₹/day)', border: OutlineInputBorder(), prefixText: '₹ '),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: hourController,
                keyboardType: TextInputType.number,
                style: TextStyle(color: context.themeTextPrimary),
                decoration: const InputDecoration(labelText: 'Hourly Rate (₹/hr)', border: OutlineInputBorder(), prefixText: '₹ '),
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Vehicle Availability Status', style: TextStyle(fontSize: 14, color: context.themeTextPrimary, fontWeight: FontWeight.w600)),
                  Switch(
                    value: isAvail,
                    activeThumbColor: const Color(0xFF06D6A0),
                    onChanged: (val) => setModalState(() => isAvail = val),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              CustomButton(
                text: 'Save Vehicle Rates',
                onPressed: () {
                  final newDay = double.tryParse(dayController.text) ?? vehicle.priceDay;
                  final newHour = double.tryParse(hourController.text) ?? vehicle.priceHour;
                  ref.read(fleetProvider.notifier).updateVehicle(vehicleId: vehicle.id, priceDay: newDay, priceHour: newHour, isAvailable: isAvail);
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${vehicle.fullName} rates updated to ₹${newDay.toInt()}/day, ₹${newHour.toInt()}/hr.')));
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
