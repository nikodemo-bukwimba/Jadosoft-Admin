class GetMessageStatusResponse {
  final String messageId;
  final String status;
  final DateTime timestamp;

  const GetMessageStatusResponse({
    required this.messageId,
    required this.status,
    required this.timestamp,
  });

  factory GetMessageStatusResponse.fromJson(Map<String, dynamic> json) {
    return GetMessageStatusResponse(
      messageId: json['message_id'] as String,
      status: json['status'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }
}
