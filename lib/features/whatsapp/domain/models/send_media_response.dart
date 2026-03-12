class SendMediaResponse {
  final String messageId;
  final String status;

  const SendMediaResponse({
    required this.messageId,
    required this.status,
  });

  factory SendMediaResponse.fromJson(Map<String, dynamic> json) {
    return SendMediaResponse(
      messageId: json['message_id'] as String,
      status: json['status'] as String,
    );
  }
}
