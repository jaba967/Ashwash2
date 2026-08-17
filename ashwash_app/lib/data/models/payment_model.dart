class PaymentModel {
  final int id;
  final String method;
  final double amount;
  final String purpose;
  final String transactionId;
  final String status;
  final String createdAt;

  PaymentModel({
    required this.id,
    required this.method,
    required this.amount,
    required this.purpose,
    required this.transactionId,
    required this.status,
    required this.createdAt,
  });

  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    return PaymentModel(
      id: json['id'] ?? 0,
      method: json['method'] ?? 'bkash',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      purpose: json['purpose'] ?? '',
      transactionId: json['transaction_id'] ?? '',
      status: json['status'] ?? 'success',
      createdAt: json['created_at'] ?? '',
    );
  }
}
