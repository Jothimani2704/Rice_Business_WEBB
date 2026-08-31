class DashboardSummary {
  final int totalCustomers;
  final int activeCustomers;
  final double todaySales;
  final double todayPaymentCollection;
  final double totalOutstandingBalance;
  final double totalAvailableStock;
  final int lowStockCount;
  final List<dynamic> lowStockProducts;
  final List<dynamic> recentSales;
  final List<dynamic> recentPayments;
  final List<dynamic> recentActivity;
  final List<dynamic> topSellingProducts;

  DashboardSummary({
    required this.totalCustomers,
    required this.activeCustomers,
    required this.todaySales,
    required this.todayPaymentCollection,
    required this.totalOutstandingBalance,
    required this.totalAvailableStock,
    required this.lowStockCount,
    required this.lowStockProducts,
    required this.recentSales,
    required this.recentPayments,
    required this.recentActivity,
    required this.topSellingProducts,
  });

  factory DashboardSummary.fromJson(Map<String, dynamic> json) {
    return DashboardSummary(
      totalCustomers: json['totalCustomers'] ?? 0,
      activeCustomers: json['activeCustomers'] ?? 0,
      todaySales: (json['todaySales'] ?? 0).toDouble(),
      todayPaymentCollection: (json['todayPaymentCollection'] ?? 0).toDouble(),
      totalOutstandingBalance: (json['totalOutstandingBalance'] ?? 0)
          .toDouble(),
      totalAvailableStock: (json['totalAvailableStock'] ?? 0).toDouble(),
      lowStockCount: json['lowStockCount'] ?? 0,
      lowStockProducts: json['lowStockProducts'] ?? [],
      recentSales: json['recentSales'] ?? [],
      recentPayments: json['recentPayments'] ?? [],
      recentActivity: json['recentActivity'] ?? [],
      topSellingProducts: json['topSellingProducts'] ?? [],
    );
  }
}
