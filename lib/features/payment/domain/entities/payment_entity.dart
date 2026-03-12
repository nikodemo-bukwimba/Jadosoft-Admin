import 'package:equatable/equatable.dart';

class PaymentEntity extends Equatable {
  final String id;
  final String orderId;
  final String customerId;
  final double amount;
  final String currency;
  final String provider;
  final String? transactionRef;
  final String status;
  final DateTime initiatedAt;
  final DateTime? confirmedAt;
  final String? failureReason;

  const PaymentEntity({
    required this.id,
    required this.orderId,
    required this.customerId,
    required this.amount,
    required this.currency,
    required this.provider,
    this.transactionRef,
    required this.status,
    required this.initiatedAt,
    this.confirmedAt,
    this.failureReason,
  });

  PaymentEntity copyWith({
    String? id,
    String? orderId,
    String? customerId,
    double? amount,
    String? currency,
    String? provider,
    String? transactionRef,
    String? status,
    DateTime? initiatedAt,
    DateTime? confirmedAt,
    String? failureReason,
  }) {
    return PaymentEntity(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      customerId: customerId ?? this.customerId,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      provider: provider ?? this.provider,
      transactionRef: transactionRef ?? this.transactionRef,
      status: status ?? this.status,
      initiatedAt: initiatedAt ?? this.initiatedAt,
      confirmedAt: confirmedAt ?? this.confirmedAt,
      failureReason: failureReason ?? this.failureReason,
    );
  }

  @override
  List<Object?> get props => [];
}
