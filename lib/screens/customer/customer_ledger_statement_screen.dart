import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../services/customer_service.dart';
import '../../utils/app_toast.dart';
import '../../widgets/skeleton_loader.dart';

class CustomerLedgerStatementScreen extends StatefulWidget {
  final dynamic customer;

  const CustomerLedgerStatementScreen({super.key, required this.customer});

  @override
  State<CustomerLedgerStatementScreen> createState() => _CustomerLedgerStatementScreenState();
}

class _CustomerLedgerStatementScreenState extends State<CustomerLedgerStatementScreen> {
  final numFormat = NumberFormat('#,##,###');
  final dateFormat = DateFormat('dd/MM/yyyy');
  final timeFormat = DateFormat('dd/MM/yyyy hh:mm a');

  bool _isLoading = true;
  List<dynamic> _allTransactions = [];
  Map<String, dynamic> _accountSummary = {};

  String _selectedFilter = 'all'; // 'all', 'this_month', 'last_30_days', 'custom'
  DateTime? _customStartDate;
  DateTime? _customEndDate;

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
        _allTransactions = (results[0] as List<dynamic>?) ?? [];
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

  DateTime? _parseDate(dynamic val) {
    if (val == null) return null;
    if (val is DateTime) return val;
    return DateTime.tryParse(val.toString());
  }

  List<dynamic> get _filteredTransactions {
    if (_selectedFilter == 'all') {
      return _allTransactions;
    }

    final now = DateTime.now();
    DateTime startDate;
    DateTime endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);

    if (_selectedFilter == 'this_month') {
      startDate = DateTime(now.year, now.month, 1);
    } else if (_selectedFilter == 'last_30_days') {
      startDate = now.subtract(const Duration(days: 30));
    } else if (_selectedFilter == 'custom' && _customStartDate != null) {
      startDate = DateTime(_customStartDate!.year, _customStartDate!.month, _customStartDate!.day);
      if (_customEndDate != null) {
        endDate = DateTime(_customEndDate!.year, _customEndDate!.month, _customEndDate!.day, 23, 59, 59);
      }
    } else {
      return _allTransactions;
    }

    return _allTransactions.where((tx) {
      final txDate = _parseDate(_getVal(tx, ['transactionDate', 'createdDate', 'date']));
      if (txDate == null) return true;
      return txDate.isAfter(startDate.subtract(const Duration(seconds: 1))) &&
          txDate.isBefore(endDate.add(const Duration(seconds: 1)));
    }).toList();
  }

  double get _openingBalance {
    final double initialOpening = _getnum(widget.customer, ['openingBalance']);
    if (_selectedFilter == 'all') return initialOpening;

    final filtered = _filteredTransactions;
    if (filtered.isEmpty || _allTransactions.isEmpty) return initialOpening;

    final firstFilteredDate = _parseDate(_getVal(filtered.last, ['transactionDate', 'createdDate', 'date']));
    if (firstFilteredDate == null) return initialOpening;

    double runningOp = initialOpening;
    for (var tx in _allTransactions.reversed) {
      final d = _parseDate(_getVal(tx, ['transactionDate', 'createdDate', 'date']));
      if (d != null && d.isBefore(firstFilteredDate)) {
        final double debit = _getnum(tx, ['debit']);
        final double credit = _getnum(tx, ['credit']);
        runningOp += (debit - credit);
      }
    }
    return runningOp;
  }

  double get _periodDebit {
    double total = 0.0;
    for (var tx in _filteredTransactions) {
      total += _getnum(tx, ['debit']);
    }
    return total;
  }

  double get _periodCredit {
    double total = 0.0;
    for (var tx in _filteredTransactions) {
      total += _getnum(tx, ['credit']);
    }
    return total;
  }

  double get _periodClosingBalance {
    return _openingBalance + _periodDebit - _periodCredit;
  }

  Future<void> _pickCustomDateRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(now.year + 5),
      initialDateRange: _customStartDate != null && _customEndDate != null
          ? DateTimeRange(start: _customStartDate!, end: _customEndDate!)
          : DateTimeRange(start: now.subtract(const Duration(days: 30)), end: now),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: Theme.of(context).colorScheme.primary,
                ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _customStartDate = picked.start;
        _customEndDate = picked.end;
        _selectedFilter = 'custom';
      });
    }
  }

  Future<void> _shareOnWhatsApp() async {
    final rawPhone = widget.customer['mobileNumber'] ?? widget.customer['phone'] ?? '';
    final cleanPhone = rawPhone.toString().replaceAll(RegExp(r'[^\d+]'), '');

    final customerName = widget.customer['name'] ?? 'Customer';
    final closingBal = _periodClosingBalance;

    String dateRangeStr = 'All Time';
    if (_selectedFilter == 'this_month') {
      dateRangeStr = 'This Month (${DateFormat('MMM yyyy').format(DateTime.now())})';
    } else if (_selectedFilter == 'last_30_days') {
      dateRangeStr = 'Last 30 Days';
    } else if (_selectedFilter == 'custom' && _customStartDate != null && _customEndDate != null) {
      dateRangeStr = '${dateFormat.format(_customStartDate!)} to ${dateFormat.format(_customEndDate!)}';
    }

    final StringBuffer msg = StringBuffer();
    msg.writeln('🌾 *RICE BUSINESS - STATEMENT OF ACCOUNT* 🌾');
    msg.writeln('----------------------------------------');
    msg.writeln('👤 *Customer:* $customerName');
    if (rawPhone.isNotEmpty) msg.writeln('📞 *Mobile:* $rawPhone');
    msg.writeln('📅 *Period:* $dateRangeStr');
    msg.writeln('----------------------------------------');
    msg.writeln('🔹 *Opening Balance:* ₹${numFormat.format(_openingBalance)}');
    msg.writeln('➕ *Total Sales (Debit):* ₹${numFormat.format(_periodDebit)}');
    msg.writeln('➖ *Total Paid (Credit):* ₹${numFormat.format(_periodCredit)}');
    msg.writeln('----------------------------------------');
    msg.writeln('📌 *CURRENT OUTSTANDING:* ₹${numFormat.format(closingBal)}');
    msg.writeln('----------------------------------------');

    if (_filteredTransactions.isNotEmpty) {
      msg.writeln('\n📋 *Recent Transactions:*');
      final recent = _filteredTransactions.take(5);
      for (var tx in recent) {
        final d = _parseDate(_getVal(tx, ['transactionDate', 'createdDate', 'date']));
        final dateStr = d != null ? dateFormat.format(d) : '';
        final double debit = _getnum(tx, ['debit']);
        final double credit = _getnum(tx, ['credit']);
        final type = debit > 0 ? 'Sale (+₹${numFormat.format(debit)})' : 'Payment (-₹${numFormat.format(credit)})';
        msg.writeln('• $dateStr: $type');
      }
    }

    msg.writeln('\n_Thank you for your business! / நன்றி!_');

    final encodedText = Uri.encodeComponent(msg.toString());
    Uri url;
    if (cleanPhone.isNotEmpty) {
      url = Uri.parse('https://wa.me/$cleanPhone?text=$encodedText');
    } else {
      url = Uri.parse('https://wa.me/?text=$encodedText');
    }

    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        AppToast.showError(context, 'Could not open WhatsApp');
      }
    } catch (e) {
      AppToast.showError(context, 'Error launching WhatsApp: $e');
    }
  }

  Future<void> _exportPdfStatement() async {
    final pdf = pw.Document();
    final customerName = widget.customer['name'] ?? 'Customer';
    final rawPhone = widget.customer['mobileNumber'] ?? widget.customer['phone'] ?? 'N/A';
    final address = widget.customer['address'] ?? 'N/A';

    String periodLabel = 'All Transactions';
    if (_selectedFilter == 'this_month') {
      periodLabel = 'This Month (${DateFormat('MMM yyyy').format(DateTime.now())})';
    } else if (_selectedFilter == 'last_30_days') {
      periodLabel = 'Last 30 Days';
    } else if (_selectedFilter == 'custom' && _customStartDate != null && _customEndDate != null) {
      periodLabel = '${dateFormat.format(_customStartDate!)} - ${dateFormat.format(_customEndDate!)}';
    }

    final transactionsList = List<dynamic>.from(_filteredTransactions);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (pw.Context context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('RICE BUSINESS APP', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: PdfColors.teal800)),
                    pw.Text('Statement of Account', style: pw.TextStyle(fontSize: 14, color: PdfColors.grey700)),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text('Date: ${dateFormat.format(DateTime.now())}', style: const pw.TextStyle(fontSize: 10)),
                    pw.Text('Period: $periodLabel', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                  ],
                ),
              ],
            ),
            pw.Divider(thickness: 1, color: PdfColors.teal800),
            pw.SizedBox(height: 8),
          ],
        ),
        build: (pw.Context context) {
          return [
            // Customer Header Box
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                border: pw.Border.all(color: PdfColors.grey300),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('STATEMENT FOR:', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.grey600)),
                      pw.SizedBox(height: 2),
                      pw.Text(customerName, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                      pw.Text('Phone: $rawPhone', style: const pw.TextStyle(fontSize: 10)),
                      pw.Text('Address: $address', style: const pw.TextStyle(fontSize: 10)),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('CLOSING OUTSTANDING', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.grey600)),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        'Rs. ${numFormat.format(_periodClosingBalance)}',
                        style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.red800),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 16),

            // Financial Summary Row
            pw.Row(
              children: [
                _pdfSummaryCard('Opening Balance', 'Rs. ${numFormat.format(_openingBalance)}', PdfColors.blueGrey800),
                pw.SizedBox(width: 8),
                _pdfSummaryCard('Total Sales (+)', 'Rs. ${numFormat.format(_periodDebit)}', PdfColors.orange800),
                pw.SizedBox(width: 8),
                _pdfSummaryCard('Total Paid (-)', 'Rs. ${numFormat.format(_periodCredit)}', PdfColors.green800),
                pw.SizedBox(width: 8),
                _pdfSummaryCard('Closing Balance', 'Rs. ${numFormat.format(_periodClosingBalance)}', PdfColors.teal800),
              ],
            ),
            pw.SizedBox(height: 16),

            // Transaction Table
            pw.Text('Transaction Details', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 6),
            pw.TableHelper.fromTextArray(
              headers: ['Date', 'Type', 'Particulars / Ref', 'Debit (Sales)', 'Credit (Paid)', 'Balance'],
              data: transactionsList.map((tx) {
                final d = _parseDate(_getVal(tx, ['transactionDate', 'createdDate', 'date']));
                final dateStr = d != null ? dateFormat.format(d) : '-';
                final double debit = _getnum(tx, ['debit']);
                final double credit = _getnum(tx, ['credit']);
                final double running = _getnum(tx, ['runningBalance']);
                final typeStr = tx['transactionType']?.toString() ?? (debit > 0 ? 'Sale' : 'Payment');
                final desc = tx['description'] ?? tx['notes'] ?? tx['referenceType'] ?? '-';

                return [
                  dateStr,
                  typeStr,
                  desc,
                  debit > 0 ? 'Rs. ${numFormat.format(debit)}' : '-',
                  credit > 0 ? 'Rs. ${numFormat.format(credit)}' : '-',
                  'Rs. ${numFormat.format(running)}',
                ];
              }).toList(),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 9),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.teal700),
              cellStyle: const pw.TextStyle(fontSize: 9),
              cellAlignment: pw.Alignment.centerLeft,
              cellAlignments: {
                3: pw.Alignment.centerRight,
                4: pw.Alignment.centerRight,
                5: pw.Alignment.centerRight,
              },
            ),
          ];
        },
        footer: (pw.Context context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Divider(thickness: 0.5, color: PdfColors.grey400),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Generated by Rice Business App', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
                pw.Text('Page ${context.pageNumber} of ${context.pagesCount}', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
              ],
            ),
          ],
        ),
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Ledger_Statement_${customerName.replaceAll(' ', '_')}.pdf',
    );
  }

  pw.Widget _pdfSummaryCard(String title, String value, PdfColor color) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(8),
        decoration: pw.BoxDecoration(
          color: PdfColors.grey50,
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
          border: pw.Border.all(color: PdfColors.grey300),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(title, style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
            pw.SizedBox(height: 2),
            pw.Text(value, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final customerName = widget.customer['name'] ?? 'Customer';
    final rawPhone = widget.customer['mobileNumber'] ?? widget.customer['phone'] ?? 'No Phone';
    final address = widget.customer['address'] ?? 'No Address';

    final filteredList = _filteredTransactions;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: BoxDecoration(
          color: isDark ? null : theme.scaffoldBackgroundColor,
          gradient: isDark
              ? RadialGradient(
                  center: const Alignment(0, -0.6),
                  radius: 1.2,
                  colors: [
                    colorScheme.surface,
                    theme.primaryColor,
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
              // Top Bar
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Icon(Icons.arrow_back, color: colorScheme.primary),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Ledger Statement',
                            style: TextStyle(
                              color: colorScheme.onSurface,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            customerName,
                            style: TextStyle(
                              color: colorScheme.outline,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.picture_as_pdf_outlined),
                      color: colorScheme.primary,
                      tooltip: 'Print / Export PDF',
                      onPressed: _exportPdfStatement,
                    ),
                    IconButton(
                      icon: const Icon(Icons.share_outlined),
                      color: Colors.green,
                      tooltip: 'Share on WhatsApp',
                      onPressed: _shareOnWhatsApp,
                    ),
                  ],
                ),
              ),

              // Filter Chips Row
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    _buildFilterChip('All Time', 'all'),
                    const SizedBox(width: 8),
                    _buildFilterChip('This Month', 'this_month'),
                    const SizedBox(width: 8),
                    _buildFilterChip('Last 30 Days', 'last_30_days'),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: Text(
                        _selectedFilter == 'custom' && _customStartDate != null && _customEndDate != null
                            ? '${dateFormat.format(_customStartDate!)} - ${dateFormat.format(_customEndDate!)}'
                            : 'Custom Dates',
                        style: TextStyle(
                          fontSize: 12,
                          color: _selectedFilter == 'custom' ? colorScheme.onPrimary : colorScheme.onSurface,
                        ),
                      ),
                      selected: _selectedFilter == 'custom',
                      selectedColor: colorScheme.primary,
                      onSelected: (selected) {
                        if (selected) {
                          _pickCustomDateRange();
                        }
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              Expanded(
                child: _isLoading
                    ? ListSkeleton(title: 'Loading Statement...')
                    : RefreshIndicator(
                        onRefresh: _loadData,
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Customer Summary Header Box
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? theme.primaryColor.withValues(alpha: 0.5)
                                      : colorScheme.surface,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: colorScheme.onSurface.withValues(alpha: 0.1),
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Row(
                                      children: [
                                        Icon(Icons.person, color: colorScheme.primary),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            customerName,
                                            style: TextStyle(
                                              color: colorScheme.onSurface,
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: _periodClosingBalance > 0
                                                ? Colors.red.withValues(alpha: 0.15)
                                                : Colors.green.withValues(alpha: 0.15),
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                          child: Text(
                                            _periodClosingBalance > 0 ? 'DUE' : 'CLEARED',
                                            style: TextStyle(
                                              color: _periodClosingBalance > 0 ? Colors.redAccent : Colors.green,
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Icon(Icons.phone_outlined, size: 14, color: colorScheme.outline),
                                        const SizedBox(width: 4),
                                        Text(rawPhone, style: TextStyle(fontSize: 12, color: colorScheme.outline)),
                                        const SizedBox(width: 16),
                                        Icon(Icons.location_on_outlined, size: 14, color: colorScheme.outline),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            address,
                                            style: TextStyle(fontSize: 12, color: colorScheme.outline),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 14),

                              // 4 Summary Metric Cards
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildMetricCard(
                                      'Opening Bal',
                                      '₹${numFormat.format(_openingBalance)}',
                                      Icons.account_balance_wallet_outlined,
                                      colorScheme.primary,
                                      isDark,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: _buildMetricCard(
                                      'Total Sales (+)',
                                      '₹${numFormat.format(_periodDebit)}',
                                      Icons.shopping_bag_outlined,
                                      Colors.orangeAccent,
                                      isDark,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildMetricCard(
                                      'Total Paid (-)',
                                      '₹${numFormat.format(_periodCredit)}',
                                      Icons.payments_outlined,
                                      Colors.green,
                                      isDark,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: _buildMetricCard(
                                      'Closing Balance',
                                      '₹${numFormat.format(_periodClosingBalance)}',
                                      Icons.trending_up,
                                      _periodClosingBalance > 0 ? Colors.redAccent : Colors.teal,
                                      isDark,
                                      isBold: true,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 18),

                              // Transactions Header
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Statement Transactions (${filteredList.length})',
                                    style: TextStyle(
                                      color: colorScheme.onSurface,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),

                              if (filteredList.isEmpty)
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 40),
                                  child: Center(
                                    child: Column(
                                      children: [
                                        Icon(Icons.receipt_long_outlined, size: 48, color: colorScheme.outline),
                                        const SizedBox(height: 8),
                                        Text(
                                          'No transactions found for selected period.',
                                          style: TextStyle(color: colorScheme.outline),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              else
                                ListView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: filteredList.length,
                                  itemBuilder: (context, index) {
                                    final tx = filteredList[index];
                                    final d = _parseDate(_getVal(tx, ['transactionDate', 'createdDate', 'date']));
                                    final double debit = _getnum(tx, ['debit']);
                                    final double credit = _getnum(tx, ['credit']);
                                    final double running = _getnum(tx, ['runningBalance']);
                                    final typeStr = tx['transactionType']?.toString() ?? (debit > 0 ? 'Sale' : 'Payment');
                                    final desc = tx['description'] ?? tx['notes'] ?? tx['referenceType'] ?? 'Transaction';

                                    final isDebit = debit > 0;

                                    return Container(
                                      margin: const EdgeInsets.only(bottom: 10),
                                      padding: const EdgeInsets.all(14),
                                      decoration: BoxDecoration(
                                        color: isDark
                                            ? theme.primaryColor.withValues(alpha: 0.35)
                                            : colorScheme.surface,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: colorScheme.onSurface.withValues(alpha: 0.08),
                                        ),
                                      ),
                                      child: Column(
                                        children: [
                                          Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.all(8),
                                                decoration: BoxDecoration(
                                                  color: isDebit
                                                      ? Colors.orange.withValues(alpha: 0.15)
                                                      : Colors.green.withValues(alpha: 0.15),
                                                  shape: BoxShape.circle,
                                                ),
                                                child: Icon(
                                                  isDebit ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                                                  color: isDebit ? Colors.orangeAccent : Colors.green,
                                                  size: 18,
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      desc,
                                                      style: TextStyle(
                                                        color: colorScheme.onSurface,
                                                        fontSize: 14,
                                                        fontWeight: FontWeight.w600,
                                                      ),
                                                    ),
                                                    if (d != null)
                                                      Text(
                                                        timeFormat.format(d),
                                                        style: TextStyle(
                                                          color: colorScheme.outline,
                                                          fontSize: 11,
                                                        ),
                                                      ),
                                                  ],
                                                ),
                                              ),
                                              Column(
                                                crossAxisAlignment: CrossAxisAlignment.end,
                                                children: [
                                                  Text(
                                                    isDebit ? '+₹${numFormat.format(debit)}' : '-₹${numFormat.format(credit)}',
                                                    style: TextStyle(
                                                      color: isDebit ? Colors.orangeAccent : Colors.green,
                                                      fontSize: 15,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                  Text(
                                                    'Bal: ₹${numFormat.format(running)}',
                                                    style: TextStyle(
                                                      color: colorScheme.outline,
                                                      fontSize: 11,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              const SizedBox(height: 30),
                            ],
                          ),
                        ),
                      ),
              ),

              // Bottom Action Bar
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? theme.primaryColor.withValues(alpha: 0.9) : colorScheme.surface,
                  border: Border(
                    top: BorderSide(color: colorScheme.onSurface.withValues(alpha: 0.1)),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: BorderSide(color: colorScheme.primary),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: _exportPdfStatement,
                        icon: const Icon(Icons.print_outlined),
                        label: const Text('PDF / Print'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade700,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: _shareOnWhatsApp,
                        icon: const Icon(Icons.share),
                        label: const Text('WhatsApp Share'),
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

  Widget _buildFilterChip(String label, String value) {
    final colorScheme = Theme.of(context).colorScheme;
    final isSelected = _selectedFilter == value;

    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: isSelected ? colorScheme.onPrimary : colorScheme.onSurface,
        ),
      ),
      selected: isSelected,
      selectedColor: colorScheme.primary,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _selectedFilter = value;
          });
        }
      },
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color, bool isDark, {bool isBold = false}) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? theme.primaryColor.withValues(alpha: 0.4) : colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.onSurface.withValues(alpha: 0.08),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 11,
                    color: colorScheme.outline,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: isBold ? 15 : 13,
                    fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
                    color: color,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
