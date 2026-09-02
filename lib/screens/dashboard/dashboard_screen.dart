import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../widgets/dashboard_stat_card.dart';
import '../../widgets/quick_action_button.dart';
import '../../services/dashboard_service.dart';
import '../../widgets/skeleton_loader.dart';
import '../sales/sale_form_screen.dart';
import '../stock/stock_form_screen.dart';
import '../payment/payment_form_screen.dart';
import '../customer/customer_form_screen.dart';
import '../../utils/app_events.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Map<String, dynamic>? _summary;
  bool _isLoading = true;

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
    if (mounted) {
      setState(() {
        _summary = data;
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
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Theme.of(context).colorScheme.primary
                                  .withOpacity(0.5),
                            ),
                          ),
                          child: Icon(
                            Icons.grass,
                            color: Theme.of(context).colorScheme.primary,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Good Morning, Admin',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              DateFormat('EEEE, dd MMMM')
                                  .format(DateTime.now()),
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context).colorScheme.outline,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Icon(
                          Icons.notifications_none,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 16),
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: Theme.of(context).primaryColor,
                          child: Icon(
                            Icons.person,
                            color: Theme.of(context).colorScheme.primary,
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1B4D2B), Color(0xFF0D2916)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.primary
                          .withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Today\'s Business',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '₹${numFormat.format(todaysSalesAmount)}',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurface,
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
                                    color: Theme.of(context)
                                        .colorScheme
                                        .outline,
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
                                        color: Theme.of(context).colorScheme.primary,
                                        size: 12,
                                      ),
                                      SizedBox(width: 4),
                                      Text(
                                        '+% Today',
                                        style: TextStyle(
                                          color: Theme.of(context).colorScheme.primary,
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
                      Icon(
                        Icons.bar_chart,
                        size: 80,
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  childAspectRatio: 2.2,
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
