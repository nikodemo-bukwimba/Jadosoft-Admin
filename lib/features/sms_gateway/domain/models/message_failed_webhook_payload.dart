class MessageFailedWebhookPayload {
  final String event;
  final String messageId;
  final String errorCode;
  final String errorMessage;

  const MessageFailedWebhookPayload({
    required this.event,
    required this.messageId,
    required this.errorCode,
    required this.errorMessage,
  });

  factory MessageFailedWebhookPayload.fromJson(Map<String, dynamic> json) {
    return MessageFailedWebhookPayload(
      event: json['event'] as String,
      messageId: json['message_id'] as String,
      errorCode: json['error_code'] as String,
      errorMessage: json['error_message'] as String,
    );
  }
}
