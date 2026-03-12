class PaymentCompletedWebhookPayload {
  final String event;
  final String transactionId;
  final double amount;
  final DateTime completedAt;

  const PaymentCompletedWebhookPayload({
    required this.event,
    required this.transactionId,
    required this.amount,
    required this.completedAt,
  });

  factory PaymentCompletedWebhookPayload.fromJson(Map<String, dynamic> json) {
    return PaymentCompletedWebhookPayload(
      event: json['event'] as String,
      transactionId: json['transaction_id'] as String,
      amount: (json['amount'] as num).toDouble(),
      completedAt: DateTime.parse(json['completed_at'] as String),
    );
  }
}
