import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../services/customer_service.dart';
import '../../widgets/skeleton_loader.dart';
import 'customer_form_screen.dart';
import 'customer_details_screen.dart';
import '../../utils/app_events.dart';

class CustomerListScreen extends StatefulWidget {
  const CustomerListScreen({super.key});

  @override
  State<CustomerListScreen> createState() => _CustomerListScreenState();
}

class _CustomerListScreenState extends State<CustomerListScreen> {
  String _selectedFilter = 'All';
  DateTimeRange? _selectedDateRange;
  List<dynamic> _customers = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchCustomers();
    AppEvents.refreshData.addListener(_fetchCustomers);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    AppEvents.refreshData.removeListener(_fetchCustomers);
    super.dispose();
  }

  Future<void> _fetchCustomers() async {
    final data = await CustomerService.getCustomers();
    if (mounted) {
      setState(() {
        _customers = data ?? [];
        _isLoading = false;
      });
    }
  }

  void _showDateFilterModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF161C24) : Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
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
                      Icon(
                        Icons.calendar_month,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Filter Customers by Date',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.close,
                      color: Theme.of(context).colorScheme.outline,
                    ),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildQuickDateChip(ctx, 'All Time', null),
                  _buildQuickDateChip(
                    ctx,
                    'Today',
                    DateTimeRange(
                      start: DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day),
                      end: DateTime.now(),
                    ),
                  ),
                  _buildQuickDateChip(
                    ctx,
                    'Yesterday',
                    DateTimeRange(
                      start: DateTime.now().subtract(const Duration(days: 1)),
                      end: DateTime.now().subtract(const Duration(days: 1)),
                    ),
                  ),
                  _buildQuickDateChip(
                    ctx,
                    'This Week',
                    DateTimeRange(
                      start: DateTime.now().subtract(Duration(days: DateTime.now().weekday - 1)),
                      end: DateTime.now(),
                    ),
                  ),
                  _buildQuickDateChip(
                    ctx,
                    'This Month',
                    DateTimeRange(
                      start: DateTime(DateTime.now().year, DateTime.now().month, 1),
                      end: DateTime.now(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    final now = DateTime.now();
                    final picked = await showDateRangePicker(
                      context: context,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                      initialDateRange: _selectedDateRange ??
                          DateTimeRange(
                            start: DateTime(now.year, now.month, 1),
                            end: now,
                          ),
                      builder: (context, child) {
                        return Theme(
                          data: Theme.of(context).copyWith(
                            colorScheme: Theme.of(context).colorScheme.copyWith(
                                  primary: Theme.of(context).colorScheme.primary,
                                  onPrimary: Colors.black,
                                ),
                          ),
                          child: child!,
                        );
                      },
                    );
                    if (picked != null) {
                      setState(() {
                        _selectedDateRange = picked;
                      });
                    }
                  },
                  icon: const Icon(Icons.date_range, color: Colors.black),
                  label: const Text(
                    'Custom Date Range',
                    style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              if (_selectedDateRange != null) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _selectedDateRange = null;
                      });
                      Navigator.pop(ctx);
                    },
                    icon: const Icon(Icons.clear_all, color: Colors.redAccent),
                    label: const Text(
                      'Clear Date Filter',
                      style: TextStyle(color: Colors.redAccent),
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildQuickDateChip(BuildContext ctx, String label, DateTimeRange? range) {
    final isSelected = (_selectedDateRange == null && range == null) ||
        (_selectedDateRange != null &&
            range != null &&
            _selectedDateRange!.start.day == range.start.day &&
            _selectedDateRange!.end.day == range.end.day);

    return FilterChip(
      selected: isSelected,
      label: Text(label),
      selectedColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
      checkmarkColor: Theme.of(context).colorScheme.primary,
      onSelected: (selected) {
        setState(() {
          _selectedDateRange = range;
        });
        Navigator.pop(ctx);
      },
    );
  }

  void _showCustomerAnalyticsSheet(List<dynamic> customers, double totalOutstanding) {
    final numFormat = NumberFormat('#,##,###');
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final totalCustomersCount = customers.length;

        int dueCustomersCount = 0;
        int noDueCustomersCount = 0;
        int inactiveCount = 0;
        double inactiveDue = 0;

        double highestDue = 0;
        String highestDueCustomerName = '-';

        for (final c in customers) {
          final double due = ((c['outstandingBalance'] ?? 0) as num).toDouble();
          final bool isActive = c['isActive'] ?? true;
          final name = (c['name'] ?? c['customerName'] ?? 'Customer').toString();

          if (due > highestDue) {
            highestDue = due;
            highestDueCustomerName = name;
          }

          if (!isActive) {
            inactiveCount++;
            inactiveDue += due;
          }

          if (due > 0) {
            dueCustomersCount++;
          } else {
            noDueCustomersCount++;
          }
        }

        final avgDue = totalCustomersCount > 0 ? (totalOutstanding / totalCustomersCount) : 0.0;

        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF161C24) : Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
            ),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
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
                        'Customer Analytics & Insights',
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
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Total Outstanding Hero Card
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
                      'TOTAL CUSTOMER OUTSTANDING',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.8),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '₹${numFormat.format(totalOutstanding)}',
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
                          Icons.people_outline,
                          color: Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.9),
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '$totalCustomersCount Customers  •  $dueCustomersCount With Outstanding Due',
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

              // Customer Status Breakdown
              Text(
                'Customer Dues Breakdown',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 16),
              _buildAnalyticsBreakdownRow(
                label: 'With Outstanding Dues ($dueCustomersCount)',
                valueStr: '₹${numFormat.format(totalOutstanding)}',
                amount: totalOutstanding,
                totalAmount: totalOutstanding > 0 ? totalOutstanding : 1,
                icon: Icons.pending_outlined,
                color: Colors.redAccent,
              ),
              const SizedBox(height: 12),
              _buildAnalyticsBreakdownRow(
                label: 'Clear / No Dues ($noDueCustomersCount)',
                valueStr: '₹0',
                amount: 0,
                totalAmount: totalOutstanding > 0 ? totalOutstanding : 1,
                icon: Icons.check_circle_outline,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 12),
              _buildAnalyticsBreakdownRow(
                label: 'Inactive Accounts ($inactiveCount)',
                valueStr: '₹${numFormat.format(inactiveDue)}',
                amount: inactiveDue,
                totalAmount: totalOutstanding > 0 ? totalOutstanding : 1,
                icon: Icons.timelapse,
                color: Colors.amberAccent,
              ),
              const SizedBox(height: 24),

              // Key Metric Cards Row
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
                            'Highest Due Customer',
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).colorScheme.outline,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '₹${numFormat.format(highestDue)}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (highestDueCustomerName != '-')
                            Text(
                              highestDueCustomerName,
                              style: TextStyle(
                                fontSize: 10,
                                color: Theme.of(context).colorScheme.outline,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
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
                            'Avg Due per Customer',
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).colorScheme.outline,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '₹${numFormat.format(avgDue.round())}',
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
        );
      },
    );
  }

  Widget _buildAnalyticsBreakdownRow({
    required String label,
    required String valueStr,
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
                    valueStr,
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
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct,
              backgroundColor: color.withValues(alpha: 0.15),
              color: color,
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderIconButton(
    IconData icon, {
    bool isActive = false,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isActive
                ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.25)
                : Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isActive
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.primary.withValues(alpha: 0.4),
              width: 1.5,
            ),
          ),
          child: Icon(
            icon,
            color: Theme.of(context).colorScheme.primary,
            size: 20,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final numFormat = NumberFormat('#,##,###');

    // Apply filtering
    List<dynamic> filteredCustomers = _customers.where((customer) {
      if (_selectedFilter == 'Outstanding') {
        if ((customer['outstandingBalance'] ?? 0) <= 0) return false;
      } else if (_selectedFilter == 'Inactive') {
        if (customer['isActive'] != false) return false;
      }

      if (_selectedDateRange != null) {
        final rawDate = customer['createdDate'] ?? customer['updatedDate'] ?? customer['created_at'];
        if (rawDate != null) {
          final date = DateTime.tryParse(rawDate.toString());
          if (date != null) {
            final inRange = date.isAfter(_selectedDateRange!.start.subtract(const Duration(seconds: 1))) &&
                date.isBefore(_selectedDateRange!.end.add(const Duration(days: 1)));
            if (!inRange) return false;
          }
        }
      }

      if (_searchQuery.trim().isNotEmpty) {
        final query = _searchQuery.trim().toLowerCase();
        final name = (customer['name'] ?? customer['customerName'] ?? '').toString().toLowerCase();
        final phone = (customer['phone'] ?? customer['phoneNumber'] ?? customer['mobileNumber'] ?? '').toString().toLowerCase();
        final address = (customer['address'] ?? '').toString().toLowerCase();
        final email = (customer['email'] ?? '').toString().toLowerCase();

        return name.contains(query) ||
            phone.contains(query) ||
            address.contains(query) ||
            email.contains(query);
      }

      return true;
    }).toList();

    double totalOutstanding = filteredCustomers.fold(
      0,
      (sum, item) => sum + (item['outstandingBalance'] ?? 0),
    );

    if (_isLoading) {
      return const ListSkeleton(title: 'Customers');
    }

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
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // App Bar Area
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
                            Icons.people_alt_rounded,
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
                                'Customers',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.onSurface,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Manage customer accounts',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.primary.withValues(
                                    alpha: 0.8,
                                  ),
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        _buildHeaderIconButton(
                          Icons.calendar_month,
                          isActive: _selectedDateRange != null,
                          tooltip: 'Filter Customers by Date',
                          onTap: _showDateFilterModal,
                        ),
                        const SizedBox(width: 10),
                        _buildHeaderIconButton(
                          Icons.insert_chart_outlined,
                          tooltip: 'Customer Analytics',
                          onTap: () => _showCustomerAnalyticsSheet(filteredCustomers, totalOutstanding),
                        ),
                      ],
                    ),
                  ),

                  // Search Bar
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
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
                      child: Row(
                        children: [
                          Icon(
                            Icons.search,
                            color: Theme.of(context).colorScheme.outline,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
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
                                hintText: 'Search name or phone',
                                hintStyle: TextStyle(
                                  color: Theme.of(context).colorScheme.outline,
                                  fontSize: 14,
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

                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  if (_selectedDateRange != null) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.calendar_month,
                              size: 14,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${DateFormat('dd MMM').format(_selectedDateRange!.start)} - ${DateFormat('dd MMM yyyy').format(_selectedDateRange!.end)}',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedDateRange = null;
                                });
                              },
                              child: const Icon(
                                Icons.close,
                                size: 16,
                                color: Colors.redAccent,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Chips
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      children: [
                        _buildChip('All'),
                        const SizedBox(width: 8),
                        _buildChip('Outstanding'),
                        const SizedBox(width: 8),
                        _buildChip('Inactive'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Stats Row
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 16,
                        horizontal: 20,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Theme.of(context).primaryColor.withValues(alpha: 0.5)
                            : Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.people,
                                  color: Theme.of(context).colorScheme.primary,
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${filteredCustomers.length}',
                                    style: TextStyle(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primary,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    'Customers',
                                    style: TextStyle(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .outline,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Container(
                            height: 30,
                            width: 1,
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1),
                          ),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.currency_rupee,
                                  color: Theme.of(context).colorScheme.primary,
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '₹${numFormat.format(totalOutstanding)}',
                                    style: TextStyle(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primary,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    'Total Outstanding',
                                    style: TextStyle(
                                      color: Theme.of(context).colorScheme.primary.withValues(
                                        alpha: 0.8,
                                      ),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Customer List
                  Expanded(
                    child: filteredCustomers.isEmpty
                        ? Center(
                            child: Text(
                              'No customers found',
                              style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54)),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            itemCount: filteredCustomers.length,
                            itemBuilder: (context, index) {
                              final customer = filteredCustomers[index];
                              final bool isActive =
                                  customer['isActive'] ?? true;
                              final double due =
                                  (customer['outstandingBalance'] ?? 0)
                                      .toDouble();

                              String name = customer['name'] ?? 'Unknown';
                              String initials = name.isNotEmpty
                                  ? name
                                        .split(' ')
                                        .map((e) => e.isNotEmpty ? e[0] : '')
                                        .take(2)
                                        .join('')
                                        .toUpperCase()
                                  : 'U';

                              return GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          CustomerDetailsScreen(
                                            customer: customer,
                                          ),
                                    ),
                                  );
                                },
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).brightness == Brightness.dark
                                        ? Theme.of(context).primaryColor.withValues(alpha: 0.5)
                                        : Theme.of(context).colorScheme.surface,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Theme.of(context).colorScheme.onSurface.withValues(
                                        alpha: 0.05,
                                      ),
                                    ),
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        width: 48,
                                        height: 48,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .primary,
                                            width: 1,
                                          ),
                                        ),
                                        child: Center(
                                          child: Text(
                                            initials,
                                            style: TextStyle(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .primary,
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              name,
                                              style: TextStyle(
                                                color: Theme.of(context).colorScheme.onSurface,
                                                fontSize: 16,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              customer['phone'] ?? 'No Phone',
                                              style: TextStyle(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .outline,
                                                fontSize: 13,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Row(
                                              children: [
                                                Container(
                                                  width: 8,
                                                  height: 8,
                                                  decoration: BoxDecoration(
                                                    color: isActive
                                                        ? Theme.of(context).colorScheme.primary
                                                        : Colors.redAccent,
                                                    shape: BoxShape.circle,
                                                  ),
                                                ),
                                                const SizedBox(width: 6),
                                                Text(
                                                  isActive
                                                      ? 'Active'
                                                      : 'Inactive',
                                                  style: TextStyle(
                                                    color: isActive
                                                        ? Theme.of(context).colorScheme.primary
                                                        : Colors.redAccent,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            Row(
                                              children: [
                                                Icon(
                                                  Icons.calendar_today,
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .outline,
                                                  size: 12,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  customer['lastActivity'] ??
                                                      'Unknown',
                                                  style: TextStyle(
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .outline,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          Row(
                                            children: [
                                              Text(
                                                due > 0
                                                    ? '₹${numFormat.format(due)} Due'
                                                    : 'No Due',
                                                style: TextStyle(
                                                  color: due > 0
                                                      ? Colors.redAccent
                                                      : Theme.of(context).colorScheme.primary,
                                                  fontSize: 13,
                                                  fontWeight: due > 0
                                                      ? FontWeight.w500
                                                      : FontWeight.normal,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Icon(
                                                Icons.more_vert,
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .primary,
                                                size: 20,
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 24),
                                          Icon(
                                            Icons.chevron_right,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .primary,
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                  const SizedBox(height: 80), // Space for FAB
                ],
              ),

              // Floating Action Button Overlay
              Positioned(
                bottom: 24,
                left: 0,
                right: 0,
                child: Center(
                  child: GestureDetector(
                    onTap: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CustomerFormScreen(),
                        ),
                      );
                      if (result == true) {
                        _fetchCustomers(); // Refresh list if customer was added
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Theme.of(context).colorScheme.primary,
                            Theme.of(context).colorScheme.secondary,
                          ],
                        ),

                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.add, color: Theme.of(context).colorScheme.onPrimary, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Add Customer',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChip(String label) {
    bool isSelected = _selectedFilter == label;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = label;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.transparent
              : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Colors.transparent,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
