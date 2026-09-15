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

  /// Opens WhatsApp with a pre-formatted Sale Invoice message
  static Future<void> shareSaleInvoice({
    required BuildContext context,
    required String customerName,
    String? customerPhone,
    required dynamic saleId,
    required DateTime saleDate,
    required List<dynamic> items,
    required double totalAmount,
    required double paidAmount,
    required double balanceAmount,
    double? previousBalance,
    double? totalOutstandingBalance,
    String? paymentMode,
    String? notes,
  }) async {
    final dateFormat = DateFormat('dd-MMM-yyyy hh:mm a');
    final numFormat = NumberFormat('#,##,###');

    final String dateStr = dateFormat.format(saleDate);

    final StringBuffer sb = StringBuffer();
    sb.writeln('🛍️ *SALES INVOICE*');
    sb.writeln('------------------------------------');
    sb.writeln('👤 *Customer:* $customerName');
    sb.writeln('🧾 *Invoice No:* #SALE-$saleId');
    sb.writeln('📅 *Date:* $dateStr');
    sb.writeln('');
    sb.writeln('📦 *Items Purchased:*');

    for (var item in items) {
      String prodName = '';
      double qty = 0;
      double rate = 0;
      double amt = 0;

      if (item is Map) {
        prodName = (item['productName'] ?? item['name'] ?? 'Item').toString();
        qty = ((item['quantity'] ?? item['qty'] ?? 0) as num).toDouble();
        rate = ((item['rate'] ?? item['unitPrice'] ?? 0) as num).toDouble();
        amt = ((item['totalAmount'] ?? item['amount'] ?? (qty * rate)) as num).toDouble();
      } else {
        try {
          prodName = (item.productName ?? 'Item').toString();
          qty = (item.quantity ?? 0).toDouble();
          rate = (item.rate ?? 0).toDouble();
          amt = (item.amount ?? (qty * rate)).toDouble();
        } catch (_) {
          prodName = item.toString();
        }
      }

      final qtyStr = qty % 1 == 0 ? qty.toInt().toString() : qty.toString();
      sb.writeln('• $prodName ($qtyStr) x ₹${numFormat.format(rate)} = ₹${numFormat.format(amt)}');
    }

    sb.writeln('------------------------------------');
    sb.writeln('💰 *Bill Total:* ₹${numFormat.format(totalAmount)}');
    if (paidAmount > 0) {
      sb.writeln('💵 *Paid Amount:* ₹${numFormat.format(paidAmount)}');
    }
    if (balanceAmount > 0) {
      sb.writeln('📌 *Bill Due:* ₹${numFormat.format(balanceAmount)}');
    }

    // Previous Balance and Total Outstanding
    if (previousBalance != null && previousBalance > 0) {
      sb.writeln('📊 *Previous Balance:* ₹${numFormat.format(previousBalance)}');
    }

    final double netTotalBalance = totalOutstandingBalance ??
        ((previousBalance ?? 0) + balanceAmount);

    if (netTotalBalance > 0) {
      sb.writeln('🔻 *Total Outstanding Balance:* ₹${numFormat.format(netTotalBalance)}');
    }

    if (paymentMode != null && paymentMode.isNotEmpty) {
      sb.writeln('💳 *Payment Mode:* $paymentMode');
    }
    if (notes != null && notes.trim().isNotEmpty) {
      sb.writeln('📝 *Notes:* ${notes.trim()}');
    }
    sb.writeln('------------------------------------');
    sb.writeln('Thank you for shopping with us! 🙏');

    final String messageText = Uri.encodeComponent(sb.toString());

    // Format phone number
    String cleanPhone = (customerPhone ?? '').replaceAll(RegExp(r'[^\d+]'), '');
    if (cleanPhone.isNotEmpty && !cleanPhone.startsWith('+') && cleanPhone.length == 10) {
      cleanPhone = '91$cleanPhone';
    }

    final String urlString = cleanPhone.isNotEmpty
        ? 'https://wa.me/$cleanPhone?text=$messageText'
        : 'https://wa.me/?text=$messageText';

    final Uri uri = Uri.parse(urlString);

    try {
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched) {
        await launchUrl(uri, mode: LaunchMode.platformDefault);
      }
    } catch (e) {
      if (context.mounted) {
        AppToast.showError(context, 'Could not open WhatsApp: $e');
      }
    }
  }
}
