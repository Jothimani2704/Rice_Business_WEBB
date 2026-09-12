import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../services/payment_service.dart';
import '../../services/customer_service.dart';
import '../../models/customer.dart';
import '../../utils/app_events.dart';
import '../../utils/app_toast.dart';

class PaymentFormScreen extends StatefulWidget {
  final Customer? preSelectedCustomer;
  final Map<String, dynamic>? existingPayment;

  const PaymentFormScreen({
    super.key,
    this.preSelectedCustomer,
    this.existingPayment,
  });

  @override
  State<PaymentFormScreen> createState() => _PaymentFormScreenState();
}

class _PaymentFormScreenState extends State<PaymentFormScreen> {
  List<Customer> _customers = [];
  bool _isLoading = true;

  Customer? _selectedCustomer;

  final _amountController = TextEditingController();
  final _referenceController = TextEditingController();
  final _notesController = TextEditingController();

  String _paymentMode = 'UPI';
  DateTime _paymentDate = DateTime.now();
  double _originalAmount = 0.0;

  final numFormat = NumberFormat('#,##,###');

  bool get _isCorrectionMode => widget.existingPayment != null;

  @override
  void initState() {
    super.initState();
    if (_isCorrectionMode) {
      final p = widget.existingPayment!;
      _originalAmount = (p['amount'] as num?)?.toDouble() ?? 0.0;
      _amountController.text = _originalAmount > 0 ? _originalAmount.toStringAsFixed(0) : '';
      _paymentMode = p['paymentMode'] ?? 'UPI';
      _paymentDate = DateTime.tryParse(p['paymentDate']?.toString() ?? '') ?? DateTime.now();
      _referenceController.text = p['referenceNumber'] ?? '';
      _notesController.text = p['notes'] ?? '';

      final custId = p['customerId'] ?? 0;
      final custName = p['customerName'] ?? 'Customer';
      final custPhone = p['mobileNumber'] ?? p['phone'] ?? '';
      final prevBal = (p['previousBalance'] as num?)?.toDouble() ?? (p['currentBalance'] as num?)?.toDouble() ?? 0.0;

      _selectedCustomer = Customer(
        id: custId,
        name: custName,
        mobileNumber: custPhone,
        address: '',
        openingBalance: 0.0,
        currentBalance: prevBal,
        isActive: true,
        createdDate: DateTime.now(),
      );
    } else {
      _selectedCustomer = widget.preSelectedCustomer;
    }

    _fetchCustomers();
    _amountController.addListener(_onAmountChanged);
  }

  @override
  void dispose() {
    _amountController.dispose();
    _referenceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _onAmountChanged() {
    setState(() {}); // Trigger rebuild for calculation previews
  }

  Future<void> _fetchCustomers() async {
    try {
      final customers = await CustomerService.getCustomers();
      if (customers != null) {
        setState(() {
          _customers = customers
              .map((c) => Customer.fromJson(c))
              .where((c) => c.isActive)
              .toList();
          _isLoading = false;

          if (_selectedCustomer != null) {
            final loaded = _customers.firstWhere(
              (c) => c.id == _selectedCustomer!.id,
              orElse: () => _selectedCustomer!,
            );
            _selectedCustomer = loaded;
          }
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print('Error fetching customers: $e');
      setState(() => _isLoading = false);
    }
  }

  double get _currentAmount {
    final text = _amountController.text.replaceAll(',', '');
    return double.tryParse(text) ?? 0.0;
  }

  Future<void> _savePayment() async {
    if (_selectedCustomer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a customer')),
      );
      return;
    }
    if (_currentAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final data = {
        'customerId': _selectedCustomer!.id,
        'amount': _currentAmount,
        'paymentMode': _paymentMode,
        'paymentDate': _paymentDate.toIso8601String(),
        'referenceNumber': _referenceController.text.isNotEmpty
            ? _referenceController.text
            : null,
        'notes': _notesController.text.isNotEmpty
            ? _notesController.text
            : null,
      };

      if (_isCorrectionMode) {
        await PaymentService.updatePayment(widget.existingPayment!['id'], data);
      } else {
        await PaymentService.createPayment(data);
      }

      AppEvents.triggerRefresh();

      if (mounted) {
        AppToast.showSuccess(
          context,
          _isCorrectionMode
              ? 'Payment correction applied successfully!'
              : 'Payment recorded successfully!',
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      print('Error saving payment: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save payment: $e')),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  String _getInitials(String name) {
    if (name.isEmpty) return '??';
    List<String> words = name.trim().split(' ');
    if (words.length > 1 && words[1].isNotEmpty) {
      return '${words[0][0]}${words[1][0]}'.toUpperCase();
    }
    return name.substring(0, name.length > 1 ? 2 : 1).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Background Gradient
          Container(
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
          ),

          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: _isLoading && _customers.isEmpty
                      ? Center(
                          child: CircularProgressIndicator(
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        )
                      : SingleChildScrollView(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _buildCustomerSection(),
                              const SizedBox(height: 16),
                              _buildPaymentInfoSection(),
                              const SizedBox(height: 16),
                              if (_isCorrectionMode)
                                _buildCorrectionImpactSection()
                              else
                                _buildBalancePreviewSection(),
                              if (_isCorrectionMode) ...[
                                const SizedBox(height: 16),
                                _buildWarningAlertBox(),
                              ],
                              const SizedBox(height: 24),
                              _buildActionButtons(),
                              const SizedBox(height: 32),
                            ],
                          ),
                        ),
                ),
              ],
            ),
          ),

          if (_isLoading && _customers.isNotEmpty)
            Container(
              color: Colors.black54,
              child: Center(
                child: CircularProgressIndicator(
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              if (Navigator.canPop(context)) Navigator.pop(context);
            },
            child: Icon(
              Icons.arrow_back,
              color: Theme.of(context).colorScheme.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isCorrectionMode ? 'Correct Payment' : 'Receive Payment',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                if (_isCorrectionMode)
                  Row(
                    children: [
                      Text(
                        'Payment #${widget.existingPayment!['id']}',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.outline,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.orange, width: 1.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'CORRECTION',
                          style: TextStyle(
                            color: Colors.orange,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  )
                else
                  Text(
                    'Record customer collection',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.outline,
                      fontSize: 14,
                    ),
                  ),
              ],
            ),
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
          'Customer',
          style: TextStyle(
            color: Theme.of(context).colorScheme.outline,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        if (_isCorrectionMode || _selectedCustomer != null)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Theme.of(context).primaryColor.withValues(alpha: 0.5)
                  : Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.4),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Theme.of(context).colorScheme.primary,
                      width: 1.5,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    _getInitials(_selectedCustomer?.name ?? 'CS'),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _selectedCustomer?.name ?? 'Customer',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _selectedCustomer?.mobileNumber != null &&
                                _selectedCustomer!.mobileNumber!.isNotEmpty
                            ? '+91 ${_selectedCustomer!.mobileNumber}'
                            : 'No Phone Provided',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.outline,
                          fontSize: 13,
                        ),
                      ),
                      if (_isCorrectionMode) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(
                              Icons.lock_outline,
                              color: Theme.of(context).colorScheme.outline,
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Customer cannot be changed',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.outline,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
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
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '₹${numFormat.format(_selectedCustomer?.currentBalance ?? 0)}',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          )
        else
          LayoutBuilder(
            builder: (context, constraints) {
              return DropdownMenu<Customer>(
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
                  backgroundColor: WidgetStatePropertyAll(
                    Theme.of(context).brightness == Brightness.dark
                        ? Theme.of(context).primaryColor
                        : Theme.of(context).colorScheme.surface,
                  ),
                  elevation: const WidgetStatePropertyAll(8.0),
                ),
                menuHeight: 260,
                enableFilter: true,
                enableSearch: true,
                trailingIcon: Icon(Icons.keyboard_arrow_down, color: Theme.of(context).colorScheme.primary),
                leadingIcon: Icon(Icons.search, color: Theme.of(context).colorScheme.outline, size: 20),
                initialSelection: _selectedCustomer,
                onSelected: (Customer? selected) {
                  setState(() => _selectedCustomer = selected);
                  FocusScope.of(context).unfocus();
                },
                dropdownMenuEntries: _customers.map((c) {
                  final String name = c.name;
                  final String phone = c.mobileNumber ?? '';
                  final String label = phone.isNotEmpty ? '$name ($phone)' : name;
                  return DropdownMenuEntry<Customer>(
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

  Widget _buildPaymentInfoSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? Theme.of(context).primaryColor.withValues(alpha: 0.5)
            : Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Payment Information',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          if (_isCorrectionMode)
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Original Amount',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.outline,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        height: 48,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.black26
                              : Colors.grey.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Text(
                              '₹${numFormat.format(_originalAmount)}',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.outline,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Spacer(),
                            Icon(
                              Icons.lock_outline,
                              color: Theme.of(context).colorScheme.outline,
                              size: 18,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Revised Amount *',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        height: 48,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.green,
                            width: 1.5,
                          ),
                        ),
                        alignment: Alignment.centerLeft,
                        child: TextField(
                          controller: _amountController,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(
                            color: Colors.green,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                          decoration: const InputDecoration(
                            prefixText: '₹',
                            prefixStyle: TextStyle(
                              color: Colors.green,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            )
          else ...[
            Text(
              'Amount Received *',
              style: TextStyle(
                color: Theme.of(context).colorScheme.outline,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
                ),
              ),
              alignment: Alignment.centerLeft,
              child: TextField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
                decoration: const InputDecoration(
                  prefixText: '₹',
                  prefixStyle: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                  border: InputBorder.none,
                ),
              ),
            ),
          ],

          const SizedBox(height: 20),

          // Payment Mode Selector
          Text(
            'Payment Mode *',
            style: TextStyle(
              color: Theme.of(context).colorScheme.outline,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildModeButton('Cash', Icons.account_balance_wallet_outlined),
                const SizedBox(width: 8),
                _buildModeButton('UPI', Icons.send_outlined),
                const SizedBox(width: 8),
                _buildModeButton('Bank Transfer', Icons.account_balance_outlined),
                const SizedBox(width: 8),
                _buildModeButton('Cheque', Icons.assignment_outlined),
                const SizedBox(width: 8),
                _buildModeButton('Other', Icons.more_horiz_outlined),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Payment Date
          Text(
            'Payment Date *',
            style: TextStyle(
              color: Theme.of(context).colorScheme.outline,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 6),
          GestureDetector(
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: _paymentDate,
                firstDate: DateTime(2000),
                lastDate: DateTime.now(),
              );
              if (date != null) {
                setState(() => _paymentDate = date);
              }
            },
            child: Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    color: Theme.of(context).colorScheme.outline,
                    size: 18,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    DateFormat('dd MMM yyyy').format(_paymentDate),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 15,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.keyboard_arrow_down,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Reference Number
          Text(
            'Reference Number',
            style: TextStyle(
              color: Theme.of(context).colorScheme.outline,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 6),
          _buildTextField(_referenceController, 'e.g. UPI829104'),

          const SizedBox(height: 20),

          // Notes
          Text(
            'Notes',
            style: TextStyle(
              color: Theme.of(context).colorScheme.outline,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 6),
          _buildTextField(_notesController, 'e.g. Amount entered incorrectly', maxLines: 2),
        ],
      ),
    );
  }

  Widget _buildModeButton(String mode, IconData icon) {
    final isSelected = _paymentMode == mode;
    return GestureDetector(
      onTap: () => setState(() => _paymentMode = mode),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.outline,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              mode,
              style: TextStyle(
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurface,
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            if (isSelected) ...[
              const SizedBox(width: 6),
              Icon(
                Icons.check_circle,
                color: Theme.of(context).colorScheme.primary,
                size: 14,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String hint, {
    int maxLines = 1,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
        ),
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurface,
          fontSize: 14,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Theme.of(context).colorScheme.outline),
          border: InputBorder.none,
          isDense: true,
        ),
      ),
    );
  }

  Widget _buildCorrectionImpactSection() {
    final revisedAmount = _currentAmount;
    final diff = revisedAmount - _originalAmount;
    final curBal = _selectedCustomer?.currentBalance ?? 0.0;
    final adjustment = _originalAmount - revisedAmount;
    final updatedBal = curBal + adjustment;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? Theme.of(context).primaryColor.withValues(alpha: 0.5)
            : Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.4),
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
          const SizedBox(height: 16),

          // Top Row: Original | Revised | Difference
          Row(
            children: [
              Expanded(
                child: _buildImpactCell(
                  'Original Payment',
                  '₹${numFormat.format(_originalAmount)}',
                  Theme.of(context).colorScheme.onSurface,
                ),
              ),
              Expanded(
                child: _buildImpactCell(
                  'Revised Payment',
                  '₹${numFormat.format(revisedAmount)}',
                  Colors.green,
                ),
              ),
              Expanded(
                child: _buildImpactCell(
                  'Difference',
                  '${diff < 0 ? "— " : "+ "}₹${numFormat.format(diff.abs())}',
                  diff < 0 ? Colors.redAccent : Colors.green,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),
          Divider(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2)),
          const SizedBox(height: 16),

          // Middle Row: Current Balance | Adjustment | Updated Balance
          Row(
            children: [
              Expanded(
                child: _buildImpactCell(
                  'Current Customer Balance',
                  '₹${numFormat.format(curBal)}',
                  Theme.of(context).colorScheme.onSurface,
                ),
              ),
              Expanded(
                child: _buildImpactCell(
                  'Balance Adjustment',
                  '${adjustment >= 0 ? "+ " : "— "}₹${numFormat.format(adjustment.abs())}',
                  Colors.green,
                ),
              ),
              Expanded(
                child: _buildImpactCell(
                  'Updated Customer Balance',
                  '₹${numFormat.format(updatedBal)}',
                  Colors.green,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),
          Divider(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2)),
          const SizedBox(height: 12),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Ledger Entry',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.outline,
                  fontSize: 13,
                ),
              ),
              const Text(
                'Recalculated',
                style: TextStyle(
                  color: Colors.green,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildImpactCell(String label, String value, Color valueColor) {
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
        const SizedBox(height: 6),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: TextStyle(
              color: valueColor,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBalancePreviewSection() {
    if (_selectedCustomer == null) return const SizedBox();

    final currentBal = _selectedCustomer!.currentBalance;
    final payment = _currentAmount;
    final newBal = currentBal - payment;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? Theme.of(context).primaryColor.withValues(alpha: 0.5)
            : Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Balance Preview',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Current', style: TextStyle(color: Theme.of(context).colorScheme.outline, fontSize: 12)),
                  const SizedBox(height: 4),
                  Text(
                    '₹${numFormat.format(currentBal)}',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Text('-', style: TextStyle(color: Theme.of(context).colorScheme.outline, fontSize: 24)),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Payment', style: TextStyle(color: Theme.of(context).colorScheme.outline, fontSize: 12)),
                  const SizedBox(height: 4),
                  Text(
                    '— ₹${numFormat.format(payment)}',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Text('=', style: TextStyle(color: Theme.of(context).colorScheme.outline, fontSize: 24)),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('New Bal', style: TextStyle(color: Theme.of(context).colorScheme.outline, fontSize: 12)),
                  const SizedBox(height: 4),
                  Text(
                    '₹${numFormat.format(newBal)}',
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
        ],
      ),
    );
  }

  Widget _buildWarningAlertBox() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Colors.orange.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.orange, width: 1.5),
            ),
            child: const Icon(
              Icons.priority_high,
              color: Colors.orange,
              size: 14,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Payment, customer balance and ledger will update together',
              style: TextStyle(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.orangeAccent
                    : Colors.orange.shade900,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
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
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: GestureDetector(
            onTap: _isLoading ? null : _savePayment,
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
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.black,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      _isCorrectionMode ? 'Apply Correction' : 'Save Payment',
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ),
      ],
    );
  }
}
