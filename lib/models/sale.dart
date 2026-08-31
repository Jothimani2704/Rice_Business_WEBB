class Sale {
  final int id;
  final int customerId;
  final String customerName;
  final DateTime saleDate;
  final double totalAmount;
  final double paidAmount;
  final double balanceAmount;
  final String paymentMode;
  final String? notes;
  final DateTime createdDate;
  final List<SaleItem> saleItems;

  Sale({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.saleDate,
    required this.totalAmount,
    required this.paidAmount,
    required this.balanceAmount,
    required this.paymentMode,
    this.notes,
    required this.createdDate,
    this.saleItems = const [],
  });

  factory Sale.fromJson(Map<String, dynamic> json) {
    var itemsList = json['saleItems'] as List? ?? [];
    List<SaleItem> items = itemsList.map((i) => SaleItem.fromJson(i)).toList();

    return Sale(
      id: json['id'],
      customerId: json['customerId'],
      customerName: json['customerName'],
      saleDate: DateTime.parse(json['saleDate']),
      totalAmount: (json['totalAmount'] ?? 0).toDouble(),
      paidAmount: (json['paidAmount'] ?? 0).toDouble(),
      balanceAmount: (json['balanceAmount'] ?? 0).toDouble(),
      paymentMode: json['paymentMode'],
      notes: json['notes'],
      createdDate: DateTime.parse(json['createdDate']),
      saleItems: items,
    );
  }
}

class SaleItem {
  final int id;
  final int productId;
  final String productName;
  final String brandName;
  final double quantity;
  final double rate;
  final double amount;

  SaleItem({
    required this.id,
    required this.productId,
    required this.productName,
    required this.brandName,
    required this.quantity,
    required this.rate,
    required this.amount,
  });

  factory SaleItem.fromJson(Map<String, dynamic> json) {
    return SaleItem(
      id: json['id'] ?? 0,
      productId: json['productId'],
      productName: json['productName'],
      brandName: json['brandName'],
      quantity: (json['quantity'] ?? 0).toDouble(),
      rate: (json['rate'] ?? 0).toDouble(),
      amount: (json['amount'] ?? 0).toDouble(),
    );
  }
}
