import '../../domain/entities/payment_entity.dart';

class PaymentModel extends PaymentEntity {
  const PaymentModel({
    required super.id,
    required super.orderId,
    required super.customerId,
    required super.amount,
    required super.currency,
    required super.provider,
    super.transactionRef,
    required super.status,
    required super.initiatedAt,
    super.confirmedAt,
    super.failureReason,
  });

  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    return PaymentModel(
      id: json['id'] as String,
      orderId: json['order_id'] as String,
      customerId: json['customer_id'] as String,
      amount: (json['amount'] as num).toDouble(),
      currency: json['currency'] as String,
      provider: json['provider'] as String,
      transactionRef: json['transaction_ref'] as String?,
      status: json['status'] as String,
      initiatedAt: DateTime.parse(json['initiated_at'] as String),
      confirmedAt: json['confirmed_at'] != null
          ? DateTime.parse(json['confirmed_at'] as String)
          : null,
      failureReason: json['failure_reason'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'order_id': orderId,
        'customer_id': customerId,
        'amount': amount,
        'currency': currency,
        'provider': provider,
        'transaction_ref': transactionRef,
        'status': status,
        'initiated_at': initiatedAt.toIso8601String(),
        'confirmed_at': confirmedAt?.toIso8601String(),
        'failure_reason': failureReason,
      };

  factory PaymentModel.fromEntity(PaymentEntity entity) {
    return PaymentModel(
      id: entity.id,
      orderId: entity.orderId,
      customerId: entity.customerId,
      amount: entity.amount,
      currency: entity.currency,
      provider: entity.provider,
      transactionRef: entity.transactionRef,
      status: entity.status,
      initiatedAt: entity.initiatedAt,
      confirmedAt: entity.confirmedAt,
      failureReason: entity.failureReason,
    );
  }
}