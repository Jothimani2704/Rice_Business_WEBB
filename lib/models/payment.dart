class Payment {
  final int id;
  final int customerId;
  final String customerName;
  final String? customerMobile;
  final double amount;
  final double previousBalance;
  final double newBalance;
  final String paymentMode;
  final DateTime paymentDate;
  final String? referenceNumber;
  final String? notes;
  final DateTime createdDate;
  final DateTime? updatedDate;

  Payment({
    required this.id,
    required this.customerId,
    required this.customerName,
    this.customerMobile,
    required this.amount,
    required this.previousBalance,
    required this.newBalance,
    required this.paymentMode,
    required this.paymentDate,
    this.referenceNumber,
    this.notes,
    required this.createdDate,
    this.updatedDate,
  });

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      id: json['id'],
      customerId: json['customerId'],
      customerName: json['customerName'] ?? 'Customer',
      customerMobile: json['customerMobile'] ?? json['mobileNumber'] ?? json['phone'] ?? json['customerPhone'],
      amount: (json['amount'] ?? 0).toDouble(),
      previousBalance: (json['previousBalance'] ?? 0).toDouble(),
      newBalance: (json['newBalance'] ?? 0).toDouble(),
      paymentMode: json['paymentMode'] ?? 'UPI',
      paymentDate: DateTime.tryParse(json['paymentDate']?.toString() ?? '') ?? DateTime.now(),
      referenceNumber: json['referenceNumber'],
      notes: json['notes'],
      createdDate: DateTime.tryParse(json['createdDate']?.toString() ?? '') ?? DateTime.now(),
      updatedDate: json['updatedDate'] != null
          ? DateTime.tryParse(json['updatedDate'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customerId': customerId,
      'customerName': customerName,
      'customerMobile': customerMobile,
      'amount': amount,
      'previousBalance': previousBalance,
      'newBalance': newBalance,
      'paymentMode': paymentMode,
      'paymentDate': paymentDate.toIso8601String(),
      'referenceNumber': referenceNumber,
      'notes': notes,
      'createdDate': createdDate.toIso8601String(),
      'updatedDate': updatedDate?.toIso8601String(),
    };
  }
}
