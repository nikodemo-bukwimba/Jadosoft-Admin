class SendTemplateResponse {
  final String messageId;
  final String status;

  const SendTemplateResponse({
    required this.messageId,
    required this.status,
  });

  factory SendTemplateResponse.fromJson(Map<String, dynamic> json) {
    return SendTemplateResponse(
      messageId: json['message_id'] as String,
      status: json['status'] as String,
    );
  }
}
