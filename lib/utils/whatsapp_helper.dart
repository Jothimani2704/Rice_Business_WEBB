import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'app_toast.dart';

class WhatsAppHelper {
  /// Opens WhatsApp with a pre-formatted Payment Receipt message
  static Future<void> sharePaymentReceipt({
    required BuildContext context,
    required String customerName,
    String? customerPhone,
    required double amount,
    required DateTime paymentDate,
    required String paymentMode,
    double? newBalance,
    String? referenceNumber,
    String? notes,
  }) async {
    final dateFormat = DateFormat('dd-MMM-yyyy hh:mm a');
    final numFormat = NumberFormat('#,##,###');

    final String dateStr = dateFormat.format(paymentDate);
    final String amountStr = '₹${numFormat.format(amount)}';
    final String balanceStr = newBalance != null ? '₹${numFormat.format(newBalance)}' : '';

    final StringBuffer sb = StringBuffer();
    sb.writeln('🧾 *PAYMENT RECEIPT*');
    sb.writeln('------------------------------------');
    sb.writeln('👤 *Customer:* $customerName');
    sb.writeln('💵 *Amount Received:* $amountStr');
    sb.writeln('📅 *Date:* $dateStr');
    sb.writeln('💳 *Payment Mode:* $paymentMode');
    if (referenceNumber != null && referenceNumber.trim().isNotEmpty) {
      sb.writeln('📌 *Ref No:* ${referenceNumber.trim()}');
    }
    if (newBalance != null) {
      sb.writeln('📊 *Remaining Balance:* $balanceStr');
    }
    if (notes != null && notes.trim().isNotEmpty) {
      sb.writeln('📝 *Notes:* ${notes.trim()}');
    }
    sb.writeln('------------------------------------');
    sb.writeln('Thank you for your payment! 🙏');

    final String messageText = Uri.encodeComponent(sb.toString());

    // Format phone number
    String cleanPhone = (customerPhone ?? '').replaceAll(RegExp(r'[^\d+]'), '');
    if (cleanPhone.isNotEmpty && !cleanPhone.startsWith('+') && cleanPhone.length == 10) {
      cleanPhone = '91$cleanPhone'; // Default India country code prefix
    }

    final String urlString = cleanPhone.isNotEmpty
        ? 'https://wa.me/$cleanPhone?text=$messageText'
        : 'https://wa.me/?text=$messageText';

    final Uri uri = Uri.parse(urlString);

    try {
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched) {
        // Fallback launch mode
        await launchUrl(uri, mode: LaunchMode.platformDefault);
      }
    } catch (e) {
      if (context.mounted) {
        AppToast.showError(context, 'Could not open WhatsApp: $e');
      }
    }
  }
}
