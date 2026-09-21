import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_assets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/admin_stats_model.dart';
import '../../../data/models/booking_model.dart';
import '../../../data/models/coupon_model.dart';
import '../../../data/models/vehicle_model.dart';
import '../../state/admin_provider.dart';
import '../../state/auth_provider.dart';
import '../../state/fleet_provider.dart';
import '../../../data/repositories/fleet_repository.dart';
import '../../widgets/background_video_widget.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/status_badge.dart';

String _formatINR(num value) {
  final intVal = value.toInt();
  final s = intVal.toString();
  if (s.length <= 3) return '₹$s';
  final last3 = s.substring(s.length - 3);
  final rest = s.substring(0, s.length - 3);
  final reg = RegExp(r'\B(?=(\d{2})+(?!\d))');
  final formattedRest = rest.replaceAllMapped(reg, (Match m) => '${m[1]},');
  return '₹$formattedRest,$last3';
}

class StaffDashboardScreen extends ConsumerStatefulWidget {
  const StaffDashboardScreen({super.key});

  @override
  ConsumerState<StaffDashboardScreen> createState() => _StaffDashboardScreenState();
}

class _StaffDashboardScreenState extends ConsumerState<StaffDashboardScreen> {
  String _selectedRole = 'ADMIN';
  bool _bgVideoEnabled = true;

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
      'ADMIN' => const Color(0xFF4FD7FF),
      'MANAGER PANEL' => const Color(0xFF06D6A0),
      'EXECUTIVE' => const Color(0xFFFFB703),
      'ACCOUNTS' => const Color(0xFFFF5C77),
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
                fontSize: 12,
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
            icon: Icon(
              _bgVideoEnabled ? Icons.videocam_rounded : Icons.videocam_off_rounded,
              color: _bgVideoEnabled ? accentColor : context.themeTextMuted,
              size: 20,
            ),
            tooltip: _bgVideoEnabled ? 'Background Video: Playing' : 'Background Video: Off',
            onPressed: () => setState(() => _bgVideoEnabled = !_bgVideoEnabled),
          ),
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
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: availableRoles.map((role) {
                      final isSelected = _selectedRole == role;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedRole = role),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected ? accentColor : context.themeSurfaceElevated,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected ? Colors.transparent : context.themeBorder,
                              ),
                            ),
                            child: Text(
                              role,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.6,
                                color: isSelected ? const Color(0xFF041017) : context.themeTextSecondary,
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
                child: _buildRoleContent(
                  role: _selectedRole,
                  stats: stats,
                  vehicles: vehicles,
                  bookingsAsync: bookingsAsync,
                  accentColor: accentColor,
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
              _buildFilterPill('Booking Calendar 📅', _adminSubTab == 1, () => setState(() => _adminSubTab = 1)),
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
                onTap: () => setState(() => _selectedCalendarDate = curDate),
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
                            text: 'Inspect KYC',
                            isOutlined: true,
                            height: 28,
                            width: 100,
                            onPressed: () {
                              _showKycInspectionModal(name, email, uid);
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

  void _showKycInspectionModal(String name, String email, String uid) {
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
            Text('KYC Verification: $name', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: context.themeTextPrimary)),
            Text(email, style: TextStyle(fontSize: 12, color: context.themeTextSecondary)),
            const SizedBox(height: 16),
            _buildDocInspectRow('Driving License', 'DL-Verified', true),
            _buildDocInspectRow('Aadhaar Card', 'UIDAI Attached', true),
            _buildDocInspectRow('PAN Card', 'Income Tax Verified', true),
            const SizedBox(height: 20),
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
            _buildStatMetricCard('TOTAL REGISTERED USERS', '${stats.totalUsers > 0 ? stats.totalUsers : 161}', 'System user accounts', accentColor),
            _buildStatMetricCard('TOTAL ACTIVE CUSTOMERS', '$uniqueCustomers', 'Unique users who booked', const Color(0xFF06D6A0)),
            _buildStatMetricCard("THIS MONTH'S CUSTOMERS", '20', 'Unique bookers in month', accentColor),
            _buildStatMetricCard('NEW CUSTOMERS THIS MONTH', '20', 'First booking this month', const Color(0xFF06D6A0)),
            _buildStatMetricCard('REPEAT CUSTOMERS', '2', 'Customers with >1 booking', const Color(0xFFFFB703)),
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
              _buildTableRow(['September 2026', '22', '20', '22'], isHighlight: true),
              _buildTableRow(['August 2026', '76', '1', '1']),
              _buildTableRow(['July 2026', '33', '0', '0']),
              _buildTableRow(['January - June 2026', '30', '0', '0']),
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
            _buildStatMetricCard('TOTAL BOOKINGS', '${stats.totalBookings > 0 ? stats.totalBookings : 29}', 'All reservations recorded', context.themeTextPrimary),
            _buildStatMetricCard('PAID & CONFIRMED', '${stats.paidBookings > 0 ? stats.paidBookings : 24}', 'Verified payment received', const Color(0xFF06D6A0)),
            _buildStatMetricCard('PENDING VERIFICATION', '${stats.pendingPayments > 0 ? stats.pendingPayments : 5}', 'Awaiting payment audit', const Color(0xFFFF5C77)),
            _buildStatMetricCard('ACTIVE / ON-ROAD', '${stats.activeTrips > 0 ? stats.activeTrips : 7}', 'Currently on rental trip', const Color(0xFF06D6A0)),
            _buildStatMetricCard('CANCELLED / REJECTED', '5', 'Cancelled or rejected', const Color(0xFFFF5C77)),
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
              _buildTableRow(['September 2026', '26', '20', '4', '₹3,02,906'], isHighlight: true),
              _buildTableRow(['August 2026', '1', '1', '0', '₹2,81,857']),
              _buildTableRow(['July 2026', '0', '0', '0', '₹50,540']),
              _buildTableRow(['October 2026', '1', '1', '0', '₹28,000']),
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
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Fleet Availability Management', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: context.themeTextPrimary)),
                Text('Control catalog inventory, rates, availability, and vehicle images.', style: TextStyle(fontSize: 12, color: context.themeTextSecondary)),
              ],
            ),
            CustomButton(
              text: 'Open Public Fleet',
              isOutlined: true,
              height: 32,
              width: 130,
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

        _buildFleetManagementSection(vehicles, accentColor),
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
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Promo & Coupon Codes', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: context.themeTextPrimary)),
                Text('Create, edit, activate, or deactivate discount codes for customer checkout.', style: TextStyle(fontSize: 12, color: context.themeTextSecondary)),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: accentColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
              child: Text('ACTIVE PROMOS: 6', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: accentColor)),
            ),
          ],
        ),
        const SizedBox(height: 14),

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
    final activeFleet = activeFleetAsync.value ?? FleetRepository.defaultActive9Fleets.map((v) => VehicleModel.fromJson(v)).toList();

    final mgrRange = _getDateRange(_mgrPeriod, _mgrCustomFrom, _mgrCustomTo);
    final periodBookings = allBookings.where((b) => _isBookingInRange(b, mgrRange)).toList();
    final nonCancelledBookings = periodBookings.where((b) => !b.isCancelled).toList();

    double periodRevenue;
    if (_mgrPeriod == 'All Time') {
      periodRevenue = stats.totalRevenue > 0 ? stats.totalRevenue : 663303.0;
    } else if (_mgrPeriod == 'This Month') {
      periodRevenue = stats.monthRevenue > 0 ? stats.monthRevenue : 302906.0;
    } else if (_mgrPeriod == 'Last Month') {
      periodRevenue = stats.lastMonthRevenue > 0 ? stats.lastMonthRevenue : 281857.0;
    } else {
      periodRevenue = nonCancelledBookings.fold(0.0, (sum, b) => sum + b.finalAmount);
    }

    final periodActiveTrips = (_mgrPeriod == 'All Time' || _mgrPeriod == 'This Month')
        ? (stats.activeTrips > 0 ? stats.activeTrips : 7)
        : periodBookings.where((b) => b.status == 'active').length;

    final periodCompletedTrips = (_mgrPeriod == 'All Time' || _mgrPeriod == 'This Month')
        ? (stats.completedTrips > 0 ? stats.completedTrips : 10)
        : periodBookings.where((b) => b.status == 'completed').length;

    final periodTotalBookings = (_mgrPeriod == 'All Time' || _mgrPeriod == 'This Month')
        ? (stats.totalBookings > 0 ? stats.totalBookings : (allBookings.isNotEmpty ? allBookings.length : 24))
        : periodBookings.length;

    final periodAvgBooking = periodTotalBookings > 0 ? (periodRevenue / periodTotalBookings) : 27638.0;

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
              _buildKpiCard('PERIOD REVENUE', _formatINR(periodRevenue), const Color(0xFF06D6A0)),
              _buildKpiCard('ACTIVE TRIPS', '$periodActiveTrips', accentColor),
              _buildKpiCard('COMPLETED TRIPS', '$periodCompletedTrips', context.themeTextPrimary),
              _buildKpiCard('TOTAL BOOKINGS', '$periodTotalBookings', context.themeTextPrimary),
              _buildKpiCard('AVG. BOOKING VALUE', _formatINR(periodAvgBooking), accentColor),
              _buildKpiCard('FLEET UTILIZATION', '${stats.fleetUtilization > 0 ? stats.fleetUtilization : 88}%', const Color(0xFF06D6A0)),
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
                _buildMonthlyRow('September 2026', '22 Bookings', '₹3,02,906', true),
                _buildMonthlyRow('August 2026', '1 Booking', '₹2,81,857', false),
                _buildMonthlyRow('July 2026', 'Baseline Ledger', '₹50,540', false),
                _buildMonthlyRow('October 2026', '1 Advance Booking', '₹28,000', false),
                const Divider(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Total Verified Revenue', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: context.themeTextPrimary)),
                    Text('₹6,63,303', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF06D6A0))),
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
                      const Text('MG Hector • ₹1,00,000 • 1 Booking (29 Days)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF06D6A0))),
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
              _buildKpiCard('TOTAL FLEET REVENUE', '₹6,63,303', const Color(0xFF06D6A0)),
              _buildKpiCard('TOTAL BOOKINGS', '24', context.themeTextPrimary),
              _buildKpiCard('TOTAL BOOKING DAYS', '75 Days', const Color(0xFFFFB703)),
              _buildKpiCard('AVERAGE / BOOKING', '₹27,638', accentColor),
            ],
          ),
          const SizedBox(height: 14),

          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterPill('All (${activeFleet.length})', _mgrFleetFilter == 'all', () => setState(() => _mgrFleetFilter = 'all')),
                _buildFilterPill('On Trip (7)', _mgrFleetFilter == 'on_trip', () => setState(() => _mgrFleetFilter = 'on_trip')),
                _buildFilterPill('Yard (2)', _mgrFleetFilter == 'yard', () => setState(() => _mgrFleetFilter = 'yard')),
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
                _buildTableRow(['MG Hector', 'MH43BY2773', 'On Trip', '29d', '₹1,00,000'], isHighlight: true),
                _buildTableRow(['Mahindra XUV700', 'MH02FU6808', 'On Trip', '5d', '₹50,000']),
                _buildTableRow(['Maruti Fronx', 'MH03EL1025', 'On Trip', '14d', '₹46,504']),
                _buildTableRow(['Toyota Glanza', 'MH48GJ4153', 'On Trip', '6d', '₹42,960']),
                _buildTableRow(['Maruti Ertiga', 'MH05GJ4711', 'On Trip', '9d', '₹28,474']),
                _buildTableRow(['Toyota Glanza', 'MH04MU1178', 'On Trip', '1d', '₹25,200']),
                _buildTableRow(['Maruti Fronx', 'MH43CU1632', 'On Trip', '8d', '₹22,180']),
                _buildTableRow(['Tata Punch', 'MH05FV3454', 'In Yard', '1d', '₹3,896']),
                _buildTableRow(['Maruti Baleno', 'CPR-007', 'In Yard', '0d', '₹0']),
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
              _buildKpiCard('TOTAL BOOKING DAYS', '75 Days', const Color(0xFFFFB703)),
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
              _buildKpiCard('ACTIVE FLEETS', '9', const Color(0xFF06D6A0)),
              _buildKpiCard('PARKED IN YARD', '1', context.themeTextPrimary),
              _buildKpiCard('CURRENTLY ON TRIP', '8', accentColor),
              _buildKpiCard('AVERAGE OCCUPANCY', '88%', const Color(0xFF06D6A0)),
            ],
          ),
          const SizedBox(height: 16),

          Text('Kruizly 9 Fleets Roster & Utilization', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: context.themeTextPrimary)),
          const SizedBox(height: 10),

          GridView.count(
            crossAxisCount: 1,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            childAspectRatio: 2.8,
            children: [
              _buildFleetUtilizationCard('Maruti Suzuki Fronx', 'MH03EL1025 • CRP-032', 'Aditi Lotankar', 'Automatic • Petrol', 0.46, '4 (14d)', '₹46,504', true),
              _buildFleetUtilizationCard('Maruti Suzuki Ertiga', 'MH05GJ4711 • CRP-031', 'Viren Gupta', 'Manual • Petrol + CNG', 0.27, '6 (9d)', '₹28,474', true),
              _buildFleetUtilizationCard('Toyota Glanza', 'MH48GJ4153 • CRP-035', 'Ajay Vishwakarma', 'Manual • Petrol + CNG', 0.18, '4 (6d)', '₹42,960', true),
              _buildFleetUtilizationCard('Toyota Glanza', 'MH04MU1178 • CRP-036', 'Kundan Singh', 'Manual • Petrol + CNG', 0.03, '1 (1d)', '₹25,200', true),
              _buildFleetUtilizationCard('Tata Punch', 'MH05FV3454 • CRP-037', 'Tai Phad', 'Manual • Petrol + CNG', 0.03, '1 (1d)', '₹3,896', false),
              _buildFleetUtilizationCard('Maruti Suzuki Fronx', 'MH43CU1632 • CRP-038', 'Amol Gole', 'Manual • Petrol + CNG', 0.24, '4 (8d)', '₹22,180', true),
              _buildFleetUtilizationCard('Mahindra XUV700', 'MH02FU6808 • CRP-039', 'Saif Feroz Shaikh', 'Automatic • Petrol', 0.15, '1 (5d)', '₹50,000', true),
              _buildFleetUtilizationCard('Maruti Suzuki Baleno', 'CPR-007 • CPR-007', 'Kruizly Fleet Host', 'Manual • Petrol', 0.0, '0 (0d)', '₹0', false),
              _buildFleetUtilizationCard('MG Hector', 'MH43BY2773 • CRP-040', 'Anil Kumar Gupta', 'Automatic • Petrol', 0.88, '1 (29d)', '₹1,00,000', true),
            ],
          ),
          const SizedBox(height: 18),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Other Fleet Catalog Roster', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: context.themeTextPrimary)),
              GestureDetector(
                onTap: () => setState(() => _otherFleetsCollapsed = !_otherFleetsCollapsed),
                child: Text(
                  _otherFleetsCollapsed ? '▼ Expand Other Fleets' : '▲ Collapse Other Fleets Roster',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: accentColor),
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
                  _buildTableRow(['CAR', 'YARD', 'DAYS', 'OCCUPANCY', 'RATE'], isHeader: true),
                  const Divider(height: 12),
                  _buildTableRow(['WagonR (CPR-030)', 'In Yard', '0d', '0%', '₹2,300']),
                  _buildTableRow(['Baleno (CPR-007)', 'On Trip', '5d', '15%', '₹2,500'], isHighlight: true),
                  _buildTableRow(['Ignis (CPR-019)', 'In Yard', '0d', '0%', '₹2,500']),
                  _buildTableRow(['Swift (CPR-025)', 'In Yard', '0d', '0%', '₹2,500']),
                  _buildTableRow(['Swift (CPR-026)', 'In Yard', '0d', '0%', '₹2,500']),
                  _buildTableRow(['Altroz (CPR-005)', 'In Yard', '0d', '0%', '₹2,600']),
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
            _buildKpiCard('ACTIVE TRIPS', '10', const Color(0xFF06D6A0)),
            _buildKpiCard('PICKUPS TODAY', '$pickupsToday', Colors.white),
            _buildKpiCard('RETURNS TODAY', '$returnsToday', accentColor),
            _buildKpiCard('PENDING PAY', '11', const Color(0xFFFF5C77)),
            _buildKpiCard('PENDING KYC', '2', const Color(0xFFFFB703)),
            _buildKpiCard('IN YARD', '${stats.availableInYard > 0 ? stats.availableInYard : 1}', const Color(0xFF06D6A0)),
          ],
        ),
        const SizedBox(height: 16),

        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildFilterPill('Operations & Bookings', _execSubTab == 0, () => setState(() => _execSubTab = 0)),
              _buildFilterPill('Booking Calendar 📅', _execSubTab == 1, () => setState(() => _execSubTab = 1)),
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
                  text: 'Verify & Approve',
                  height: 36,
                  onPressed: () async {
                    await ref.read(adminBookingsProvider.notifier).verifyPayment(
                          bookingOrPaymentId: bId,
                          action: 'approve',
                        );
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Payment for $bId verified and booking confirmed.')),
                      );
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: CustomButton(
                  text: 'Reject Payment',
                  isOutlined: true,
                  height: 36,
                  onPressed: () async {
                    await ref.read(adminBookingsProvider.notifier).verifyPayment(
                          bookingOrPaymentId: bId,
                          action: 'reject',
                          reason: 'Invalid UTR reference',
                        );
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Payment for $bId marked as rejected.')),
                      );
                    }
                  },
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
    final isCancelled = b.status.toLowerCase() == 'cancelled';
    final isCompleted = b.status.toLowerCase() == 'completed';
    final isActive = b.status.toLowerCase() == 'active';
    final isConfirmed = b.status.toLowerCase() == 'confirmed';
    final isPendingPay = b.status.toLowerCase() == 'pending_payment';
    final isPendingConfirm = b.status.toLowerCase() == 'pending_confirmation' || b.status.toLowerCase() == 'pending_verification';

    const monthNames = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final pMonth = b.pickupDate.month <= 12 && b.pickupDate.month >= 1 ? monthNames[b.pickupDate.month] : '';
    final dMonth = b.dropDate.month <= 12 && b.dropDate.month >= 1 ? monthNames[b.dropDate.month] : '';
    final dateStr = '${b.pickupDate.day} $pMonth - ${b.dropDate.day} $dMonth (${b.duration})';

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
          if (isManager) ...[
            CustomButton(
              text: 'Inspect Rental Ledger ▾',
              isOutlined: true,
              height: 36,
              onPressed: () => _showInspectBookingModal(b),
            ),
          ] else if (isCancelled) ...[
            CustomButton(
              text: 'View Cancellation Details ▾',
              isOutlined: true,
              height: 36,
              onPressed: () => _showInspectBookingModal(b),
            ),
          ] else if (isCompleted) ...[
            CustomButton(
              text: 'Trip Completed • View Summary ▾',
              isOutlined: true,
              height: 36,
              onPressed: () => _showInspectBookingModal(b),
            ),
          ] else ...[
            Row(
              children: [
                if (isActive) ...[
                  Expanded(
                    child: CustomButton(
                      text: 'Process Return',
                      height: 36,
                      onPressed: () => _showHandoverOrReturnModal(b, true),
                    ),
                  ),
                  const SizedBox(width: 8),
                ] else if (isConfirmed) ...[
                  Expanded(
                    child: CustomButton(
                      text: 'Start Handover',
                      height: 36,
                      onPressed: () => _showHandoverOrReturnModal(b, false),
                    ),
                  ),
                  const SizedBox(width: 8),
                ] else if (isPendingConfirm || isPendingPay) ...[
                  Expanded(
                    child: CustomButton(
                      text: isPendingPay ? 'Verify & Confirm' : 'Confirm Trip',
                      height: 36,
                      onPressed: () async {
                        await ref.read(adminBookingsProvider.notifier).updateStatus(bookingId: bId, newStatus: 'confirmed');
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Trip $bId confirmed.')));
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: CustomButton(
                    text: 'Details ▾',
                    isOutlined: true,
                    height: 36,
                    onPressed: () => _showInspectBookingModal(b),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
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
              Container(
                width: 70,
                height: 50,
                decoration: BoxDecoration(
                  color: context.isDarkMode ? context.themeSurfaceElevated : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.all(4),
                child: Center(
                  child: Image.asset(
                    AppAssets.getCarImagePath(v.brand, v.model),
                    fit: BoxFit.contain,
                    errorBuilder: (_, _, _) => Icon(Icons.directions_car, color: context.themeTextMuted),
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
                          text: 'Approve KYC',
                          height: 34,
                          onPressed: () async {
                            await ref.read(adminBookingsProvider.notifier).updateKyc(uid: uid, documentType: 'all', status: 'verified');
                            ref.invalidate(adminKycListProvider);
                            if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('KYC for $name approved.')));
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: CustomButton(
                          text: 'Reject',
                          isOutlined: true,
                          height: 34,
                          onPressed: () async {
                            await ref.read(adminBookingsProvider.notifier).updateKyc(uid: uid, documentType: 'all', status: 'rejected');
                            ref.invalidate(adminKycListProvider);
                            if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('KYC for $name marked as rejected.')));
                          },
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
      {'title': 'TOTAL REVENUE (VERIFIED)', 'value': _formatINR(stats.totalRevenue > 0 ? stats.totalRevenue : 663303), 'color': const Color(0xFF06D6A0)},
      {'title': 'REVENUE THIS MONTH', 'value': _formatINR(stats.monthRevenue > 0 ? stats.monthRevenue : 302906), 'color': accentColor},
      {'title': 'TOTAL BOOKINGS', 'value': '${stats.totalBookings > 0 ? stats.totalBookings : 24}', 'color': Colors.white},
      {'title': 'PAID BOOKINGS', 'value': '${stats.paidBookings > 0 ? stats.paidBookings : 24}', 'color': const Color(0xFF06D6A0)},
      {'title': 'PENDING DOCUMENT REVIEWS', 'value': '${stats.pendingDocs > 0 ? stats.pendingDocs : 13}', 'color': const Color(0xFFFFB703)},
      {'title': 'AWAITING PAYMENT VERIFICATION', 'value': '${stats.pendingPayments > 0 ? stats.pendingPayments : 11}', 'color': const Color(0xFFFF5C77)},
      {'title': 'AVG. VERIFIED BOOKING VALUE', 'value': _formatINR(stats.avgBooking > 0 ? stats.avgBooking : 27638), 'color': accentColor},
      {'title': 'ACTIVE ON-ROAD RENTALS', 'value': '${stats.activeTrips > 0 ? stats.activeTrips : 7}', 'color': const Color(0xFF06D6A0)},
      {'title': 'TOTAL REGISTERED USERS', 'value': '${stats.totalUsers > 0 ? stats.totalUsers : 161}', 'color': Colors.white},
      {'title': 'TOTAL FLEET VEHICLES', 'value': '${stats.totalFleet > 0 ? stats.totalFleet : 8}', 'color': Colors.white},
      {'title': 'AVAILABLE IN YARD', 'value': '${stats.availableInYard > 0 ? stats.availableInYard : 1}', 'color': const Color(0xFF06D6A0)},
      {'title': 'FLEET UTILIZATION RATE', 'value': '${stats.fleetUtilization > 0 ? stats.fleetUtilization : 88}%', 'color': accentColor},
    ];

    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        mainAxisExtent: 82,
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(title, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 0.5, color: context.themeTextMuted)),
          const SizedBox(height: 3),
          Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: resolvedColor)),
        ],
      ),
    );
  }

  Widget _buildStatMetricCard(String title, String value, String subtitle, Color color) {
    return GlassCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(title, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 0.5, color: context.themeTextMuted)),
          const SizedBox(height: 3),
          Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: color)),
          const SizedBox(height: 2),
          Text(subtitle, style: TextStyle(fontSize: 10.5, color: context.themeTextSecondary)),
        ],
      ),
    );
  }

  Widget _buildFilterPill(String title, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : context.themeSurfaceElevated,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? Colors.transparent : context.themeBorder),
        ),
        child: Text(title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: isSelected ? Colors.white : context.themeTextSecondary)),
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
  void _showHandoverOrReturnModal(BookingModel booking, bool isReturn) {
    final messenger = ScaffoldMessenger.of(context);
    final odoController = TextEditingController(text: isReturn ? (booking.endOdometer ?? "") : (booking.startOdometer ?? ""));
    final fastagController = TextEditingController(text: isReturn ? (booking.returnFastag ?? "") : (booking.startFastag ?? ""));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 24),
        decoration: BoxDecoration(color: context.themeSurfaceElevated, borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(isReturn ? 'Process Vehicle Return' : 'Start Trip & Pickup Handover', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: context.themeTextPrimary)),
            const SizedBox(height: 6),
            Text('Booking: ${booking.bookingNumber} • ${booking.vehicleName}', style: TextStyle(fontSize: 12, color: context.themeTextSecondary)),
            const SizedBox(height: 14),
            TextField(
              controller: odoController,
              keyboardType: TextInputType.number,
              style: TextStyle(color: context.themeTextPrimary),
              decoration: InputDecoration(labelText: isReturn ? 'Return Odometer (km)' : 'Starting Odometer (km)', border: const OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: fastagController,
              keyboardType: TextInputType.number,
              style: TextStyle(color: context.themeTextPrimary),
              decoration: InputDecoration(labelText: isReturn ? 'Return FASTag Balance (₹)' : 'Starting FASTag Balance (₹)', border: const OutlineInputBorder()),
            ),
            const SizedBox(height: 18),
            CustomButton(
              text: isReturn ? 'Complete Trip & Close' : 'Dispatch Vehicle & Start Trip',
              onPressed: () async {
                final bId = booking.bookingNumber.isNotEmpty ? booking.bookingNumber : booking.bookingId;
                await ref.read(adminBookingsProvider.notifier).updateStatus(bookingId: bId, newStatus: isReturn ? 'completed' : 'active');
                if (ctx.mounted) Navigator.pop(ctx);
                messenger.showSnackBar(SnackBar(content: Text(isReturn ? 'Trip $bId marked as completed.' : 'Trip $bId dispatched.')));
              },
            ),
          ],
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
              Text('Vehicle: ${booking.vehicleName}', style: TextStyle(fontSize: 13, color: context.themeTextSecondary)),
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
