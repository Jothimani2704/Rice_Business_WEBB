import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../services/sale_service.dart';
import '../../widgets/skeleton_loader.dart';
import 'sale_detail_screen.dart';
import 'sale_form_screen.dart';
import '../../utils/app_events.dart';

class SaleListScreen extends StatefulWidget {
  const SaleListScreen({super.key});

  @override
  State<SaleListScreen> createState() => _SaleListScreenState();
}

class _SaleListScreenState extends State<SaleListScreen> {
  List<Map<String, dynamic>> _sales = [];
  bool _isLoading = true;
  String _selectedFilter = 'All';
  DateTimeRange? _selectedDateRange;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String _searchQuery = '';

  final numFormat = NumberFormat('#,##,###');

  @override
  void initState() {
    super.initState();
    _fetchSales();
    AppEvents.refreshData.addListener(_fetchSales);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    AppEvents.refreshData.removeListener(_fetchSales);
    super.dispose();
  }

  Future<void> _fetchSales() async {
    setState(() => _isLoading = true);
    try {
      final sales = await SaleService.getSales();
      if (mounted) {
        setState(() {
          _sales = sales;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
      print('Error fetching sales: $e');
    }
  }

  double get _todaysSalesAmount {
    final today = DateTime.now();
    return _sales
        .where((s) {
          final saleDate = DateTime.parse(s['saleDate']);
          return saleDate.year == today.year &&
              saleDate.month == today.month &&
              saleDate.day == today.day;
        })
        .fold(0.0, (sum, item) => sum + (item['totalAmount'] as num));
  }

  int get _todaysBillsCount {
    final today = DateTime.now();
    return _sales.where((s) {
      final saleDate = DateTime.parse(s['saleDate']);
      return saleDate.year == today.year &&
          saleDate.month == today.month &&
          saleDate.day == today.day;
    }).length;
  }

  double get _totalPendingAmount {
    return _sales.fold(
      0.0,
      (sum, item) => sum + (item['balanceAmount'] as num),
    );
  }

  List<Map<String, dynamic>> get _filteredSales {
    List<Map<String, dynamic>> list = _sales;

    if (_selectedDateRange != null) {
      final start = DateTime(_selectedDateRange!.start.year, _selectedDateRange!.start.month, _selectedDateRange!.start.day, 0, 0, 0);
      final end = DateTime(_selectedDateRange!.end.year, _selectedDateRange!.end.month, _selectedDateRange!.end.day, 23, 59, 59);
      list = list.where((s) {
        final saleDate = DateTime.parse(s['saleDate']);
        return !saleDate.isBefore(start) && !saleDate.isAfter(end);
      }).toList();
    }

    if (_selectedFilter == 'Today') {
      final today = DateTime.now();
      list = list.where((s) {
        final saleDate = DateTime.parse(s['saleDate']);
        return saleDate.year == today.year &&
            saleDate.month == today.month &&
            saleDate.day == today.day;
      }).toList();
    } else if (_selectedFilter == 'Pending') {
      list = list.where((s) => (s['balanceAmount'] as num) > 0).toList();
    } else if (_selectedFilter == 'Paid') {
      list = list.where((s) => (s['balanceAmount'] as num) == 0).toList();
    }

    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.trim().toLowerCase();
      list = list.where((s) {
        final saleIdStr = 'sale #${s['id'].toString().padLeft(4, '0')}'.toLowerCase();
        final idStr = s['id'].toString().toLowerCase();
        final customerName = (s['customerName'] ?? '').toString().toLowerCase();
        final customerPhone = (s['customerPhone'] ?? s['phone'] ?? '').toString().toLowerCase();
        final paymentStatus = (s['paymentStatus'] ?? '').toString().toLowerCase();
        final billNo = (s['billNumber'] ?? s['invoiceNumber'] ?? '').toString().toLowerCase();

        return saleIdStr.contains(q) ||
            idStr.contains(q) ||
            customerName.contains(q) ||
            customerPhone.contains(q) ||
            paymentStatus.contains(q) ||
            billNo.contains(q);
      }).toList();
    }

    return list;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const ListSkeleton(title: 'Sales');
    }

    final currentFiltered = _filteredSales;

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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // App Bar
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                          width: 1.5,
                        ),
                      ),
                      child: Icon(
                        Icons.shopping_bag_rounded,
                        color: Theme.of(context).colorScheme.primary,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Sales',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Manage customer bills',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _buildIconButton(
                      Icons.calendar_month,
                      isActive: _selectedDateRange != null,
                      onTap: _showDateFilterModal,
                    ),
                    const SizedBox(width: 12),
                    _buildIconButton(
                      Icons.insert_chart_outlined,
                      onTap: () => _showSalesAnalyticsSheet(currentFiltered),
                    ),
                  ],
                ),
              ),

              // Search Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2),
                          ),
                        ),
                        child: TextField(
                          controller: _searchController,
                          focusNode: _searchFocusNode,
                          onChanged: (value) {
                            setState(() {
                              _searchQuery = value;
                            });
                          },
                          style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                          decoration: InputDecoration(
                            icon: Icon(
                              Icons.search,
                              color: Theme.of(context).colorScheme.outline,
                            ),
                            hintText: 'Search bill or customer',
                            hintStyle: TextStyle(
                              color: Theme.of(context).colorScheme.outline,
                            ),
                            border: InputBorder.none,
                            suffixIcon: _searchQuery.isNotEmpty
                                ? GestureDetector(
                                    onTap: () {
                                      _searchController.clear();
                                      setState(() {
                                        _searchQuery = '';
                                      });
                                    },
                                    child: Icon(
                                      Icons.clear,
                                      color: Theme.of(context).colorScheme.outline,
                                      size: 18,
                                    ),
                                  )
                                : null,
                          ),
                        ),
                      ),
                    ),

                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Metric Cards
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    _buildMetricCard(
                      icon: Icons.trending_up,
                      title: 'Today\'s Sales',
                      value: '₹${numFormat.format(_todaysSalesAmount)}',
                      iconColor: Theme.of(context).colorScheme.primary,
                      iconBgColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                    ),
                    const SizedBox(width: 12),
                    _buildMetricCard(
                      icon: Icons.receipt_long,
                      title: 'Bills',
                      value: _todaysBillsCount.toString(),
                      iconColor: Theme.of(context).colorScheme.primary,
                      iconBgColor: Theme.of(context).colorScheme.primary
                          .withValues(alpha: 0.1),
                    ),
                    const SizedBox(width: 12),
                    _buildMetricCard(
                      icon: Icons.schedule,
                      title: 'Pending',
                      value: '₹${numFormat.format(_totalPendingAmount)}',
                      iconColor: Colors.redAccent,
                      iconBgColor: Colors.redAccent.withValues(alpha: 0.1),
                      titleColor: Colors.redAccent,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Action Buttons
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const SaleFormScreen(),
                            ),
                          ).then((val) {
                            if (val == true) _fetchSales();
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Theme.of(context).colorScheme.primary,
                                Theme.of(context).colorScheme.secondary,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          alignment: Alignment.center,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.add, color: Theme.of(context).colorScheme.onPrimary, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'New Sale',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.onPrimary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Sales Report: Coming Soon'),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          alignment: Alignment.center,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.description_outlined,
                                color: Theme.of(context).colorScheme.primary,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Sales Report',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Filters
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    _buildFilterChip('All'),
                    _buildFilterChip('Today'),
                    _buildFilterChip('Pending'),
                    _buildFilterChip('Paid'),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  'Recent Sales',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              Expanded(
                child: currentFiltered.isEmpty
                    ? Center(
                        child: Text(
                          'No sales found',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.outline,
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 8.0,
                        ),
                        itemCount: currentFiltered.length,
                        itemBuilder: (context, index) {
                          final item = currentFiltered[index];
                          return _buildSaleCard(item);
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIconButton(
    IconData icon, {
    VoidCallback? onTap,
    bool isActive = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isActive
              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.2)
              : Colors.transparent,
          border: Border.all(
            color: isActive
                ? Theme.of(context).colorScheme.secondary
                : Theme.of(context).colorScheme.primary,
            width: isActive ? 1.5 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: isActive
              ? Theme.of(context).colorScheme.secondary
              : Theme.of(context).colorScheme.primary,
          size: 20,
        ),
      ),
    );
  }

  Widget _buildMetricCard({
    required IconData icon,
    required String title,
    required String value,
    required Color iconColor,
    required Color iconBgColor,
    Color? titleColor,
  }) {
    return Container(
      width: 140,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? Theme.of(context).primaryColor.withValues(alpha: 0.5)
            : Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: iconBgColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 16),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: titleColor ?? Theme.of(context).colorScheme.primary,
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    bool isSelected = _selectedFilter == label;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = label),
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.outline,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildSaleCard(Map<String, dynamic> sale) {
    final saleDate = DateTime.parse(sale['saleDate']);
    final dateStr = DateFormat('dd MMM yyyy').format(saleDate);
    final timeStr = DateFormat('hh:mm a').format(saleDate);

    final balance = (sale['balanceAmount'] as num).toDouble();
    final total = (sale['totalAmount'] as num).toDouble();

    String badgeText = 'PAID';
    Color badgeColor = Theme.of(context).colorScheme.primary;
    if (balance > 0) {
      if (balance == total) {
        badgeText = 'UNPAID';
        badgeColor = Colors.redAccent;
      } else {
        badgeText = 'PARTIAL';
        badgeColor = Theme.of(context).colorScheme.primary;
      }
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SaleDetailScreen(saleId: sale['id']),
          ),
        ).then((_) => _fetchSales());
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? Theme.of(context).primaryColor.withValues(alpha: 0.5)
              : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary
                        .withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Theme.of(context).colorScheme.primary
                          .withValues(alpha: 0.5),
                    ),
                  ),
                  child: Icon(
                    Icons.receipt_long,
                    color: Theme.of(context).colorScheme.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sale #${sale['id'].toString().padLeft(4, '0')}',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$dateStr • $timeStr',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: badgeColor.withValues(alpha: 0.5),
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: badgeColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        badgeText,
                        style: TextStyle(
                          color: badgeColor,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.more_horiz, color: Theme.of(context).colorScheme.onSurface, size: 24),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              sale['customerName'],
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  '${sale['itemCount']} items • ${numFormat.format(sale['totalQuantity'])} bags',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
                    fontSize: 13,
                  ),
                ),
                const Spacer(),
                _buildAmountColumn('Total', sale['totalAmount'], Theme.of(context).colorScheme.onSurface),
                _buildVerticalDivider(),
                _buildAmountColumn('Paid', sale['paidAmount'], Theme.of(context).colorScheme.onSurface),
                _buildVerticalDivider(),
                _buildAmountColumn(
                  'Balance',
                  sale['balanceAmount'],
                  badgeColor,
                ),
                const SizedBox(width: 12),
                Icon(
                  Icons.chevron_right,
                  color: Theme.of(context).colorScheme.primary,
                  size: 24,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAmountColumn(String label, dynamic amount, Color valueColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Theme.of(context).colorScheme.outline,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '₹${numFormat.format(amount)}',
          style: TextStyle(color: valueColor, fontSize: 13),
        ),
      ],
    );
  }

  Widget _buildVerticalDivider() {
    return Container(
      height: 30,
      width: 1,
      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1),
      margin: const EdgeInsets.symmetric(horizontal: 12),
    );
  }

  void _showDateFilterModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E2430) : Theme.of(context).cardColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            border: Border.all(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
            ),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.calendar_month, color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: 10),
                      Text(
                        'Filter Sales by Date Range',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              if (_selectedDateRange != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Active Range: ${DateFormat('dd MMM yyyy').format(_selectedDateRange!.start)} - ${DateFormat('dd MMM yyyy').format(_selectedDateRange!.end)}',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _buildQuickDateChip('Today', () {
                    final now = DateTime.now();
                    setState(() {
                      _selectedDateRange = DateTimeRange(start: now, end: now);
                    });
                    Navigator.pop(context);
                  }),
                  _buildQuickDateChip('Yesterday', () {
                    final y = DateTime.now().subtract(const Duration(days: 1));
                    setState(() {
                      _selectedDateRange = DateTimeRange(start: y, end: y);
                    });
                    Navigator.pop(context);
                  }),
                  _buildQuickDateChip('Last 7 Days', () {
                    final now = DateTime.now();
                    final start = now.subtract(const Duration(days: 6));
                    setState(() {
                      _selectedDateRange = DateTimeRange(start: start, end: now);
                    });
                    Navigator.pop(context);
                  }),
                  _buildQuickDateChip('This Month', () {
                    final now = DateTime.now();
                    final start = DateTime(now.year, now.month, 1);
                    setState(() {
                      _selectedDateRange = DateTimeRange(start: start, end: now);
                    });
                    Navigator.pop(context);
                  }),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.date_range),
                      label: const Text('Custom Range'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () async {
                        final picked = await showDateRangePicker(
                          context: context,
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                          initialDateRange: _selectedDateRange,
                        );
                        if (picked != null) {
                          setState(() {
                            _selectedDateRange = picked;
                          });
                          if (context.mounted) Navigator.pop(context);
                        }
                      },
                    ),
                  ),
                  if (_selectedDateRange != null) ...[
                    const SizedBox(width: 12),
                    TextButton.icon(
                      icon: const Icon(Icons.clear, color: Colors.redAccent),
                      label: const Text('Reset', style: TextStyle(color: Colors.redAccent)),
                      onPressed: () {
                        setState(() {
                          _selectedDateRange = null;
                        });
                        Navigator.pop(context);
                      },
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  Widget _buildQuickDateChip(String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: Theme.of(context).colorScheme.primary,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  void _showSalesAnalyticsSheet(List<Map<String, dynamic>> salesList) {
    final totalRevenue = salesList.fold(0.0, (sum, s) => sum + (s['totalAmount'] as num).toDouble());
    final totalPaid = salesList.fold(0.0, (sum, s) => sum + (s['paidAmount'] as num).toDouble());
    final totalPending = salesList.fold(0.0, (sum, s) => sum + (s['balanceAmount'] as num).toDouble());
    final totalBags = salesList.fold(0.0, (sum, s) => sum + (s['totalQuantity'] as num).toDouble());
    final count = salesList.length;
    final avgBill = count > 0 ? totalRevenue / count : 0.0;

    double maxBill = 0.0;
    int paidCount = 0;
    int partialCount = 0;
    int unpaidCount = 0;

    for (final s in salesList) {
      final total = (s['totalAmount'] as num).toDouble();
      final balance = (s['balanceAmount'] as num).toDouble();
      if (total > maxBill) maxBill = total;

      if (balance == 0) {
        paidCount++;
      } else if (balance == total) {
        unpaidCount++;
      } else {
        partialCount++;
      }
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E2430) : Theme.of(context).cardColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
            ),
          ),
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.insert_chart_outlined,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Sales Analytics & Insights',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Total Revenue Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Theme.of(context).colorScheme.primary,
                        Theme.of(context).colorScheme.secondary,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'TOTAL SALES REVENUE',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.8),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '₹${numFormat.format(totalRevenue)}',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onPrimary,
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.shopping_bag_outlined,
                            color: Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.9),
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '$count Bills  •  ${numFormat.format(totalBags)} Bags Sold',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.9),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                Text(
                  'Bill Status Breakdown',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 16),
                _buildAnalyticsBreakdownRow(
                  label: 'Fully Paid ($paidCount)',
                  amount: totalPaid,
                  totalAmount: totalRevenue > 0 ? totalRevenue : 1,
                  icon: Icons.check_circle_outline,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 12),
                _buildAnalyticsBreakdownRow(
                  label: 'Partially Paid ($partialCount)',
                  amount: (totalRevenue - totalPaid - totalPending) > 0 ? (totalRevenue - totalPaid - totalPending) : (totalRevenue - totalPaid),
                  totalAmount: totalRevenue > 0 ? totalRevenue : 1,
                  icon: Icons.timelapse,
                  color: Colors.amberAccent,
                ),
                const SizedBox(height: 12),
                _buildAnalyticsBreakdownRow(
                  label: 'Outstanding / Balance ($unpaidCount)',
                  amount: totalPending,
                  totalAmount: totalRevenue > 0 ? totalRevenue : 1,
                  icon: Icons.pending_outlined,
                  color: Colors.redAccent,
                ),
                const SizedBox(height: 24),

                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.05)
                              : Colors.black.withValues(alpha: 0.03),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Highest Sale Bill',
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context).colorScheme.outline,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '₹${numFormat.format(maxBill)}',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.05)
                              : Colors.black.withValues(alpha: 0.03),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Avg Sale per Bill',
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context).colorScheme.outline,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '₹${numFormat.format(avgBill.round())}',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.secondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAnalyticsBreakdownRow({
    required String label,
    required double amount,
    required double totalAmount,
    required IconData icon,
    required Color color,
  }) {
    final pct = totalAmount > 0 ? (amount / totalAmount).clamp(0.0, 1.0) : 0.0;
    final pctStr = (pct * 100).toStringAsFixed(1);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(icon, color: color, size: 20),
                  const SizedBox(width: 10),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '₹${numFormat.format(amount > 0 ? amount : 0)}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    '$pctStr%',
                    style: TextStyle(
                      fontSize: 11,
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 6,
              backgroundColor: color.withValues(alpha: 0.15),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }
}
