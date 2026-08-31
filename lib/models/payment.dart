class Payment {
  final int id;
  final int customerId;
  final String customerName;
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
      customerName: json['customerName'],
      amount: (json['amount'] ?? 0).toDouble(),
      previousBalance: (json['previousBalance'] ?? 0).toDouble(),
      newBalance: (json['newBalance'] ?? 0).toDouble(),
      paymentMode: json['paymentMode'],
      paymentDate: DateTime.parse(json['paymentDate']),
      referenceNumber: json['referenceNumber'],
      notes: json['notes'],
      createdDate: DateTime.parse(json['createdDate']),
      updatedDate: json['updatedDate'] != null
          ? DateTime.parse(json['updatedDate'])
          : null,
    );
  }
}
