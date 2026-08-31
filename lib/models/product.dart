class Product {
  final int id;
  final String productName;
  final String brandName;
  final double purchasePrice;
  final double sellingPrice;
  final double currentStock;
  final double minimumStockLevel;
  final bool isActive;
  final String bagSize;

  Product({
    required this.id,
    required this.productName,
    required this.brandName,
    required this.purchasePrice,
    required this.sellingPrice,
    required this.currentStock,
    required this.minimumStockLevel,
    required this.isActive,
    this.bagSize = '',
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      productName: json['productName'] ?? '',
      brandName: json['brandName'] ?? '',
      purchasePrice: (json['purchasePrice'] ?? 0).toDouble(),
      sellingPrice: (json['sellingPrice'] ?? 0).toDouble(),
      currentStock: (json['currentStock'] ?? 0).toDouble(),
      minimumStockLevel: (json['minimumStockLevel'] ?? 0).toDouble(),
      isActive: json['isActive'] ?? true,
      bagSize: json['bagSize'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'productName': productName,
      'brandName': brandName,
      'purchasePrice': purchasePrice,
      'sellingPrice': sellingPrice,
      'currentStock': currentStock,
      'minimumStockLevel': minimumStockLevel,
      'isActive': isActive,
      'bagSize': bagSize,
    };
  }
}
