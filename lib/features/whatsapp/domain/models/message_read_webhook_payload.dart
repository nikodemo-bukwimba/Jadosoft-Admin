class MessageReadWebhookPayload {
  final String event;
  final String messageId;
  final DateTime readAt;

  const MessageReadWebhookPayload({
    required this.event,
    required this.messageId,
    required this.readAt,
  });

  factory MessageReadWebhookPayload.fromJson(Map<String, dynamic> json) {
    return MessageReadWebhookPayload(
      event: json['event'] as String,
      messageId: json['message_id'] as String,
      readAt: DateTime.parse(json['read_at'] as String),
    );
  }
}
