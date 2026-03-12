class InitiatePaymentResponse {
  final String transactionId;
  final String status;
  final String provider;
  final DateTime initiatedAt;

  const InitiatePaymentResponse({
    required this.transactionId,
    required this.status,
    required this.provider,
    required this.initiatedAt,
  });

  factory InitiatePaymentResponse.fromJson(Map<String, dynamic> json) {
    return InitiatePaymentResponse(
      transactionId: json['transaction_id'] as String,
      status: json['status'] as String,
      provider: json['provider'] as String,
      initiatedAt: DateTime.parse(json['initiated_at'] as String),
    );
  }
}
