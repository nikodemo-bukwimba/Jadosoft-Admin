class MessageDeliveredWebhookPayload {
  final String event;
  final String messageId;
  final DateTime deliveredAt;

  const MessageDeliveredWebhookPayload({
    required this.event,
    required this.messageId,
    required this.deliveredAt,
  });

  factory MessageDeliveredWebhookPayload.fromJson(Map<String, dynamic> json) {
    return MessageDeliveredWebhookPayload(
      event: json['event'] as String,
      messageId: json['message_id'] as String,
      deliveredAt: DateTime.parse(json['delivered_at'] as String),
    );
  }
}
