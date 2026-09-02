import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../services/customer_service.dart';
import '../../services/product_service.dart';
import '../../services/sale_service.dart';
import '../../utils/app_events.dart';

class SaleFormScreen extends StatefulWidget {
  final Map<String, dynamic>? existingSale;

  const SaleFormScreen({super.key, this.existingSale});

  @override
  State<SaleFormScreen> createState() => _SaleFormScreenState();
}

class _SaleFormScreenState extends State<SaleFormScreen> {
  bool _isLoading = false;
  bool _isEditMode = false;

  Map<String, dynamic>? _selectedCustomer;
  List<Map<String, dynamic>> _customers = [];
  List<Map<String, dynamic>> _products = [];

  List<Map<String, dynamic>> _saleItems = [];

  final _paidAmountController = TextEditingController();

  final numFormat = NumberFormat('#,##,###');

  @override
  void initState() {
    super.initState();
    _isEditMode = widget.existingSale != null;
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final customers = await CustomerService.getCustomers();
      final products = await ProductService.getProducts();

      setState(() {
        _customers = customers?.cast<Map<String, dynamic>>() ?? [];
        _products = products.where((p) => p['isActive'] == true).toList();
      });

      if (_isEditMode) {
        _initializeEditMode();
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _initializeEditMode() {
    final sale = widget.existingSale!;

    // Find customer
    _selectedCustomer = _customers.firstWhere(
      (c) => c['id'] == sale['customerId'],
      orElse: () => {
        'id': sale['customerId'],
        'name': sale['customerName'],
        'mobileNumber': sale['customerPhone'] ?? '',
        'currentBalance': 0, // Fallback
      },
    );

    // Initialize items
    if (sale['saleItems'] != null) {
      _saleItems = List<Map<String, dynamic>>.from(sale['saleItems'])
          .map((item) {
            final product = _products.firstWhere(
              (p) => p['id'] == item['productId'],
              orElse: () => <String, dynamic>{},
            );
            return {
              'productId': item['productId'],
              'productName': item['productName'],
              'brandName': item['brandName'] ?? product['brandName'] ?? '',
              'bagSize': item['bagSize'] ?? product['bagSize'] ?? 0,
              'imageUrl': product['imageUrl'] ?? '',
              'availableStock': product['currentStock'] ?? 0,
              'quantity': item['quantity'],
              'rate': item['rate'],
              'amount': item['amount'],
            };
          })
          .toList();
    }

    _paidAmountController.text = sale['paidAmount'].toString();
  }

  double get _totalAmount {
    return _saleItems.fold(
      0.0,
      (sum, item) => sum + ((item['quantity'] as num) * (item['rate'] as num)),
    );
  }

  int get _totalBags {
    return _saleItems.fold(
      0,
      (sum, item) => sum + (item['quantity'] as num).toInt(),
    );
  }

  double get _paidAmount {
    return double.tryParse(_paidAmountController.text) ?? 0.0;
  }

  @override
  Widget build(BuildContext context) {
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
          child: _isLoading
              ? Center(
                  child: CircularProgressIndicator(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                )
              : Column(
                  children: [
                    _buildHeader(),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildCustomerSection(),
                            const SizedBox(height: 24),
                            _buildSaleItemsSection(),
                            const SizedBox(height: 24),
                            _buildPaymentSummarySection(),
                            if (_isEditMode) ...[
                              const SizedBox(height: 24),
                              _buildImpactPreviewSection(),
                            ],
                            const SizedBox(height: 32),
                            _buildActionButtons(),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: GestureDetector(
              onTap: () {
                if (Navigator.canPop(context)) Navigator.pop(context);
              },
              child: Icon(
                Icons.arrow_back,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      _isEditMode ? 'Edit Sale' : 'New Sale',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (_isEditMode) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'CORRECTION',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                Text(
                  _isEditMode
                      ? 'Correct Sale #${widget.existingSale!['id'].toString().padLeft(4, '0')}'
                      : 'Create customer bill',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Sale Date',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.outline,
                  fontSize: 10,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Theme.of(context).colorScheme.primary
                        .withValues(alpha: 0.5),
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    Text(
                      DateFormat('dd MMM yyyy').format(DateTime.now()),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.calendar_today,
                      color: Theme.of(context).colorScheme.primary,
                      size: 12,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Customer *',
          style: TextStyle(
            color: Theme.of(context).colorScheme.primary,
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        if (_isEditMode || _selectedCustomer != null)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark ? Theme.of(context).primaryColor.withValues(alpha: 0.5) : Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(context).colorScheme.primary
                    .withValues(alpha: 0.5),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      _selectedCustomer!['name'].substring(0, 2).toUpperCase(),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _selectedCustomer!['name'],
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _selectedCustomer!['mobileNumber'] ?? '',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
                          fontSize: 13,
                        ),
                      ),
                      if (_isEditMode)
                        Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Row(
                            children: [
                              Icon(
                                Icons.lock_outline,
                                color: Theme.of(context).colorScheme.outline,
                                size: 12,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Customer cannot be changed',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.outline,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Current Balance',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.outline,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '₹${numFormat.format(_selectedCustomer!['currentBalance'] ?? _selectedCustomer!['outstandingBalance'] ?? 0)}',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                if (_isEditMode) ...[
                  const SizedBox(width: 16),
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
                      Icons.lock_outline,
                      color: Theme.of(context).colorScheme.primary,
                      size: 20,
                    ),
                  ),
                ] else ...[
                  const SizedBox(width: 16),
                  GestureDetector(
                    onTap: () => setState(() => _selectedCustomer = null),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Active',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          )
        else
          LayoutBuilder(
            builder: (context, constraints) {
              return DropdownMenu<Map<String, dynamic>>(
                width: constraints.maxWidth,
                hintText: 'Search and select customer',
                textStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                inputDecorationTheme: InputDecorationTheme(
                  hintStyle: TextStyle(color: Theme.of(context).colorScheme.outline),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
                menuStyle: MenuStyle(
                  backgroundColor: WidgetStatePropertyAll(Theme.of(context).primaryColor),
                  elevation: const WidgetStatePropertyAll(8.0),
                ),
                enableFilter: true,
                enableSearch: true,
                trailingIcon: Icon(Icons.keyboard_arrow_down, color: Theme.of(context).colorScheme.primary),
                leadingIcon: Icon(Icons.search, color: Theme.of(context).colorScheme.outline, size: 20),
                onSelected: (Map<String, dynamic>? selected) {
                  setState(() => _selectedCustomer = selected);
                  // To clear focus and keyboard after selection
                  FocusScope.of(context).unfocus();
                },
                dropdownMenuEntries: _customers.map((c) {
                  final String name = c['name'] ?? '';
                  final String phone = c['mobileNumber'] ?? '';
                  final String label = phone.isNotEmpty ? '$name ($phone)' : name;
                  return DropdownMenuEntry<Map<String, dynamic>>(
                    value: c,
                    label: label,
                    style: MenuItemButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.onSurface,
                    ),
                  );
                }).toList(),
              );
            },
          ),
      ],
    );
  }

  Widget _buildSaleItemsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Sale Items',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ..._saleItems.asMap().entries.map(
          (entry) => _buildSaleItemCard(entry.key, entry.value),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: _showProductSelectionModal,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add, color: Theme.of(context).colorScheme.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Add Product',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSaleItemCard(int index, Map<String, dynamic> item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark ? Theme.of(context).primaryColor.withValues(alpha: 0.5) : Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 60,
            height: 80,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: Colors.black12,
            ),
            child: item['imageUrl'] != null && item['imageUrl'].isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      item['imageUrl'],
                      fit: BoxFit.cover,
                      errorBuilder: (c, e, s) =>
                          Icon(Icons.image, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.24)),
                    ),
                  )
                : Icon(Icons.image, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.24)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        item['productName'],
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _saleItems.removeAt(index);
                        });
                      },
                      child: Icon(
                        Icons.close,
                        color: Colors.redAccent,
                        size: 20,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${item['brandName']} • ${item['bagSize']} kg',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Available: ${item['availableStock']} bags',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Quantity',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.outline,
                              fontSize: 11,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            height: 36,
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: Theme.of(context).colorScheme.primary
                                    .withValues(alpha: 0.5),
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                InkWell(
                                  onTap: () {
                                    if (item['quantity'] > 1) {
                                      setState(() {
                                        item['quantity']--;
                                        item['amount'] =
                                            item['quantity'] * item['rate'];
                                      });
                                    }
                                  },
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 8,
                                    ),
                                    child: Icon(
                                      Icons.remove,
                                      color: Theme.of(context).colorScheme.primary,
                                      size: 16,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    '${item['quantity']} bags',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Theme.of(context).colorScheme.onSurface,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                                InkWell(
                                  onTap: () {
                                    setState(() {
                                      item['quantity']++;
                                      item['amount'] =
                                          item['quantity'] * item['rate'];
                                    });
                                  },
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 8,
                                    ),
                                    child: Icon(
                                      Icons.add,
                                      color: Theme.of(context).colorScheme.primary,
                                      size: 16,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Rate',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.outline,
                              fontSize: 11,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            height: 36,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: Theme.of(context).colorScheme.primary
                                    .withValues(alpha: 0.5),
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            alignment: Alignment.centerLeft,
                            child: TextFormField(
                              initialValue: item['rate'].toString(),
                              keyboardType: TextInputType.number,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurface,
                                fontSize: 13,
                              ),
                              decoration: InputDecoration(
                                prefixText: '₹',
                                prefixStyle: TextStyle(
                                  color: Theme.of(context).colorScheme.onSurface,
                                  fontSize: 13,
                                ),
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                                border: InputBorder.none,
                              ),
                              onChanged: (val) {
                                final newRate = double.tryParse(val) ?? 0;
                                setState(() {
                                  item['rate'] = newRate;
                                  item['amount'] = item['quantity'] * newRate;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Amount',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.outline,
                              fontSize: 11,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            height: 36,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: Theme.of(context).colorScheme.primary.withValues(
                                  alpha: 0.5,
                                ),
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '₹${numFormat.format(item['amount'] ?? 0)}',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurface,
                                fontSize: 13,
                              ),
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
    );
  }

  void _showProductSelectionModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).primaryColor,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        String searchQuery = '';
        return StatefulBuilder(
          builder: (context, setModalState) {
            final filteredProducts = _products.where((p) {
              final name = (p['name']?.toString() ?? '').toLowerCase();
              final brand = (p['brand']?.toString() ?? '').toLowerCase();
              final query = searchQuery.toLowerCase();
              return name.contains(query) || brand.contains(query);
            }).toList();

            return DraggableScrollableSheet(
              initialChildSize: 0.7,
              minChildSize: 0.5,
              maxChildSize: 0.9,
              expand: false,
              builder: (context, scrollController) {
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Select Product',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.close, color: Theme.of(context).colorScheme.onSurface),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: TextField(
                        style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                        decoration: InputDecoration(
                          hintText: 'Search product...',
                          hintStyle: TextStyle(color: Theme.of(context).colorScheme.outline),
                          prefixIcon: Icon(Icons.search, color: Theme.of(context).colorScheme.outline),
                          filled: true,
                          fillColor: Colors.black12,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                        onChanged: (val) {
                          setModalState(() {
                            searchQuery = val;
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: ListView.builder(
                        controller: scrollController,
                        itemCount: filteredProducts.length,
                        itemBuilder: (context, index) {
                          final product = filteredProducts[index];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.12),
                              backgroundImage:
                                  product['image'] != null &&
                                      product['image'].toString().isNotEmpty
                                  ? NetworkImage(product['image'])
                                  : null,
                              child:
                                  product['image'] == null ||
                                      product['image'].toString().isEmpty
                                  ? Icon(Icons.inventory, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54))
                                  : null,
                            ),
                            title: Text(
                              product['name']?.toString() ?? 'Unknown Product',
                              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                            ),
                            subtitle: Text(
                              '${product['brand'] ?? ''} • ₹${product['sellingPrice'] ?? 0} (Stock: ${product['currentStock'] ?? 0})',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.outline,
                              ),
                            ),
                            onTap: () {
                              setState(() {
                                // Check if already added
                                final existingIndex = _saleItems.indexWhere(
                                  (i) => i['productId'] == product['id'],
                                );
                                if (existingIndex >= 0) {
                                  _saleItems[existingIndex]['quantity']++;
                                  _saleItems[existingIndex]['amount'] =
                                      _saleItems[existingIndex]['quantity'] *
                                      _saleItems[existingIndex]['rate'];
                                } else {
                                  _saleItems.add({
                                    'productId': product['id'],
                                    'productName': product['name'] ?? 'Unknown Product',
                                    'brandName': product['brand'] ?? '',
                                    'bagSize': product['bagSize'],
                                    'imageUrl': product['image'],
                                    'availableStock': product['currentStock'] ?? 0,
                                    'quantity': 1,
                                    'rate': product['sellingPrice'] ?? 0,
                                    'amount': product['sellingPrice'] ?? 0,
                                  });
                                }
                              });
                              Navigator.pop(context);
                            },
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildPaymentSummarySection() {
    double originalTotal = _isEditMode
        ? (widget.existingSale!['totalAmount'] as num).toDouble()
        : 0.0;
    double originalPaid = _isEditMode
        ? (widget.existingSale!['paidAmount'] as num).toDouble()
        : 0.0;
    double currentBalance = _selectedCustomer?['currentBalance'] != null
        ? (_selectedCustomer!['currentBalance'] as num).toDouble()
        : _selectedCustomer?['outstandingBalance'] != null
            ? (_selectedCustomer!['outstandingBalance'] as num).toDouble()
            : 0.0;

    double balanceAmount = _totalAmount - _paidAmount;
    double newCustomerBalance = _isEditMode
        ? currentBalance
        : currentBalance + balanceAmount;

    if (_isEditMode) {
      double originalBalanceAdded = originalTotal - originalPaid;
      // Reverse old balance added, then add new balance
      newCustomerBalance =
          currentBalance - originalBalanceAdded + balanceAmount;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _isEditMode ? 'Payment Correction' : 'Payment Summary',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(context).colorScheme.primary
                  .withValues(alpha: 0.5),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_isEditMode) ...[
                Row(
                  children: [
                    Expanded(
                      child: _buildAmountColumn(
                        'Original Total',
                        originalTotal,
                        Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    _buildVerticalDivider(),
                    Expanded(
                      child: _buildAmountColumn(
                        'Revised Total',
                        _totalAmount,
                        Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    _buildVerticalDivider(),
                    Expanded(
                      child: _buildAmountColumn(
                        'Original Paid',
                        originalPaid,
                        Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ] else ...[
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Total Bags',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.outline,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$_totalBags',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontSize: 20,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _buildVerticalDivider(),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Total Amount',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.outline,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '₹${numFormat.format(_totalAmount)}',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontSize: 20,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
              Divider(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1)),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Paid Amount',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.outline,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _isEditMode
                              ? 'Ensure paid amount is not applied twice'
                              : 'Paid Now is applied once during this sale',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.outline,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Container(
                    width: 120,
                    height: 40,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.centerLeft,
                    child: TextFormField(
                      controller: _paidAmountController,
                      keyboardType: TextInputType.number,
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 16),
                      decoration: InputDecoration(
                        prefixText: '₹',
                        prefixStyle: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 16,
                        ),
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                        border: InputBorder.none,
                      ),
                      onChanged: (val) =>
                          setState(() {}), // rebuild to update balances
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Divider(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1)),
              const SizedBox(height: 16),
              if (!_isEditMode) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Balance Amount',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.outline,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      '₹${numFormat.format(balanceAmount)}',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _isEditMode ? 'Revised Balance' : 'New Customer Balance',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.outline,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    '₹${numFormat.format(newCustomerBalance)}',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
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
          style: TextStyle(color: valueColor, fontSize: 16),
        ),
      ],
    );
  }

  Widget _buildVerticalDivider() {
    return Container(
      height: 40,
      width: 1,
      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1),
      margin: const EdgeInsets.symmetric(horizontal: 16),
    );
  }

  Widget _buildImpactPreviewSection() {
    double originalTotal = (widget.existingSale!['totalAmount'] as num)
        .toDouble();
    double originalPaid = (widget.existingSale!['paidAmount'] as num)
        .toDouble();
    double originalBalanceAdded = originalTotal - originalPaid;

    double balanceAmount = _totalAmount - _paidAmount;

    double balanceAdjustment = balanceAmount - originalBalanceAdded;

    double currentBalance = _selectedCustomer?['currentBalance'] != null
        ? (_selectedCustomer!['currentBalance'] as num).toDouble()
        : _selectedCustomer?['outstandingBalance'] != null
            ? (_selectedCustomer!['outstandingBalance'] as num).toDouble()
            : 0.0;
    double newCustomerBalance = currentBalance + balanceAdjustment;

    // Calculate Stock adjustment
    int originalBags = (widget.existingSale!['totalQuantity'] as num).toInt();
    int bagAdjustment =
        originalBags - _totalBags; // If original was 8, new is 7, we return +1

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Impact Preview',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(context).colorScheme.primary
                  .withValues(alpha: 0.5),
            ),
          ),
          child: Column(
            children: [
              if (bagAdjustment != 0) ...[
                _buildImpactRow(
                  Icons.arrow_upward,
                  bagAdjustment > 0 ? 'Return to Stock' : 'Deduct from Stock',
                  '${bagAdjustment > 0 ? '+' : ''}$bagAdjustment Bag${bagAdjustment.abs() > 1 ? 's' : ''}',
                  bagAdjustment > 0 ? Theme.of(context).colorScheme.primary : Colors.redAccent,
                ),
                Divider(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1)),
              ],
              _buildImpactRow(
                Icons.person_outline,
                'Customer Balance Adjustment',
                '${balanceAdjustment > 0 ? '+' : ''} ₹${numFormat.format(balanceAdjustment)}',
                balanceAdjustment < 0 ? Colors.redAccent : Theme.of(context).colorScheme.primary,
              ),
              Divider(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1)),
              _buildImpactRow(
                Icons.account_balance_wallet_outlined,
                'Updated Customer Balance',
                '₹${numFormat.format(newCustomerBalance)}',
                Theme.of(context).colorScheme.primary,
              ),
              Divider(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1)),
              _buildImpactRow(
                Icons.menu_book,
                'Ledger Entry',
                'Recalculated',
                Colors.lightBlueAccent,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Theme.of(context).colorScheme.primary
                  .withValues(alpha: 0.5),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: Theme.of(context).colorScheme.primary,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Stock, customer balance and ledger will update together',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'This correction will be processed as one transaction.',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.outline,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildImpactRow(
    IconData icon,
    String label,
    String value,
    Color valueColor,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.outline, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: Theme.of(context).colorScheme.outline,
                fontSize: 13,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: valueColor,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: GestureDetector(
            onTap: _submitSale,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
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
                  Icon(
                    Icons.check_circle_outline, color: Theme.of(context).colorScheme.onPrimary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _isEditMode ? 'Update Sale' : 'Complete Sale',
                    style: TextStyle(
                      color: Colors.black,
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
    );
  }

  Future<void> _submitSale() async {
    if (_selectedCustomer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a customer.')),
      );
      return;
    }
    if (_saleItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one product.')),
      );
      return;
    }
    if (_paidAmount > _totalAmount) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Paid amount cannot exceed total amount.'),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final saleData = {
        'customerId': _selectedCustomer!['id'],
        'paidAmount': _paidAmount,
        'paymentMode': _paidAmount > 0 ? 'Cash' : '',
        'saleItems': _saleItems
            .map(
              (item) => {
                'productId': item['productId'],
                'quantity': item['quantity'],
                'rate': item['rate'],
              },
            )
            .toList(),
      };

      if (_isEditMode) {
        await SaleService.updateSale(widget.existingSale!['id'], saleData);
      } else {
        await SaleService.createSale(saleData);
      }
      
      AppEvents.triggerRefresh(); // Trigger global data refresh

      if (mounted) {
        Navigator.pop(context, true); // Return true to indicate success
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }
}

