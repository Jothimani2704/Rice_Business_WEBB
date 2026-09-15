import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/payment.dart';
import '../../services/payment_service.dart';
import '../../widgets/whatsapp_icon.dart';
import '../../utils/whatsapp_helper.dart';
import '../customer/customer_details_screen.dart';
import 'payment_form_screen.dart';

class PaymentDetailScreen extends StatefulWidget {
  final int paymentId;
  final Payment? initialPayment;

  const PaymentDetailScreen({
    super.key,
    required this.paymentId,
    this.initialPayment,
  });

  @override
  State<PaymentDetailScreen> createState() => _PaymentDetailScreenState();
}

class _PaymentDetailScreenState extends State<PaymentDetailScreen> {
  Payment? _payment;
  bool _isLoading = true;

  final numFormat = NumberFormat('#,##,###');

  @override
  void initState() {
    super.initState();
    if (widget.initialPayment != null) {
      _payment = widget.initialPayment;
      _isLoading = false;
    }
    _fetchPaymentDetails();
  }

  Future<void> _fetchPaymentDetails() async {
    try {
      final payment = await PaymentService.getPaymentById(widget.paymentId);
      if (mounted) {
        setState(() {
          if (payment != null) {
            _payment = payment;
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching payment details: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _getInitials(String name) {
    if (name.isEmpty) return '??';
    List<String> words = name.trim().split(' ');
    if (words.length > 1) {
      return '${words[0][0]}${words[1][0]}'.toUpperCase();
    }
    return name.substring(0, name.length > 1 ? 2 : 1).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading && _payment == null) {
      return Scaffold(
        backgroundColor: isDark
            ? Theme.of(context).primaryColor
            : Theme.of(context).scaffoldBackgroundColor,
        body: Center(
          child: CircularProgressIndicator(
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      );
    }

    if (_payment == null) {
      return Scaffold(
        backgroundColor: isDark
            ? Theme.of(context).primaryColor
            : Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
        body: Center(
          child: Text(
            'Payment not found',
            style: TextStyle(color: Theme.of(context).colorScheme.outline),
          ),
        ),
      );
    }

    final payment = _payment!;
    final paymentDate = payment.paymentDate;
    final dateStr = DateFormat('dd MMM yyyy').format(paymentDate);
    final timeStr = DateFormat('hh:mm a').format(paymentDate);

    return Scaffold(
      backgroundColor: isDark
          ? Theme.of(context).primaryColor
          : Theme.of(context).scaffoldBackgroundColor,
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark
              ? LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFF1E293B),
                    Theme.of(context).primaryColor,
                    const Color(0xFF0F172A),
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
                        'Payment Details',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    // WhatsApp Share Icon
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        WhatsAppHelper.sharePaymentReceipt(
                          context: context,
                          customerName: payment.customerName,
                          customerPhone: payment.customerMobile,
                          amount: payment.amount,
                          paymentMode: payment.paymentMode,
                          paymentDate: paymentDate,
                          previousBalance: payment.previousBalance,
                          newBalance: payment.newBalance,
                          referenceNumber: payment.referenceNumber,
                          notes: payment.notes,
                        );
                      },
                      child: const WhatsAppIcon(size: 28),
                    ),
                    const SizedBox(width: 16),

                    // Edit Icon
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PaymentFormScreen(
                              existingPayment: payment.toJson(),
                            ),
                          ),
                        );
                        if (result == true) {
                          _fetchPaymentDetails();
                        }
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: Icon(
                          Icons.edit_outlined,
                          color: Theme.of(context).colorScheme.primary,
                          size: 24,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Card
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Theme.of(context).primaryColor.withValues(alpha: 0.5)
                              : Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
                                ),
                              ),
                              child: Icon(
                                Icons.credit_score,
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
                                    'Payment #${payment.id}',
                                    style: TextStyle(
                                      color: Theme.of(context).colorScheme.onSurface,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '$dateStr • $timeStr',
                                    style: TextStyle(
                                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.surface,
                                border: Border.all(
                                  color: Colors.blueAccent.withValues(alpha: 0.5),
                                ),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                payment.paymentMode,
                                style: const TextStyle(
                                  color: Colors.blueAccent,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Customer Card
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Theme.of(context).primaryColor.withValues(alpha: 0.5)
                              : Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Customer',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.outline,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
                                    ),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    _getInitials(payment.customerName),
                                    style: TextStyle(
                                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
                                      fontSize: 18,
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
                                        payment.customerName,
                                        style: TextStyle(
                                          color: Theme.of(context).colorScheme.onSurface,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        payment.customerMobile ?? 'No Phone',
                                        style: TextStyle(
                                          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => CustomerDetailsScreen(
                                          customer: {
                                            'id': payment.customerId,
                                            'name': payment.customerName,
                                            'mobileNumber': payment.customerMobile,
                                          },
                                        ),
                                      ),
                                    );
                                  },
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.chevron_right,
                                        color: Theme.of(context).colorScheme.primary,
                                        size: 16,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Customer Details',
                                        style: TextStyle(
                                          color: Theme.of(context).colorScheme.primary,
                                          fontSize: 12,
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
                      const SizedBox(height: 16),

                      // Amount Card (Hero Display)
                      Container(
                        padding: const EdgeInsets.all(20),
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: isDark
                              ? Theme.of(context).primaryColor.withValues(alpha: 0.5)
                              : Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(
                              'Payment Received Amount',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.outline,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '₹${numFormat.format(payment.amount)}',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (payment.referenceNumber != null &&
                                payment.referenceNumber!.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'Ref: ${payment.referenceNumber}',
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.outline,
                                    fontSize: 12,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Payment & Balance Summary
                      Text(
                        'Payment Summary',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),

                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Theme.of(context).primaryColor.withValues(alpha: 0.5)
                              : Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1),
                          ),
                        ),
                        child: Column(
                          children: [
                            _buildSummaryRow(
                              'Previous Customer Balance',
                              payment.previousBalance,
                              Theme.of(context).colorScheme.onSurface,
                            ),
                            const SizedBox(height: 12),
                            _buildSummaryRow(
                              'Payment Received',
                              payment.amount,
                              Theme.of(context).colorScheme.primary,
                              isNegative: true,
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8.0),
                              child: Divider(
                                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                              ),
                            ),
                            _buildSummaryRow(
                              'Updated Customer Balance',
                              payment.newBalance,
                              payment.newBalance > 0
                                  ? Colors.redAccent
                                  : Theme.of(context).colorScheme.primary,
                              isBold: true,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Notes Section (If available)
                      if (payment.notes != null && payment.notes!.isNotEmpty) ...[
                        Text(
                          'Notes',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Theme.of(context).primaryColor.withValues(alpha: 0.5)
                                : Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1),
                            ),
                          ),
                          child: Text(
                            payment.notes!,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Business Impact Section
                      Text(
                        'Business Impact',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Theme.of(context).primaryColor.withValues(alpha: 0.5)
                              : Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.check_circle_outline,
                                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Customer Balance Reduced',
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.outline,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              '- ₹${numFormat.format(payment.amount)}',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 40),
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

  Widget _buildSummaryRow(
    String label,
    double value,
    Color textColor, {
    bool isBold = false,
    bool isNegative = false,
  }) {
    final prefix = isNegative ? '- ' : '';
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: isBold
                ? Theme.of(context).colorScheme.onSurface
                : Theme.of(context).colorScheme.outline,
            fontSize: 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          '$prefix₹${numFormat.format(value)}',
          style: TextStyle(
            color: textColor,
            fontSize: isBold ? 16 : 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}
