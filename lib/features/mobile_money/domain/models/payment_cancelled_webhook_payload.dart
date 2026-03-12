class PaymentCancelledWebhookPayload {
  final String event;
  final String transactionId;
  final DateTime cancelledAt;

  const PaymentCancelledWebhookPayload({
    required this.event,
    required this.transactionId,
    required this.cancelledAt,
  });

  factory PaymentCancelledWebhookPayload.fromJson(Map<String, dynamic> json) {
    return PaymentCancelledWebhookPayload(
      event: json['event'] as String,
      transactionId: json['transaction_id'] as String,
      cancelledAt: DateTime.parse(json['cancelled_at'] as String),
    );
  }
}
