import 'sale.dart';
import 'payment.dart';

class SalesReportResponse {
  final DateTime startDate;
  final DateTime endDate;
  final int? customerIdFilter;
  final int? productIdFilter;
  final double totalSalesAmount;
  final double totalQuantity;
  final int numberOfSales;
  final List<Sale> sales;

  SalesReportResponse({
    required this.startDate,
    required this.endDate,
    this.customerIdFilter,
    this.productIdFilter,
    required this.totalSalesAmount,
    required this.totalQuantity,
    required this.numberOfSales,
    required this.sales,
  });

  factory SalesReportResponse.fromJson(Map<String, dynamic> json) {
    return SalesReportResponse(
      startDate: DateTime.parse(json['startDate']),
      endDate: DateTime.parse(json['endDate']),
      customerIdFilter: json['customerIdFilter'],
      productIdFilter: json['productIdFilter'],
      totalSalesAmount: (json['totalSalesAmount'] ?? 0).toDouble(),
      totalQuantity: (json['totalQuantity'] ?? 0).toDouble(),
      numberOfSales: json['numberOfSales'] ?? 0,
      sales:
          (json['sales'] as List?)?.map((x) => Sale.fromJson(x)).toList() ?? [],
    );
  }
}

class PaymentReportResponse {
  final DateTime startDate;
  final DateTime endDate;
  final int? customerIdFilter;
  final String paymentModeFilter;
  final double totalCollection;
  final List<Payment> payments;

  PaymentReportResponse({
    required this.startDate,
    required this.endDate,
    this.customerIdFilter,
    required this.paymentModeFilter,
    required this.totalCollection,
    required this.payments,
  });

  factory PaymentReportResponse.fromJson(Map<String, dynamic> json) {
    return PaymentReportResponse(
      startDate: DateTime.parse(json['startDate']),
      endDate: DateTime.parse(json['endDate']),
      customerIdFilter: json['customerIdFilter'],
      paymentModeFilter: json['paymentModeFilter'] ?? '',
      totalCollection: (json['totalCollection'] ?? 0).toDouble(),
      payments:
          (json['payments'] as List?)
              ?.map((x) => Payment.fromJson(x))
              .toList() ??
          [],
    );
  }
}

class CustomerBalanceReportItem {
  final int customerId;
  final String customerName;
  final String phoneNumber;
  final double totalSales;
  final double totalPayments;
  final double outstandingBalance;
  final DateTime? lastTransactionDate;

  CustomerBalanceReportItem({
    required this.customerId,
    required this.customerName,
    required this.phoneNumber,
    required this.totalSales,
    required this.totalPayments,
    required this.outstandingBalance,
    this.lastTransactionDate,
  });

  factory CustomerBalanceReportItem.fromJson(Map<String, dynamic> json) {
    return CustomerBalanceReportItem(
      customerId: json['customerId'] ?? 0,
      customerName: json['customerName'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      totalSales: (json['totalSales'] ?? 0).toDouble(),
      totalPayments: (json['totalPayments'] ?? 0).toDouble(),
      outstandingBalance: (json['outstandingBalance'] ?? 0).toDouble(),
      lastTransactionDate: json['lastTransactionDate'] != null
          ? DateTime.parse(json['lastTransactionDate'])
          : null,
    );
  }
}

class StockReportItem {
  final int productId;
  final String productName;
  final String brandName;
  final double currentStock;
  final double minimumStockLevel;
  final String stockStatus;
  final double totalStockIn;
  final double totalStockOut;

  StockReportItem({
    required this.productId,
    required this.productName,
    required this.brandName,
    required this.currentStock,
    required this.minimumStockLevel,
    required this.stockStatus,
    required this.totalStockIn,
    required this.totalStockOut,
  });

  factory StockReportItem.fromJson(Map<String, dynamic> json) {
    return StockReportItem(
      productId: json['productId'] ?? 0,
      productName: json['productName'] ?? '',
      brandName: json['brandName'] ?? '',
      currentStock: (json['currentStock'] ?? 0).toDouble(),
      minimumStockLevel: (json['minimumStockLevel'] ?? 0).toDouble(),
      stockStatus: json['stockStatus'] ?? '',
      totalStockIn: (json['totalStockIn'] ?? 0).toDouble(),
      totalStockOut: (json['totalStockOut'] ?? 0).toDouble(),
    );
  }
}

class ProductSalesReportItem {
  final int productId;
  final String productName;
  final String brandName;
  final double quantitySold;
  final double salesAmount;
  final int numberOfCustomersPurchased;

  ProductSalesReportItem({
    required this.productId,
    required this.productName,
    required this.brandName,
    required this.quantitySold,
    required this.salesAmount,
    required this.numberOfCustomersPurchased,
  });

  factory ProductSalesReportItem.fromJson(Map<String, dynamic> json) {
    return ProductSalesReportItem(
      productId: json['productId'] ?? 0,
      productName: json['productName'] ?? '',
      brandName: json['brandName'] ?? '',
      quantitySold: (json['quantitySold'] ?? 0).toDouble(),
      salesAmount: (json['salesAmount'] ?? 0).toDouble(),
      numberOfCustomersPurchased: json['numberOfCustomersPurchased'] ?? 0,
    );
  }
}
