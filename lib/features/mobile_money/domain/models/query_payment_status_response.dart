class QueryPaymentStatusResponse {
  final String transactionId;
  final String status;
  final double amount;
  final String currency;
  final String provider;
  final DateTime? completedAt;
  final String? failureReason;

  const QueryPaymentStatusResponse({
    required this.transactionId,
    required this.status,
    required this.amount,
    required this.currency,
    required this.provider,
    this.completedAt,
    this.failureReason,
  });

  factory QueryPaymentStatusResponse.fromJson(Map<String, dynamic> json) {
    return QueryPaymentStatusResponse(
      transactionId: json['transaction_id'] as String,
      status: json['status'] as String,
      amount: (json['amount'] as num).toDouble(),
      currency: json['currency'] as String,
      provider: json['provider'] as String,
      completedAt: json['completed_at'] != null ? DateTime.parse(json['completed_at'] as String) : null,
      failureReason: json['failure_reason'] as String?,
    );
  }
}
