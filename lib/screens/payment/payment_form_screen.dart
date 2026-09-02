import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../services/payment_service.dart';
import '../../services/customer_service.dart';
import '../../models/customer.dart';
import '../../utils/app_events.dart';

class PaymentFormScreen extends StatefulWidget {
  final Customer? preSelectedCustomer;

  const PaymentFormScreen({super.key, this.preSelectedCustomer});

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

  final numFormat = NumberFormat('#,##,###');

  @override
  void initState() {
    super.initState();
    _selectedCustomer = widget.preSelectedCustomer;
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
    setState(() {}); // Trigger rebuild for balance preview
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

          // If a customer was pre-selected but not loaded fully, update it
          if (_selectedCustomer != null) {
            _selectedCustomer = _customers.firstWhere(
              (c) => c.id == _selectedCustomer!.id,
              orElse: () => _selectedCustomer!,
            );
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a customer')));
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

      await PaymentService.createPayment(data);
      AppEvents.triggerRefresh(); // Trigger global data refresh

      if (mounted) {
        Navigator.pop(context, true); // Return true to indicate success
      }
    } catch (e) {
      print('Error saving payment: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to save payment: $e')));
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).primaryColor,
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
                              _buildBalancePreviewSection(),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Receive Payment',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Record customer collection',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.outline,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Customer search removed in favor of DropdownMenu

  // To be implemented:
  Widget _buildCustomerSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Customer', style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
        const SizedBox(height: 8),
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
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
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
        if (_selectedCustomer != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark ? Theme.of(context).primaryColor.withValues(alpha: 0.5) : Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Theme.of(context).colorScheme.primary
                    .withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    _selectedCustomer!.name.substring(0, 2).toUpperCase(),
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
                        _selectedCustomer!.name,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '+91 ${_selectedCustomer!.mobileNumber ?? "N/A"}',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.outline,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.green.withValues(alpha: 0.5),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.circle, color: Colors.green, size: 8),
                            const SizedBox(width: 4),
                            Text(
                              'Active',
                              style: TextStyle(
                                color: Colors.green,
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
                    Text('Outstanding Balance', style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
                    const SizedBox(height: 4),
                    Text(
                      '₹${numFormat.format(_selectedCustomer!.currentBalance)}',
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
          ),
        ],
      ],
    );
  }

  Widget _buildPaymentInfoSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark ? Theme.of(context).primaryColor.withValues(alpha: 0.5) : Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
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
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 24),

          // Amount
          Text('Amount Received', style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Theme.of(context).colorScheme.primary
                    .withValues(alpha: 0.5),
              ),
            ),
            child: TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              decoration: InputDecoration(border: InputBorder.none),
            ),
          ),
          if (_selectedCustomer != null) ...[
            const SizedBox(height: 4),
            Text(
              'Maximum ₹${numFormat.format(_selectedCustomer!.currentBalance)}',
              style: TextStyle(
                color: Theme.of(context).colorScheme.outline,
                fontSize: 11,
              ),
            ),
          ],

          const SizedBox(height: 20),

          // Payment Mode
          Text('Payment Mode', style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildModeButton('Cash', Icons.money),
                const SizedBox(width: 8),
                _buildModeButton('UPI', Icons.send),
                const SizedBox(width: 8),
                _buildModeButton('Bank Transfer', Icons.account_balance),
                const SizedBox(width: 8),
                _buildModeButton('Cheque', Icons.article),
                const SizedBox(width: 8),
                _buildModeButton('Other', Icons.more_horiz),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Payment Date
          Text('Payment Date', style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: _paymentDate,
                firstDate: DateTime(2000),
                lastDate: DateTime.now(),
                builder: (context, child) {
                  return Theme(
                    data: ThemeData.dark().copyWith(
                      colorScheme: ColorScheme.light(
                        primary: Theme.of(context).colorScheme.primary,
                        onPrimary: Theme.of(context).colorScheme.onSurface,
                        surface: Theme.of(context).primaryColor,
                        onSurface: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    child: child!,
                  );
                },
              );
              if (date != null) {
                setState(() => _paymentDate = date);
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary
                      .withValues(alpha: 0.5),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    color: Theme.of(context).colorScheme.outline,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    DateFormat('dd MMM yyyy').format(_paymentDate),
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 15),
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
          Text('Reference Number (Optional)', style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
          const SizedBox(height: 8),
          _buildTextField(_referenceController, 'UPI829104'),

          const SizedBox(height: 20),

          // Notes
          Text('Additional Notes', style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
          const SizedBox(height: 8),
          _buildTextField(
            _notesController,
            'August balance payment',
            maxLines: 3,
          ),
        ],
      ),
    );
  }

  Widget _buildModeButton(String mode, IconData icon) {
    final isSelected = _paymentMode == mode;
    return GestureDetector(
      onTap: () => setState(() => _paymentMode = mode),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.blue.withValues(alpha: 0.1)
              : Theme.of(context).primaryColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? Colors.blue
                : Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected
                  ? Colors.blue
                  : Theme.of(context).colorScheme.primary,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              mode,
              style: TextStyle(
                color: isSelected ? Colors.blue : Theme.of(context).colorScheme.onSurface,
                fontSize: 12,
              ),
            ),
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
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
        ),
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 15),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Theme.of(context).colorScheme.outline),
          border: InputBorder.none,
        ),
      ),
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
        color: Theme.of(context).brightness == Brightness.dark ? Theme.of(context).primaryColor.withValues(alpha: 0.5) : Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Balance Preview',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text('Current', style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 12)),
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
              Text('-', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54), fontSize: 24)),
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text('Payment', style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 12)),
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
              Text('=', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54), fontSize: 24)),
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text('New Bal', style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 12)),
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
          const SizedBox(height: 16),
          Divider(
            color: Theme.of(context).colorScheme.primary,
            height: 1,
            thickness: 0.2,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
                  ),
                ),
                child: Text(
                  'PAYMENT • CREDIT',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(child: Text('This payment will be credited to the customer account.', style: TextStyle(color: Theme.of(context).colorScheme.outline, fontSize: 12))),
            ],
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
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              alignment: Alignment.center,
              child: Text('Cancel', style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 16)),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: GestureDetector(
            onTap: _isLoading ? null : _savePayment,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.primary,
                    Theme.of(context).colorScheme.secondary,
                  ],
                ),

                borderRadius: BorderRadius.circular(8),
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
                      'Save Payment',
                      style: TextStyle(
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
