class Customer {
  final int id;
  final String name;
  final String? mobileNumber;
  final String? address;
  final double openingBalance;
  final double currentBalance;
  final bool isActive;
  final DateTime createdDate;
  final DateTime? updatedDate;

  Customer({
    required this.id,
    required this.name,
    this.mobileNumber,
    this.address,
    required this.openingBalance,
    required this.currentBalance,
    required this.isActive,
    required this.createdDate,
    this.updatedDate,
  });

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: json['id'],
      name: json['name'],
      mobileNumber: json['mobileNumber'],
      address: json['address'],
      openingBalance: (json['openingBalance'] ?? 0).toDouble(),
      currentBalance: (json['currentBalance'] ?? 0).toDouble(),
      isActive: json['isActive'] ?? true,
      createdDate: DateTime.parse(json['createdDate']),
      updatedDate: json['updatedDate'] != null
          ? DateTime.parse(json['updatedDate'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'mobileNumber': mobileNumber,
      'address': address,
      'openingBalance': openingBalance,
      'currentBalance': currentBalance,
      'isActive': isActive,
      'createdDate': createdDate.toIso8601String(),
      'updatedDate': updatedDate?.toIso8601String(),
    };
  }
}
