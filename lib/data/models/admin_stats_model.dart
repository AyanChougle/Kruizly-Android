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

    final monthlyMap = (data['monthly'] is Map)
        ? Map<String, dynamic>.from(data['monthly'] as Map)
        : const <String, dynamic>{};

    double parseDouble(dynamic val, [double def = 0.0]) {
      if (val == null) return def;
      if (val is num) return val.toDouble();
      return double.tryParse(val.toString()) ?? def;
    }

    int parseInt(dynamic val, [int def = 0]) {
      if (val == null) return def;
      if (val is int) return val;
      if (val is num) return val.toInt();
      final str = val.toString().trim();
      final asInt = int.tryParse(str);
      if (asInt != null) return asInt;
      final asDouble = double.tryParse(str);
      if (asDouble != null) return asDouble.round();
      return def;
    }

    return AdminStatsModel(
      totalRevenue: parseDouble(live['total_revenue']),
      monthRevenue: parseDouble(live['month_revenue']),
      lastMonthRevenue: parseDouble(live['last_month_revenue']),
      daySales: parseDouble(live['day_sales']),
      weekSales: parseDouble(live['week_sales']),
      totalBookings: parseInt(live['total_bookings']),
      paidBookings: parseInt(live['paid_bookings']),
      pendingDocs: parseInt(live['pending_docs']),
      pendingPayments: parseInt(live['pending_payments']),
      avgBooking: parseDouble(live['avg_booking']),
      activeTrips: parseInt(live['active_trips'] ?? live['on_road_fleet']),
      completedTrips: parseInt(live['completed_trips']),
      totalUsers: parseInt(live['total_users']),
      totalFleet: parseInt(live['total_fleet'] ?? live['fleet_count']),
      availableInYard: parseInt(live['available_in_yard'] ?? live['available_fleet']),
      fleetUtilization: parseInt(live['fleet_utilization'] ?? live['occupancy_pct']),
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
