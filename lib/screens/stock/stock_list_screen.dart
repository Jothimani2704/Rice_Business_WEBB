import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../services/product_service.dart';
import '../../services/stock_service.dart';
import '../../utils/app_events.dart';
import '../../widgets/skeleton_loader.dart';
import 'stock_form_screen.dart';
import 'stock_detail_screen.dart';

class StockListScreen extends StatefulWidget {
  const StockListScreen({super.key});

  @override
  State<StockListScreen> createState() => _StockListScreenState();
}

class _StockListScreenState extends State<StockListScreen> {
  List<Map<String, dynamic>> _inventory = [];
  bool _isLoading = true;
  String _selectedFilter = 'All Stock';
  DateTimeRange? _selectedDateRange;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String _searchQuery = '';

  final numFormat = NumberFormat('#,##,###');

  @override
  void initState() {
    super.initState();
    _fetchInventory();
    AppEvents.refreshData.addListener(_fetchInventory);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    AppEvents.refreshData.removeListener(_fetchInventory);
    super.dispose();
  }

  Future<void> _fetchInventory() async {
    if (_inventory.isEmpty) {
      setState(() => _isLoading = true);
    }
    try {
      final products = await ProductService.getProducts();
      if (mounted) {
        setState(() {
          _inventory = products;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
      print('Error fetching inventory: $e');
    }
  }

  double get _totalBags {
    return _inventory.fold(
      0.0,
      (sum, item) => sum + (item['currentStock'] as num),
    );
  }

  double get _stockValue {
    return _inventory.fold(0.0, (sum, item) {
      final stock = (item['currentStock'] as num).toDouble();
      final price = (item['purchasePrice'] as num).toDouble();
      return sum + (stock * price);
    });
  }

  int get _lowStockCount {
    return _inventory.where((p) => p['status'] == 'Low Stock').length;
  }

  int get _outOfStockCount {
    return _inventory.where((p) => (p['currentStock'] as num) == 0).length;
  }

  List<Map<String, dynamic>> get _filteredInventory {
    List<Map<String, dynamic>> list = _inventory;

    if (_selectedFilter != 'All Stock') {
      list = list.where((p) => p['status'] == _selectedFilter).toList();
    }

    if (_selectedDateRange != null) {
      list = list.where((p) {
        final rawDate = p['updatedDate'] ?? p['createdDate'] ?? p['date'];
        if (rawDate == null) return true;
        final date = DateTime.tryParse(rawDate.toString());
        if (date == null) return true;
        return date.isAfter(_selectedDateRange!.start.subtract(const Duration(seconds: 1))) &&
            date.isBefore(_selectedDateRange!.end.add(const Duration(days: 1)));
      }).toList();
    }

    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.trim().toLowerCase();
      list = list.where((p) {
        final name = (p['name'] ?? p['productName'] ?? '').toString().toLowerCase();
        final brand = (p['brand'] ?? p['brandName'] ?? p['category'] ?? '').toString().toLowerCase();
        final code = (p['productCode'] ?? p['code'] ?? '').toString().toLowerCase();
        final size = (p['bagSize'] ?? p['size'] ?? '').toString().toLowerCase();
        return name.contains(q) || brand.contains(q) || code.contains(q) || size.contains(q);
      }).toList();
    }

    return list;
  }

  void _showStockHistorySheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const _StockHistoryBottomSheet(),
    );
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
                        'Filter Stock by Date',
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

  void _showStockAnalyticsSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final totalProds = _inventory.length;
        final totalStockBags = _totalBags;
        final totalVal = _stockValue;
        final lowStockCount = _lowStockCount;
        final outOfStockCount = _outOfStockCount;
        final inStockCount = totalProds - lowStockCount - outOfStockCount;

        double inStockBags = 0;
        double lowStockBags = 0;
        double outOfStockBags = 0;

        double maxStockItemBags = 0;
        String maxStockItemName = '-';

        for (final p in _inventory) {
          final stock = (p['currentStock'] as num).toDouble();
          final minLevel = (p['minimumStockLevel'] as num).toDouble();
          final name = (p['name'] ?? p['productName'] ?? 'Product').toString();

          if (stock > maxStockItemBags) {
            maxStockItemBags = stock;
            maxStockItemName = name;
          }

          if (stock == 0) {
            outOfStockBags += stock;
          } else if (stock <= minLevel) {
            lowStockBags += stock;
          } else {
            inStockBags += stock;
          }
        }

        final avgStockBags = totalProds > 0 ? (totalStockBags / totalProds) : 0.0;

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
                        'Stock Analytics & Insights',
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

              // Total Stock Asset Value Card
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
                      'TOTAL STOCK ASSET VALUE',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.8),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '₹${numFormat.format(totalVal)}',
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
                          Icons.inventory_2_outlined,
                          color: Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.9),
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${numFormat.format(totalStockBags)} Total Bags  •  $totalProds Products',
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

              // Stock Status Breakdown
              Text(
                'Stock Status Breakdown',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 16),
              _buildAnalyticsBreakdownRow(
                label: 'In Stock / Healthy ($inStockCount)',
                valueStr: '${numFormat.format(inStockBags)} Bags',
                amount: inStockBags,
                totalAmount: totalStockBags > 0 ? totalStockBags : 1,
                icon: Icons.check_circle_outline,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 12),
              _buildAnalyticsBreakdownRow(
                label: 'Low Stock ($lowStockCount)',
                valueStr: '${numFormat.format(lowStockBags)} Bags',
                amount: lowStockBags,
                totalAmount: totalStockBags > 0 ? totalStockBags : 1,
                icon: Icons.timelapse,
                color: Colors.amberAccent,
              ),
              const SizedBox(height: 12),
              _buildAnalyticsBreakdownRow(
                label: 'Out of Stock ($outOfStockCount)',
                valueStr: '0 Bags',
                amount: 0,
                totalAmount: totalStockBags > 0 ? totalStockBags : 1,
                icon: Icons.pending_outlined,
                color: Colors.redAccent,
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
                            'Highest Stock Item',
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).colorScheme.outline,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${numFormat.format(maxStockItemBags)} Bags',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (maxStockItemName != '-')
                            Text(
                              maxStockItemName,
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
                            'Avg Stock per Product',
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).colorScheme.outline,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${numFormat.format(avgStockBags.round())} Bags',
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
    if (_isLoading) {
      return const ListSkeleton(title: 'Stock');
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
                        Icons.warehouse_rounded,
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
                            'Stock',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Track rice inventory',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _buildHeaderIconButton(
                      Icons.calendar_month,
                      isActive: _selectedDateRange != null,
                      tooltip: 'Filter Stock by Date',
                      onTap: _showDateFilterModal,
                    ),
                    const SizedBox(width: 10),
                    _buildHeaderIconButton(
                      Icons.insert_chart_outlined,
                      tooltip: 'Stock Analytics',
                      onTap: _showStockAnalyticsSheet,
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
                            hintText: 'Search product or brand',
                            hintStyle: TextStyle(
                              color: Theme.of(context).colorScheme.outline,
                            ),
                            border: InputBorder.none,
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: Icon(
                                      Icons.clear,
                                      size: 18,
                                      color: Theme.of(context).colorScheme.outline,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _searchController.clear();
                                        _searchQuery = '';
                                      });
                                    },
                                  )
                                : null,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
                        ),
                      ),
                      child: Icon(
                        Icons.filter_alt_outlined,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
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

              // Metric Cards
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    _buildMetricCard(
                      icon: Icons.inventory_2_outlined,
                      title: 'Total Stock',
                      value: numFormat.format(_totalBags),
                      subtitle: 'Bags',
                      iconColor: Theme.of(context).colorScheme.onSurface,
                      iconBgColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2),
                      valueColor: Theme.of(context).colorScheme.onSurface,
                    ),
                    const SizedBox(width: 12),
                    _buildMetricCard(
                      icon: Icons.currency_rupee,
                      title: 'Stock Value',
                      value: '₹${numFormat.format(_stockValue)}',
                      subtitle: '',
                      iconColor: Theme.of(context).colorScheme.primary,
                      iconBgColor: Theme.of(context).colorScheme.primary
                          .withValues(alpha: 0.1),
                      valueColor: Theme.of(context).colorScheme.onSurface,
                    ),
                    const SizedBox(width: 12),
                    _buildMetricCard(
                      icon: Icons.error_outline,
                      title: 'Low Stock',
                      value: _lowStockCount.toString(),
                      subtitle: 'Products',
                      iconColor: Colors.redAccent,
                      iconBgColor: Colors.redAccent.withValues(alpha: 0.1),
                      valueColor: Theme.of(context).colorScheme.onSurface,
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
                        onTap: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const StockFormScreen(),
                            ),
                          );
                          if (result == true) {
                            _fetchInventory();
                          }
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
                              const Text(
                                'Stock Inward',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
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
                        onTap: () => _showStockHistorySheet(context),
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
                                Icons.history,
                                color: Theme.of(context).colorScheme.primary,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'View History',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
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
              const SizedBox(height: 16),

              // Filter Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    _buildFilterChip('All Stock'),
                    const SizedBox(width: 8),
                    _buildFilterChip('Low Stock'),
                    const SizedBox(width: 8),
                    _buildFilterChip('Out of Stock'),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Section Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  'Current Inventory',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Product List
              Expanded(
                child: _filteredInventory.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.inventory_2_outlined,
                              size: 48,
                              color: Theme.of(context).colorScheme.outline,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'No products found',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.outline,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _fetchInventory,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _filteredInventory.length,
                          itemBuilder: (context, index) {
                            final item = _filteredInventory[index];
                            return _buildInventoryCard(item);
                          },
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricCard({
    required IconData icon,
    required String title,
    required String value,
    required String subtitle,
    required Color iconColor,
    required Color iconBgColor,
    required Color valueColor,
    Color? titleColor,
  }) {
    return Container(
      width: 140,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2),
        ),
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
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: iconColor, size: 16),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: titleColor ?? Theme.of(context).colorScheme.outline,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              color: valueColor,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (subtitle.isNotEmpty)
            Text(
              subtitle,
              style: TextStyle(
                color: Theme.of(context).colorScheme.outline,
                fontSize: 11,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = _selectedFilter == label;
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
              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.onSurface,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildInventoryCard(Map<String, dynamic> item) {
    final double stock = (item['currentStock'] as num).toDouble();
    final double minLevel = (item['minimumStockLevel'] as num).toDouble();
    final isLowStock = stock <= minLevel && stock > 0;
    final isOut = stock == 0;

    Color statusColor = Theme.of(context).colorScheme.primary;
    if (isLowStock) statusColor = Colors.orangeAccent;
    if (isOut) statusColor = Colors.redAccent;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2),
        ),
      ),
      child: InkWell(
        onTap: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => StockDetailScreen(product: item),
            ),
          );
          if (result == true) {
            _fetchInventory();
          }
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14.0),
          child: Row(
            children: [
              // Bag Image Container
              Container(
                width: 54,
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.4),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.asset(
                    'assets/images/rice_bag.png',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(
                        Icons.inventory_2,
                        color: Theme.of(context).colorScheme.primary,
                        size: 28,
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(width: 14),

              // Details Column
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item['name'] ?? item['productName'] ?? 'Rice Product',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Icon(
                          Icons.chevron_right,
                          color: Theme.of(context).colorScheme.outline,
                          size: 20,
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${item['brand'] ?? item['brandName'] ?? 'Brand'} • ${item['bagSize'] ?? item['size'] ?? '25 kg'}',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.outline,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${numFormat.format(item['currentStock'])} bags',
                            style: TextStyle(
                              color: isOut
                                  ? Colors.redAccent
                                  : (isLowStock
                                        ? Colors.redAccent
                                        : Theme.of(context).colorScheme.primary),
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 20,
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Min: ${numFormat.format(item['minimumStockLevel'])} bags',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.outline,
                            fontSize: 12,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: statusColor.withValues(alpha: 0.5),
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
                                  color: statusColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                item['status'],
                                style: TextStyle(
                                  color: statusColor,
                                  fontSize: 11,
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
            ],
          ),
        ),
      ),
    );
  }
}

class _StockHistoryBottomSheet extends StatefulWidget {
  const _StockHistoryBottomSheet();

  @override
  State<_StockHistoryBottomSheet> createState() => _StockHistoryBottomSheetState();
}

class _StockHistoryBottomSheetState extends State<_StockHistoryBottomSheet> {
  List<Map<String, dynamic>> _transactions = [];
  bool _isLoading = true;
  String _typeFilter = 'All'; // 'All', 'Inward', 'Outward', 'Adjustment'
  DateTimeRange? _selectedDateRange;

  final numFormat = NumberFormat('#,##,###');

  @override
  void initState() {
    super.initState();
    _fetchTransactions();
  }

  Future<void> _fetchTransactions() async {
    setState(() => _isLoading = true);
    try {
      final list = await StockService.getStockTransactions();
      if (mounted) {
        setState(() {
          _transactions = list;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
      print('Error fetching stock transactions: $e');
    }
  }

  List<Map<String, dynamic>> get _filteredTransactions {
    List<Map<String, dynamic>> result = _transactions;

    // Filter by type
    if (_typeFilter != 'All') {
      result = result.where((tx) {
        final typeStr = (tx['transactionType'] ?? '').toString().toLowerCase();
        if (_typeFilter == 'Inward') {
          return typeStr == 'inward' || typeStr == '0';
        } else if (_typeFilter == 'Outward') {
          return typeStr == 'outward' || typeStr == '1';
        } else if (_typeFilter == 'Adjustment') {
          return typeStr == 'adjustment' || typeStr == '2';
        }
        return true;
      }).toList();
    }

    // Filter by date range
    if (_selectedDateRange != null) {
      result = result.where((tx) {
        final rawDate = tx['transactionDate'] ?? tx['createdDate'];
        if (rawDate == null) return false;
        final date = DateTime.tryParse(rawDate.toString());
        if (date == null) return false;
        return date.isAfter(_selectedDateRange!.start.subtract(const Duration(seconds: 1))) &&
            date.isBefore(_selectedDateRange!.end.add(const Duration(days: 1)));
      }).toList();
    }

    return result;
  }

  double get _totalInward {
    return _transactions.fold(0.0, (sum, tx) {
      final typeStr = (tx['transactionType'] ?? '').toString().toLowerCase();
      if (typeStr == 'inward' || typeStr == '0') {
        return sum + ((tx['quantity'] as num?)?.toDouble() ?? 0.0);
      }
      return sum;
    });
  }

  double get _totalOutward {
    return _transactions.fold(0.0, (sum, tx) {
      final typeStr = (tx['transactionType'] ?? '').toString().toLowerCase();
      if (typeStr == 'outward' || typeStr == '1') {
        return sum + ((tx['quantity'] as num?)?.toDouble() ?? 0.0);
      }
      return sum;
    });
  }

  double get _netChange => _totalInward - _totalOutward;

  Future<void> _selectDateRange() async {
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
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161C24) : Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          // Drag handle & Header bar
          const SizedBox(height: 12),
          Container(
            width: 44,
            height: 5,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.history,
                    color: Theme.of(context).colorScheme.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Stock Movement History',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Track all inward, outward & adjustment transactions',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.close,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Divider(
            height: 1,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1),
          ),

          // Scrollable Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Summary Cards
                  Row(
                    children: [
                      Expanded(
                        child: _buildSummaryCard(
                          title: 'Total Inward',
                          value: '+${numFormat.format(_totalInward)}',
                          subtitle: 'Bags Received',
                          icon: Icons.south_west_rounded,
                          color: Colors.greenAccent,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildSummaryCard(
                          title: 'Total Outward',
                          value: '-${numFormat.format(_totalOutward)}',
                          subtitle: 'Bags Sold',
                          icon: Icons.north_east_rounded,
                          color: Colors.redAccent,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildSummaryCard(
                          title: 'Net Change',
                          value: '${_netChange >= 0 ? '+' : ''}${numFormat.format(_netChange)}',
                          subtitle: 'Balance Shift',
                          icon: Icons.swap_vert_rounded,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Filter Chips & Date Picker Row
                  Row(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _buildTypeChip('All', 'All Movements'),
                              const SizedBox(width: 8),
                              _buildTypeChip('Inward', '📥 Inward'),
                              const SizedBox(width: 8),
                              _buildTypeChip('Outward', '📤 Outward'),
                              const SizedBox(width: 8),
                              _buildTypeChip('Adjustment', '⚙️ Adjustment'),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: _selectDateRange,
                        icon: Icon(
                          _selectedDateRange == null
                              ? Icons.calendar_month_outlined
                              : Icons.edit_calendar,
                          color: _selectedDateRange == null
                              ? Theme.of(context).colorScheme.outline
                              : Theme.of(context).colorScheme.primary,
                          size: 22,
                        ),
                        tooltip: 'Filter by Date',
                      ),
                      if (_selectedDateRange != null)
                        IconButton(
                          onPressed: () {
                            setState(() {
                              _selectedDateRange = null;
                            });
                          },
                          icon: const Icon(
                            Icons.close,
                            color: Colors.redAccent,
                            size: 18,
                          ),
                          tooltip: 'Clear Date Filter',
                        ),
                    ],
                  ),
                  if (_selectedDateRange != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.filter_alt,
                            size: 14,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Date: ${DateFormat('dd MMM yyyy').format(_selectedDateRange!.start)} - ${DateFormat('dd MMM yyyy').format(_selectedDateRange!.end)}',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),

                  // Section Title
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Transactions (${_filteredTransactions.length})',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (_isLoading)
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Transaction List
                  if (_isLoading)
                    const Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else if (_filteredTransactions.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.15),
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.history_toggle_off_rounded,
                            size: 48,
                            color: Theme.of(context).colorScheme.outline,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No stock movement records found',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.outline,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _filteredTransactions.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final tx = _filteredTransactions[index];
                        return _buildTransactionCard(tx);
                      },
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.outline,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(
              color: Theme.of(context).colorScheme.outline,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeChip(String value, String label) {
    final isSelected = _typeFilter == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _typeFilter = value;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.onSurface,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionCard(Map<String, dynamic> tx) {
    final typeStr = (tx['transactionType'] ?? '').toString().toLowerCase();
    final isInward = typeStr == 'inward' || typeStr == '0';
    final isOutward = typeStr == 'outward' || typeStr == '1';

    Color cardColor = Theme.of(context).colorScheme.primary;
    IconData cardIcon = Icons.tune;
    String sign = '';

    if (isInward) {
      cardColor = Colors.greenAccent;
      cardIcon = Icons.add_circle_outline;
      sign = '+';
    } else if (isOutward) {
      cardColor = Colors.redAccent;
      cardIcon = Icons.remove_circle_outline;
      sign = '-';
    }

    final qty = (tx['quantity'] as num?)?.toDouble() ?? 0.0;
    final productName = tx['productName'] ?? 'Product #${tx['productId']}';
    final rawDate = tx['transactionDate'] ?? tx['createdDate'];
    String formattedDate = 'Recently';
    if (rawDate != null) {
      final parsed = DateTime.tryParse(rawDate.toString());
      if (parsed != null) {
        formattedDate = DateFormat('dd MMM yyyy, hh:mm a').format(parsed);
      }
    }

    final notes = tx['notes'] ?? tx['remarks'] ?? tx['customerName'] ?? tx['referenceType'];
    final prevStock = (tx['previousStock'] as num?)?.toDouble();
    final newStock = (tx['newStock'] as num?)?.toDouble();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.15),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: cardColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: cardColor.withValues(alpha: 0.3),
              ),
            ),
            child: Icon(cardIcon, color: cardColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  productName.toString(),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (notes != null && notes.toString().isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    notes.toString(),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.outline,
                      fontSize: 11,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  formattedDate,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.8),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: cardColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$sign${numFormat.format(qty)} bags',
                  style: TextStyle(
                    color: cardColor,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (prevStock != null && newStock != null) ...[
                const SizedBox(height: 4),
                Text(
                  '${numFormat.format(prevStock)} ➔ ${numFormat.format(newStock)}',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.outline,
                    fontSize: 11,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
