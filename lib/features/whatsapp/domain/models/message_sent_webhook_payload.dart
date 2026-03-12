class MessageSentWebhookPayload {
  final String event;
  final String messageId;
  final String to;
  final DateTime sentAt;

  const MessageSentWebhookPayload({
    required this.event,
    required this.messageId,
    required this.to,
    required this.sentAt,
  });

  factory MessageSentWebhookPayload.fromJson(Map<String, dynamic> json) {
    return MessageSentWebhookPayload(
      event: json['event'] as String,
      messageId: json['message_id'] as String,
      to: json['to'] as String,
      sentAt: DateTime.parse(json['sent_at'] as String),
    );
  }
}
