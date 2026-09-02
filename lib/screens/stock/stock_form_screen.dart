import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../services/product_service.dart';
import '../../services/stock_service.dart';
import '../../utils/app_events.dart';

class StockFormScreen extends StatefulWidget {
  final Map<String, dynamic>?
  transaction; // If null, it's Add Mode (Stock Inward)
  final Map<String, dynamic>? preselectedProduct;

  const StockFormScreen({super.key, this.transaction, this.preselectedProduct});

  @override
  State<StockFormScreen> createState() => _StockFormScreenState();
}

class _StockFormScreenState extends State<StockFormScreen> {
  List<Map<String, dynamic>> _products = [];
  bool _isLoadingProducts = true;
  bool _isSaving = false;

  Map<String, dynamic>? _selectedProduct;
  final _quantityController = TextEditingController();
  final _remarksController = TextEditingController();
  DateTime _selectedDate = DateTime.now();

  final numFormat = NumberFormat('#,##,###');

  bool get isEditMode => widget.transaction != null;

  @override
  void initState() {
    super.initState();
    _fetchProducts();

    if (isEditMode) {
      _quantityController.text = widget.transaction!['quantity'].toString();
      _remarksController.text = widget.transaction!['notes'] ?? '';
      _selectedDate = DateTime.parse(
        widget.transaction!['transactionDate'] ??
            DateTime.now().toIso8601String(),
      );
    }

    _quantityController.addListener(() => setState(() {}));
  }

  Future<void> _fetchProducts() async {
    try {
      final products = await ProductService.getProducts();
      if (mounted) {
        setState(() {
          _products = products;
          _isLoadingProducts = false;
          if (isEditMode) {
            _selectedProduct = _products.firstWhere(
              (p) => p['id'] == widget.transaction!['productId'],
              orElse: () => _products.first,
            );
          } else if (widget.preselectedProduct != null) {
            _selectedProduct = _products.firstWhere(
              (p) => p['id'] == widget.preselectedProduct!['id'],
              orElse: () => _products.first,
            );
          }
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingProducts = false);
      print(e);
    }
  }

  Future<void> _saveTransaction() async {
    if (_selectedProduct == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a product')));
      return;
    }
    final quantityText = _quantityController.text.trim();
    if (quantityText.isEmpty ||
        double.tryParse(quantityText) == null ||
        double.parse(quantityText) <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid quantity')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final payload = {
        'productId': _selectedProduct!['id'],
        'transactionType': 1, // 1 = IN
        'quantity': double.parse(quantityText),
        'transactionDate': _selectedDate.toIso8601String(),
        'notes': _remarksController.text.trim(),
      };

      if (isEditMode) {
        await StockService.updateStockTransaction(
          widget.transaction!['id'],
          payload,
        );
      } else {
        await StockService.createStockTransaction(payload);
      }

      AppEvents.triggerRefresh();

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: Theme.of(context).colorScheme.primary,
              onPrimary: Colors.black,
              surface: Theme.of(context).primaryColor,
              onSurface: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          child: child!,
        );
      },
    );
    if (date != null && mounted) {
      setState(() => _selectedDate = date);
    }
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).primaryColor,
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(1.0, -1.0),
            radius: 1.5,
            colors: [
              Theme.of(context).colorScheme.surface.withOpacity(0.5),
              Theme.of(context).primaryColor,
              Colors.black,
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(),

              if (isEditMode)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.dark ? Theme.of(context).primaryColor.withValues(alpha: 0.5) : Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.primary
                            .withValues(alpha: 0.5),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Stock IN #ST-${widget.transaction!['id'].toString().padLeft(4, '0')}',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        _buildInBadge(),
                      ],
                    ),
                  ),
                ),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Form Section
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).brightness == Brightness.dark ? Theme.of(context).primaryColor.withValues(alpha: 0.5) : Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Theme.of(context).colorScheme.primary
                                .withValues(alpha: 0.3),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Stock Information',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurface,
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 16),

                            if (!isEditMode) ...[
                              Text(
                                'Transaction Type',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.outline,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 8),
                              _buildInBadge(),
                              const SizedBox(height: 24),
                            ],

                            Text(
                              'Product${isEditMode ? '' : ' *'}',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.primary.withValues(
                                  alpha: 0.8,
                                ),
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 8),
                            _isLoadingProducts
                                ? const Center(
                                    child: CircularProgressIndicator(),
                                  )
                                : isEditMode
                                ? _buildSelectedProductPreview(isLocked: true)
                                : _buildProductDropdown(),

                            const SizedBox(height: 16),

                            if (!isEditMode)
                              _selectedProduct == null
                                  ? _buildEmptyProductPreview()
                                  : _buildSelectedProductPreview(
                                      isLocked: false,
                                    ),

                            const SizedBox(height: 24),

                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Quantity *',
                                        style: TextStyle(
                                          color: Theme.of(context).colorScheme.primary.withValues(
                                            alpha: 0.8,
                                          ),
                                          fontSize: 13,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      _buildTextField(
                                        controller: _quantityController,
                                        keyboardType: TextInputType.number,
                                        suffixText: 'bags',
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Date *',
                                        style: TextStyle(
                                          color: Theme.of(context).colorScheme.primary.withValues(
                                            alpha: 0.8,
                                          ),
                                          fontSize: 13,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      GestureDetector(
                                        onTap: _pickDate,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 16,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.transparent,
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            border: Border.all(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .primary
                                                  .withValues(alpha: 0.5),
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                DateFormat('dd MMM yyyy')
                                                    .format(_selectedDate),
                                                style: TextStyle(
                                                  color: Theme.of(context).colorScheme.onSurface,
                                                  fontSize: 16,
                                                ),
                                              ),
                                              Icon(
                                                Icons.calendar_today,
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .primary,
                                                size: 20,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 24),
                            Text(
                              'Remarks',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.primary.withValues(
                                  alpha: 0.8,
                                ),
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 8),
                            _buildTextField(
                              controller: _remarksController,
                              hintText: isEditMode
                                  ? ''
                                  : 'Enter inward details',
                              maxLines: 3,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Preview Panel
                      _selectedProduct != null
                          ? _buildImpactPreview()
                          : const SizedBox.shrink(),

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),

              // Bottom Actions
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
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
                      flex: 2,
                      child: GestureDetector(
                        onTap: _isSaving ? null : _saveTransaction,
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
                          child: _isSaving
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.black,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.check_circle_outline, color: Theme.of(context).colorScheme.onPrimary,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      isEditMode ? 'Update Entry' : 'Add Stock',
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
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
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
                Text(
                  isEditMode ? 'Edit Stock Entry' : 'Stock Inward',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  isEditMode
                      ? 'Correct inward transaction'
                      : 'Add new stock to inventory',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          if (!isEditMode)
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.arrow_downward,
                color: Theme.of(context).colorScheme.primary,
                size: 20,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.transparent,
        border: Border.all(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.arrow_downward, color: Theme.of(context).colorScheme.primary, size: 16),
          SizedBox(width: 6),
          Text(
            'IN',
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<Map<String, dynamic>>(
          isExpanded: true,
          dropdownColor: Theme.of(context).colorScheme.surface,
          hint: Text(
            'Select rice product',
            style: TextStyle(color: Theme.of(context).colorScheme.outline),
          ),
          value: _selectedProduct,
          icon: Icon(
            Icons.keyboard_arrow_down,
            color: Theme.of(context).colorScheme.primary,
          ),
          items: _products.map((product) {
            return DropdownMenuItem<Map<String, dynamic>>(
              value: product,
              child: Text(
                '${product['name']} - ${product['brand']}',
                style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
              ),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedProduct = value;
            });
          },
        ),
      ),
    );
  }

  Widget _buildEmptyProductPreview() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
          style: BorderStyle.none,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: CustomPaint(
        painter: DashedRectPainter(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
        ),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Icon(
                Icons.inventory_2_outlined,
                color: Theme.of(context).colorScheme.outline,
                size: 40,
              ),
              const SizedBox(height: 12),
              Text(
                'No product selected',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.outline,
                  fontSize: 14,
                ),
              ),
              Text(
                'Select a rice product to see details',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.outline,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedProductPreview({required bool isLocked}) {
    if (_selectedProduct == null) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Image.asset(
              _selectedProduct!['image'] ??
                  'assets/images/products/vellore_gold_25kg.jpg',
              width: 50,
              height: 75,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _selectedProduct!['name'],
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_selectedProduct!['brand']} • ${_selectedProduct!['weight']}',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
                    fontSize: 13,
                  ),
                ),
                if (isLocked) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Product cannot be changed',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.outline,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (isLocked)
            Icon(
              Icons.lock_outline,
              color: Theme.of(context).colorScheme.outline,
              size: 24,
            ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    String? hintText,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    String? suffixText,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
        ),
      ),
      child: TextField(
        controller: controller,
        style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 16),
        keyboardType: keyboardType,
        maxLines: maxLines,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(color: Theme.of(context).colorScheme.outline),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
          suffixIcon: suffixText != null
              ? Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        suffixText,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.outline,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                )
              : null,
        ),
      ),
    );
  }

  Widget _buildImpactPreview() {
    double qty = double.tryParse(_quantityController.text) ?? 0;

    if (!isEditMode) {
      double current = (_selectedProduct!['currentStock'] as num).toDouble();
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark ? Theme.of(context).primaryColor.withValues(alpha: 0.5) : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Stock Preview',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                _buildInBadge(),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildImpactStat(
                  'Current Stock',
                  numFormat.format(current),
                  Theme.of(context).colorScheme.primary,
                ),
                Text(
                  '+',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.outline,
                    fontSize: 24,
                  ),
                ),
                _buildImpactStat(
                  'Adding',
                  '+${numFormat.format(qty)}',
                  Theme.of(context).colorScheme.primary,
                ),
                Text(
                  '=',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.outline,
                    fontSize: 24,
                  ),
                ),
                _buildImpactStat(
                  'New Stock',
                  numFormat.format(current + qty),
                  Theme.of(context).colorScheme.primary,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                'Stock will update after saving',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.outline,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      double originalQty = (widget.transaction!['quantity'] as num).toDouble();
      double diff = qty - originalQty;
      double current = (_selectedProduct!['currentStock'] as num).toDouble();
      double updated = current + diff;

      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark ? Theme.of(context).primaryColor.withValues(alpha: 0.5) : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Correction Impact',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildImpactStat(
                  'Original Quantity',
                  numFormat.format(originalQty),
                  Theme.of(context).colorScheme.primary,
                ),
                Icon(
                  Icons.arrow_forward,
                  color: Theme.of(context).colorScheme.outline,
                  size: 20,
                ),
                _buildImpactStat(
                  'Revised Quantity',
                  numFormat.format(qty),
                  Theme.of(context).colorScheme.primary,
                ),
                Text(
                  '=',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.outline,
                    fontSize: 24,
                  ),
                ),
                _buildImpactStat(
                  'Difference',
                  '${diff > 0 ? '+' : ''}${numFormat.format(diff)}',
                  Theme.of(context).colorScheme.primary,
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildImpactStat(
                  'Current Stock',
                  numFormat.format(current),
                  Theme.of(context).colorScheme.primary,
                ),
                Icon(
                  Icons.arrow_forward,
                  color: Theme.of(context).colorScheme.outline,
                  size: 20,
                ),
                _buildImpactStat(
                  'Updated Stock',
                  numFormat.format(updated),
                  Theme.of(context).colorScheme.primary,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              decoration: BoxDecoration(
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary
                      .withValues(alpha: 0.5),
                ),
                borderRadius: BorderRadius.circular(8),
                color: Theme.of(context).colorScheme.primary
                    .withValues(alpha: 0.05),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: Theme.of(context).colorScheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Updating this entry will recalculate product stock',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildImpactStat(String label, String value, Color valueColor) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              value,
              style: TextStyle(
                color: valueColor,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              'Bags',
              style: TextStyle(
                color: Theme.of(context).colorScheme.outline,
                fontSize: 12,
                height: 1.5,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class DashedRectPainter extends CustomPainter {
  final Color color;

  DashedRectPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    final path = Path();
    path.addRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        const Radius.circular(8),
      ),
    );

    // Simple dash effect
    const dashWidth = 5.0;
    const dashSpace = 5.0;
    double distance = 0.0;

    for (PathMetric pathMetric in path.computeMetrics()) {
      while (distance < pathMetric.length) {
        final extractPath = pathMetric.extractPath(
          distance,
          distance + dashWidth,
        );
        canvas.drawPath(extractPath, paint);
        distance += dashWidth + dashSpace;
      }
      distance = 0.0;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
