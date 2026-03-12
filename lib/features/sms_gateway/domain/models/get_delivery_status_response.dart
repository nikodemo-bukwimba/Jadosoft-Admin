class GetDeliveryStatusResponse {
  final String messageId;
  final String status;
  final DateTime? deliveredAt;
  final String? errorCode;
  final String? errorMessage;

  const GetDeliveryStatusResponse({
    required this.messageId,
    required this.status,
    this.deliveredAt,
    this.errorCode,
    this.errorMessage,
  });

  factory GetDeliveryStatusResponse.fromJson(Map<String, dynamic> json) {
    return GetDeliveryStatusResponse(
      messageId: json['message_id'] as String,
      status: json['status'] as String,
      deliveredAt: json['delivered_at'] != null ? DateTime.parse(json['delivered_at'] as String) : null,
      errorCode: json['error_code'] as String?,
      errorMessage: json['error_message'] as String?,
    );
  }
}
