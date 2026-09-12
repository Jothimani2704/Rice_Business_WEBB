import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../services/customer_service.dart';
import '../../models/customer.dart';
import '../../widgets/skeleton_loader.dart';
import '../payment/payment_form_screen.dart';
import '../sales/sale_form_screen.dart';
import 'customer_form_screen.dart';

class CustomerDetailsScreen extends StatefulWidget {
  final dynamic customer;

  const CustomerDetailsScreen({super.key, required this.customer});

  @override
  State<CustomerDetailsScreen> createState() => _CustomerDetailsScreenState();
}

class _CustomerDetailsScreenState extends State<CustomerDetailsScreen> {
  final numFormat = NumberFormat('#,##,###');

  bool _isLoading = true;
  List<dynamic> _transactions = [];
  Map<String, dynamic> _accountSummary = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    final customerId = widget.customer['id'];
    final results = await Future.wait([
      CustomerService.getCustomerTransactions(customerId),
      CustomerService.getCustomerAccountSummary(customerId),
    ]);

    if (mounted) {
      setState(() {
        _transactions = (results[0] as List<dynamic>?) ?? [];
        _accountSummary = (results[1] as Map<String, dynamic>?) ?? {};
        _isLoading = false;
      });
    }
  }

  dynamic _getVal(dynamic data, List<String> keys) {
    if (data is! Map) return null;
    for (var key in keys) {
      final keyLower = key.toLowerCase();
      for (var entry in data.entries) {
        if (entry.key.toString().toLowerCase() == keyLower) {
          if (entry.value != null) return entry.value;
        }
      }
    }
    return null;
  }

  double _getnum(dynamic data, List<String> keys) {
    final val = _getVal(data, keys);
    if (val == null) return 0.0;
    if (val is num) return val.toDouble();
    return double.tryParse(val.toString()) ?? 0.0;
  }

  @override
  Widget build(BuildContext context) {
    String name = widget.customer['name'] ?? 'Unknown';
    String initials = name.isNotEmpty
        ? name
              .split(' ')
              .map((e) => e.isNotEmpty ? e[0] : '')
              .take(2)
              .join('')
              .toUpperCase()
        : 'U';
    String phone = widget.customer['mobileNumber'] ?? widget.customer['phone'] ?? 'No Phone';
    bool isActive = widget.customer['isActive'] ?? true;

    final double outstanding = _getnum(_accountSummary, ['currentOutstandingBalance', 'currentBalance', 'outstandingBalance']);
    final double totalSales = _getnum(_accountSummary, ['totalSales', 'totalSalesAmount']);
    final double totalPaid = _getnum(_accountSummary, ['totalPayments', 'totalPaidAmount', 'totalPaid']);
    final int transactionsCount = _transactions.length;

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
                  children: [
                    GestureDetector(
                      onTap: () {
                        if (Navigator.canPop(context)) Navigator.pop(context);
                      },
                      child: Icon(
                        Icons.arrow_back,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        'Customer Details',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                CustomerFormScreen(customer: widget.customer),
                          ),
                        );
                        if (result == true) {
                          Navigator.pop(context, true);
                        }
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Icon(
                          Icons.edit_outlined,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Icon(
                      Icons.more_vert,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ],
                ),
              ),

              Expanded(
                child: _isLoading
                    ? ListSkeleton(title: 'Customer Details')
                    : SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Customer Card
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Theme.of(context).brightness == Brightness.dark
                                    ? Theme.of(context).primaryColor.withValues(alpha: 0.5)
                                    : Theme.of(context).colorScheme.surface,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 60,
                                    height: 60,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Theme.of(context).colorScheme.primary,
                                        width: 1.5,
                                      ),
                                    ),
                                    child: Center(
                                      child: Text(
                                        initials,
                                        style: TextStyle(
                                          color: Theme.of(context).colorScheme.primary,
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
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
                                          name,
                                          style: TextStyle(
                                            color: Theme.of(context).colorScheme.onSurface,
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          phone,
                                          style: TextStyle(
                                            color: Theme.of(context).colorScheme.outline,
                                            fontSize: 14,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.location_on_outlined,
                                              color: Theme.of(context).colorScheme.outline,
                                              size: 14,
                                            ),
                                            const SizedBox(width: 4),
                                            Expanded(
                                              child: Text(
                                                widget.customer['address'] ?? 'No Address Provided',
                                                style: TextStyle(
                                                  color: Theme.of(context).colorScheme.outline,
                                                  fontSize: 12,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
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
                                              isActive ? 'Active' : 'Inactive',
                                              style: TextStyle(
                                                color: isActive
                                                    ? Theme.of(context).colorScheme.primary
                                                    : Colors.redAccent,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  GestureDetector(
                                    behavior: HitTestBehavior.opaque,
                                    onTap: () async {
                                      final rawPhone = widget.customer['mobileNumber'] ??
                                          widget.customer['phone'] ??
                                          widget.customer['phoneNumber'];
                                      final cleanPhone = rawPhone
                                              ?.toString()
                                              .replaceAll(RegExp(r'[^\d+]'), '') ??
                                          '';

                                      if (cleanPhone.isEmpty || rawPhone == null || rawPhone.toString().isEmpty || rawPhone == 'No Phone') {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('Phone number not available for this customer'),
                                            backgroundColor: Colors.orange,
                                            behavior: SnackBarBehavior.floating,
                                          ),
                                        );
                                      } else {
                                        final Uri callUri = Uri.parse('tel:$cleanPhone');
                                        try {
                                          if (await canLaunchUrl(callUri)) {
                                            await launchUrl(callUri);
                                          } else {
                                            await launchUrl(callUri, mode: LaunchMode.externalApplication);
                                          }
                                        } catch (e) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text('Calling $cleanPhone...'),
                                              behavior: SnackBarBehavior.floating,
                                            ),
                                          );
                                        }
                                      }
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05),
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                                        ),
                                      ),
                                      child: Icon(
                                        Icons.phone_outlined,
                                        color: Theme.of(context).colorScheme.primary,
                                        size: 24,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Outstanding Balance
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 24),
                              decoration: BoxDecoration(
                                color: Theme.of(context).brightness == Brightness.dark
                                    ? Theme.of(context).primaryColor.withValues(alpha: 0.5)
                                    : Theme.of(context).colorScheme.surface,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1),
                                ),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    'Outstanding Balance',
                                    style: TextStyle(
                                      color: Theme.of(context).colorScheme.onSurface,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '₹${numFormat.format(outstanding)}',
                                    style: TextStyle(
                                      color: outstanding > 0
                                          ? Colors.redAccent
                                          : Theme.of(context).colorScheme.primary,
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Stats Row
                            Row(
                              children: [
                                Expanded(
                                  child: _buildStatCard(
                                    'Total Sales',
                                    '₹${numFormat.format(totalSales)}',
                                    Icons.shopping_bag_outlined,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildStatCard(
                                    'Total Paid',
                                    '₹${numFormat.format(totalPaid)}',
                                    Icons.currency_rupee,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildStatCard(
                                    'Transactions',
                                    '$transactionsCount',
                                    Icons.receipt_long_outlined,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),

                            // Quick Actions
                            Text(
                              'Quick Actions',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurface,
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _buildActionBtn(
                                  'New Sale',
                                  Icons.shopping_cart_checkout,
                                  () async {
                                    final customerId = widget.customer['id'];
                                    final customerName = widget.customer['name'];
                                    await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => const SaleFormScreen(),
                                      ),
                                    );
                                    _loadData();
                                  },
                                ),
                                _buildActionBtn(
                                  'Receive\nPayment',
                                  Icons.currency_exchange,
                                  () async {
                                    final c = widget.customer;
                                    final preSelected = Customer(
                                      id: c['id'],
                                      name: c['name'] ?? '',
                                      mobileNumber: c['mobileNumber'] ?? c['phone'] ?? '',
                                      address: c['address'] ?? '',
                                      isActive: c['isActive'] ?? true,
                                      currentBalance: (c['currentBalance'] ?? c['outstandingBalance'] ?? 0).toDouble(),
                                      openingBalance: (c['openingBalance'] ?? 0).toDouble(),
                                      createdDate: DateTime.tryParse(c['createdDate']?.toString() ?? '') ?? DateTime.now(),
                                      updatedDate: DateTime.tryParse(c['updatedDate']?.toString() ?? ''),
                                    );
                                    await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => PaymentFormScreen(
                                          preSelectedCustomer: preSelected,
                                        ),
                                      ),
                                    );
                                    _loadData();
                                  },
                                ),
                                _buildActionBtn(
                                  'View Ledger',
                                  Icons.menu_book,
                                  () {
                                    _loadData();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Ledger refreshed. View recent transactions below.'),
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  },
                                ),
                                _buildActionBtn(
                                  'Edit\nCustomer',
                                  Icons.edit,
                                  () async {
                                    final result = await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => CustomerFormScreen(
                                          customer: widget.customer,
                                        ),
                                      ),
                                    );
                                    if (result == true) {
                                      Navigator.pop(context, true);
                                    }
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),

                            // Recent Transactions
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Recent Transactions',
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.onSurface,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Row(
                                  children: [
                                    Text(
                                      'View All',
                                      style: TextStyle(
                                        color: Theme.of(context).colorScheme.primary,
                                        fontSize: 14,
                                      ),
                                    ),
                                    Icon(
                                      Icons.chevron_right,
                                      color: Theme.of(context).colorScheme.primary,
                                      size: 18,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            if (_transactions.isEmpty)
                              Center(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 32),
                                  child: Text(
                                    'No transactions yet',
                                    style: TextStyle(
                                      color: Theme.of(context).colorScheme.outline,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              )
                            else
                              ..._transactions.take(10).map((tx) {
                                final typeStr = (_getVal(tx, ['transactionType', 'type', 'referenceType']) ?? '').toString();
                                final isSale = typeStr.toLowerCase().contains('sale');

                                final double debit = _getnum(tx, ['debit', 'debitAmount']);
                                final double credit = _getnum(tx, ['credit', 'creditAmount', 'paidAmount']);
                                final double rawAmt = _getnum(tx, ['amount', 'totalAmount']);

                                double amount = 0.0;
                                if (debit > 0) {
                                  amount = debit;
                                } else if (credit > 0) {
                                  amount = credit;
                                } else if (rawAmt > 0) {
                                  amount = rawAmt;
                                }

                                final String description = (_getVal(tx, ['description', 'notes', 'referenceNo']) ?? '').toString();

                                if (amount == 0.0 && description.isNotEmpty) {
                                  final totalMatch = RegExp(r'Total:\s*([\d.]+)', caseSensitive: false).firstMatch(description);
                                  final paidMatch = RegExp(r'Paid:\s*([\d.]+)', caseSensitive: false).firstMatch(description);
                                  if (totalMatch != null) {
                                    final tot = double.tryParse(totalMatch.group(1) ?? '') ?? 0.0;
                                    final pd = double.tryParse(paidMatch?.group(1) ?? '') ?? 0.0;
                                    if (tot > 0) {
                                      amount = isSale ? (tot - pd > 0 ? tot - pd : tot) : pd;
                                    }
                                  }
                                }

                                final double balance = _getnum(tx, ['runningBalance', 'balance', 'newBalance']);

                                final dateStr = (_getVal(tx, ['transactionDate', 'createdDate', 'date']) ?? '').toString();
                                final date = DateTime.tryParse(dateStr);
                                final formattedDate = date != null ? DateFormat('dd MMM yyyy').format(date) : dateStr;

                                String displayDesc = description;
                                if (displayDesc.trim().isEmpty) {
                                  final refId = _getVal(tx, ['referenceId', 'id']);
                                  displayDesc = isSale ? 'Sale #$refId' : 'Payment #$refId';
                                }

                                return Container(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  decoration: BoxDecoration(
                                    border: Border(
                                      bottom: BorderSide(
                                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1),
                                      ),
                                    ),
                                  ),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
                                          ),
                                        ),
                                        child: Icon(
                                          isSale ? Icons.trending_up : Icons.trending_down,
                                          color: isSale
                                              ? Colors.redAccent
                                              : Theme.of(context).colorScheme.primary,
                                          size: 20,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              typeStr.isNotEmpty ? typeStr : (isSale ? 'Sale' : 'Payment'),
                                              style: TextStyle(
                                                color: isSale
                                                    ? Colors.redAccent
                                                    : Theme.of(context).colorScheme.primary,
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              displayDesc,
                                              style: TextStyle(
                                                color: Theme.of(context).colorScheme.outline,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Text(
                                        formattedDate,
                                        style: TextStyle(
                                          color: Theme.of(context).colorScheme.outline,
                                          fontSize: 12,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            '${isSale ? '+' : '-'} ₹${numFormat.format(amount)}',
                                            style: TextStyle(
                                              color: isSale
                                                  ? Colors.redAccent
                                                  : Theme.of(context).colorScheme.primary,
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Balance ₹${numFormat.format(balance)}',
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
                              }),
                            const SizedBox(height: 24),
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

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? Theme.of(context).primaryColor.withValues(alpha: 0.5)
            : Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: Theme.of(context).colorScheme.primary,
              size: 20,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              color: Theme.of(context).colorScheme.outline,
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionBtn(String title, IconData icon, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? Theme.of(context).primaryColor.withValues(alpha: 0.5)
                : Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1)),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: Theme.of(context).colorScheme.primary,
                size: 24,
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.outline,
                  fontSize: 11,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
