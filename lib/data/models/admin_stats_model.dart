class AdminStatsModel {
  final double totalRevenue;
  final double monthRevenue;
  final double lastMonthRevenue;
  final double daySales;
  final double weekSales;
  final int totalBookings;
  final int paidBookings;
  final int pendingDocs;
  final int pendingPayments;
  final double avgBooking;
  final int activeTrips;
  final int completedTrips;
  final int totalUsers;
  final int totalFleet;
  final int availableInYard;
  final int fleetUtilization;
  final Map<String, dynamic> monthly;

  const AdminStatsModel({
    required this.totalRevenue,
    required this.monthRevenue,
    this.lastMonthRevenue = 0.0,
    this.daySales = 0.0,
    this.weekSales = 0.0,
    required this.totalBookings,
    required this.paidBookings,
    required this.pendingDocs,
    required this.pendingPayments,
    required this.avgBooking,
    required this.activeTrips,
    this.completedTrips = 0,
    required this.totalUsers,
    required this.totalFleet,
    required this.availableInYard,
    required this.fleetUtilization,
    this.monthly = const {},
  });

  factory AdminStatsModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] is Map<String, dynamic> ? json['data'] as Map<String, dynamic> : json;
    final live = (data['effective'] is Map<String, dynamic>)
        ? data['effective'] as Map<String, dynamic>
        : (data['live'] is Map<String, dynamic>
            ? data['live'] as Map<String, dynamic>
            : (json['live'] is Map<String, dynamic> ? json['live'] as Map<String, dynamic> : data));

    final monthlyMap = (data['monthly'] is Map<String, dynamic>)
        ? Map<String, dynamic>.from(data['monthly'] as Map<String, dynamic>)
        : const <String, dynamic>{};

    return AdminStatsModel(
      totalRevenue: (live['total_revenue'] as num?)?.toDouble() ?? 0.0,
      monthRevenue: (live['month_revenue'] as num?)?.toDouble() ?? 0.0,
      lastMonthRevenue: (live['last_month_revenue'] as num?)?.toDouble() ?? 0.0,
      daySales: (live['day_sales'] as num?)?.toDouble() ?? 0.0,
      weekSales: (live['week_sales'] as num?)?.toDouble() ?? 0.0,
      totalBookings: (live['total_bookings'] as num?)?.toInt() ?? 0,
      paidBookings: (live['paid_bookings'] as num?)?.toInt() ?? 0,
      pendingDocs: (live['pending_docs'] as num?)?.toInt() ?? 0,
      pendingPayments: (live['pending_payments'] as num?)?.toInt() ?? 0,
      avgBooking: (live['avg_booking'] as num?)?.toDouble() ?? 0.0,
      activeTrips: (live['active_trips'] as num?)?.toInt() ?? (live['on_road_fleet'] as num?)?.toInt() ?? 0,
      completedTrips: (live['completed_trips'] as num?)?.toInt() ?? 0,
      totalUsers: (live['total_users'] as num?)?.toInt() ?? 0,
      totalFleet: (live['total_fleet'] as num?)?.toInt() ?? (live['fleet_count'] as num?)?.toInt() ?? 0,
      availableInYard: (live['available_in_yard'] as num?)?.toInt() ?? (live['available_fleet'] as num?)?.toInt() ?? 0,
      fleetUtilization: (live['fleet_utilization'] as num?)?.toInt() ?? 0,
      monthly: monthlyMap,
    );
  }

  static const defaultStats = AdminStatsModel(
    totalRevenue: 0.0,
    monthRevenue: 0.0,
    lastMonthRevenue: 0.0,
    daySales: 0.0,
    weekSales: 0.0,
    totalBookings: 0,
    paidBookings: 0,
    pendingDocs: 0,
    pendingPayments: 0,
    avgBooking: 0.0,
    activeTrips: 0,
    completedTrips: 0,
    totalUsers: 0,
    totalFleet: 0,
    availableInYard: 0,
    fleetUtilization: 0,
  );

  static const empty = defaultStats;
}
