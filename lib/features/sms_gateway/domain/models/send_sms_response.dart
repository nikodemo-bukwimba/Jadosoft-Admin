class SendSmsResponse {
  final String messageId;
  final String status;
  final String to;
  final DateTime sentAt;

  const SendSmsResponse({
    required this.messageId,
    required this.status,
    required this.to,
    required this.sentAt,
  });

  factory SendSmsResponse.fromJson(Map<String, dynamic> json) {
    return SendSmsResponse(
      messageId: json['message_id'] as String,
      status: json['status'] as String,
      to: json['to'] as String,
      sentAt: DateTime.parse(json['sent_at'] as String),
    );
  }
}
