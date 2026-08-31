class StockTransaction {
  final int id;
  final int productId;
  final String productName;
  final String brandName;
  final int transactionType; // 0 = In, 1 = Out, 2 = Adjustment
  final double quantity;
  final double previousStock;
  final double newStock;
  final int? customerId;
  final String? customerName;
  final String? referenceType;
  final int? referenceId;
  final DateTime transactionDate;
  final String? notes;
  final DateTime createdDate;

  StockTransaction({
    required this.id,
    required this.productId,
    required this.productName,
    required this.brandName,
    required this.transactionType,
    required this.quantity,
    required this.previousStock,
    required this.newStock,
    this.customerId,
    this.customerName,
    this.referenceType,
    this.referenceId,
    required this.transactionDate,
    this.notes,
    required this.createdDate,
  });

  factory StockTransaction.fromJson(Map<String, dynamic> json) {
    return StockTransaction(
      id: json['id'],
      productId: json['productId'],
      productName: json['productName'],
      brandName: json['brandName'],
      transactionType: json['transactionType'],
      quantity: (json['quantity'] ?? 0).toDouble(),
      previousStock: (json['previousStock'] ?? 0).toDouble(),
      newStock: (json['newStock'] ?? 0).toDouble(),
      customerId: json['customerId'],
      customerName: json['customerName'],
      referenceType: json['referenceType'],
      referenceId: json['referenceId'],
      transactionDate: DateTime.parse(json['transactionDate']),
      notes: json['notes'],
      createdDate: DateTime.parse(json['createdDate']),
    );
  }
}
