import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../widgets/dashboard_stat_card.dart';
import '../../widgets/quick_action_button.dart';
import '../../services/dashboard_service.dart';
import '../../services/offline_sync_service.dart';
import '../../widgets/skeleton_loader.dart';
import '../sales/sale_form_screen.dart';
import '../stock/stock_form_screen.dart';
import '../payment/payment_form_screen.dart';
import '../customer/customer_form_screen.dart';
import '../reports/reports_analytics_screen.dart';
import '../../utils/app_events.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/language_provider.dart';
import '../../widgets/language_toggle_button.dart';
import '../../config/api_config.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Map<String, dynamic>? _summary;
  bool _isLoading = true;
  int _pendingOfflineCount = 0;

  @override
  void initState() {
    super.initState();
    _fetchSummary();
    AppEvents.refreshData.addListener(_fetchSummary);
  }

  @override
  void dispose() {
    AppEvents.refreshData.removeListener(_fetchSummary);
    super.dispose();
  }

  Future<void> _fetchSummary() async {
    final data = await DashboardService.getSummary();
    final offlineCount = await OfflineSyncService.getPendingSalesCount();
    if (mounted) {
      setState(() {
        _summary = data;
        _pendingOfflineCount = offlineCount;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final numFormat = NumberFormat('#,##,###');

    if (_isLoading) {
      return const DashboardSkeleton();
    }

    final data = _summary ?? {};
    final todaysSalesAmount = data['todaysSalesAmount'] ?? 0;
    final todaysPaymentCollection = data['todaysPaymentCollection'] ?? 0;
    final totalOutstandingBalance = data['totalOutstandingBalance'] ?? 0;
    final totalAvailableStock = data['totalAvailableStock'] ?? 0;
    final totalCustomers = data['totalCustomers'] ?? 0;
    final lowStockCount = data['lowStockCount'] ?? 0;

    final lowStockProducts = (data['lowStockProducts'] as List?) ?? [];
    final recentActivity = (data['recentActivity'] as List?) ?? [];

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? null
              : Theme.of(context).scaffoldBackgroundColor,
          gradient: Theme.of(context).brightness == Brightness.dark
              ? RadialGradient(
                  center: const Alignment(0, -0.6),
                  radius: 1.2,
                  colors: [
                    Theme.of(context).colorScheme.surface,
                    Theme.of(context).primaryColor,
                    Colors.black,
                  ],
                  stops: const [0.0, 0.6, 1.0],
                )
              : null,
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Theme.of(context).colorScheme.primary
                                    .withValues(alpha: 0.5),
                              ),
                            ),
                            child: Icon(
                              Icons.grass,
                              color: Theme.of(context).colorScheme.primary,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Consumer<AuthProvider>(
                                  builder: (context, authProvider, _) {
                                    final username = authProvider.user?['username'] ?? 'Admin';
                                    return Text(
                                      'Good Morning, $username',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    );
                                  },
                                ),
                                Text(
                                  DateFormat('EEEE, dd MMM')
                                      .format(DateTime.now()),
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Theme.of(context).colorScheme.outline,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Stack(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Icon(
                            Icons.notifications_none,
                            color: Theme.of(context).colorScheme.primary,
                            size: 20,
                          ),
                        ),
                        Positioned(
                          right: 8,
                          top: 8,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.secondary,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                if (_pendingOfflineCount > 0) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.orange.withValues(alpha: 0.5),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: Colors.orange,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.cloud_off_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '$_pendingOfflineCount Offline Bill${_pendingOfflineCount > 1 ? 's' : ''} Pending Sync',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 2),
                              const Text(
                                'Bills saved locally. Will auto-sync when online.',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: () async {
                            final synced = await OfflineSyncService.syncPendingSales(
                              context: context,
                            );
                            _fetchSummary();
                          },
                          icon: const Icon(Icons.sync_rounded, size: 16),
                          label: const Text(
                            'Sync Now',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ReportsAnalyticsScreen(),
                      ),
                    );
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(context).colorScheme.primary,
                          Theme.of(context).colorScheme.secondary,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.1),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    'Today\'s Business',
                                    style: TextStyle(
                                      color: Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.8),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const Spacer(),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Row(
                                      children: const [
                                        Icon(Icons.auto_graph_rounded, color: Colors.white, size: 14),
                                        SizedBox(width: 4),
                                        Text(
                                          'Analytics 📊',
                                          style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '₹${numFormat.format(todaysSalesAmount)}',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.onPrimary,
                                  fontSize: 36,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Text(
                                    'Sales',
                                    style: TextStyle(
                                      color: Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.7),
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.green.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.arrow_upward,
                                          color: Theme.of(context).colorScheme.onPrimary,
                                          size: 12,
                                        ),
                                        SizedBox(width: 4),
                                        Text(
                                          '+% Today',
                                          style: TextStyle(
                                            color: Theme.of(context).colorScheme.onPrimary,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(
                          Icons.bar_chart,
                          size: 70,
                          color: Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.2),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  childAspectRatio: 1.85,
                  children: [
                    DashboardStatCard(
                      title: 'Collected',
                      value: '₹${numFormat.format(todaysPaymentCollection)}',
                      icon: Icons.account_balance_wallet,
                      iconColor: Theme.of(context).colorScheme.primary,
                      backgroundColor: Colors.green.withValues(alpha: 0.1),
                    ),
                    DashboardStatCard(
                      title: 'Pending',
                      value: '₹${numFormat.format(totalOutstandingBalance)}',
                      icon: Icons.access_time_filled,
                      iconColor: Colors.orangeAccent,
                      backgroundColor: Colors.orange.withValues(alpha: 0.1),
                    ),
                    DashboardStatCard(
                      title: 'Stock',
                      value: '${numFormat.format(totalAvailableStock)} Bags',
                      icon: Icons.inventory,
                      iconColor: Colors.lightBlueAccent,
                      backgroundColor: Colors.blue.withValues(alpha: 0.1),
                    ),
                    DashboardStatCard(
                      title: 'Customers',
                      value: '$totalCustomers',
                      icon: Icons.people,
                      iconColor: Colors.purpleAccent,
                      backgroundColor: Colors.purple.withValues(alpha: 0.1),
                    ),
                    if (lowStockCount > 0)
                      DashboardStatCard(
                        title: 'Low Stock',
                        value: '$lowStockCount Items',
                        icon: Icons.warning_amber_rounded,
                        iconColor: Colors.redAccent,
                        backgroundColor: Colors.red.withValues(alpha: 0.1),
                      ),
                  ],
                ),
                const SizedBox(height: 24),

                Text(
                  'Quick Actions',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: QuickActionButton(
                        label: 'New Sale',
                        icon: Icons.shopping_cart,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const SaleFormScreen(),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: QuickActionButton(
                        label: 'Add Stock',
                        icon: Icons.add_box,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const StockFormScreen(),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: QuickActionButton(
                        label: 'Payment',
                        icon: Icons.payments,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const PaymentFormScreen(),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: QuickActionButton(
                        label: 'Customer',
                        icon: Icons.person_add,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const CustomerFormScreen(),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                if (lowStockProducts.isNotEmpty) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Low Stock Alert',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'View All >',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ...lowStockProducts.take(3).map((item) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.redAccent.withValues(alpha: 0.5),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(Icons.image, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5)),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${item['productName']} (${item['brandName']})',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${item['currentStock']} left (Min: ${item['minimumStockLevel']})',
                                  style: TextStyle(
                                    color: Colors.redAccent,
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 12),
                ],

                if (recentActivity.isNotEmpty) ...[
                  Text(
                    'Recent Activity',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...recentActivity.take(5).map((activity) {
                    bool isSale = activity['type'] == 'SALE';
                    var amount = activity['amount'] ?? 0;
                    DateTime date =
                        DateTime.tryParse(activity['date']?.toString() ?? '') ??
                        DateTime.now();

                    return Column(
                      children: [
                        _buildActivityTile(
                          icon: isSale
                              ? Icons.shopping_cart
                              : Icons.currency_rupee,
                          title: isSale
                              ? 'Sale #${activity['id']}'
                              : 'Payment • ${activity['customerName']}',
                          subtitle: isSale
                              ? (activity['customerName'] ?? '')
                              : (activity['description'] ?? ''),
                          amount: '+ ₹${numFormat.format(amount)}',
                          time: DateFormat('hh:mm a').format(date),
                          isSale: isSale,
                        ),
                        const SizedBox(height: 12),
                      ],
                    );
                  }),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActivityTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required String amount,
    required String time,
    required bool isSale,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isSale
                  ? Colors.green.withValues(alpha: 0.1)
                  : Colors.blue.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: isSale ? Theme.of(context).colorScheme.primary : Colors.blueAccent,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.outline,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                amount,
                style: TextStyle(
                  color: isSale ? Colors.green : Theme.of(context).colorScheme.onSurface,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                time,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.outline,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
