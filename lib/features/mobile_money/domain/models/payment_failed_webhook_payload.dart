class PaymentFailedWebhookPayload {
  final String event;
  final String transactionId;
  final String errorCode;
  final String errorMessage;

  const PaymentFailedWebhookPayload({
    required this.event,
    required this.transactionId,
    required this.errorCode,
    required this.errorMessage,
  });

  factory PaymentFailedWebhookPayload.fromJson(Map<String, dynamic> json) {
    return PaymentFailedWebhookPayload(
      event: json['event'] as String,
      transactionId: json['transaction_id'] as String,
      errorCode: json['error_code'] as String,
      errorMessage: json['error_message'] as String,
    );
  }
}
