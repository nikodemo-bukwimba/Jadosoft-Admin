import 'package:equatable/equatable.dart';
import '../value_objects/order_status.dart';

class OrderEntity extends Equatable {
  final String id;
  final String customerId;
  final List<Map<String, dynamic>> items;
  final double total;
  final String? paymentRef;
  final String status;
  final DateTime createdAt;
  // ── Payment audit fields ──────────────────────────────────
  final String paymentStatus;      // unpaid | paid | partial | refunded
  final String? paymentVerifiedBy; // actor ID who toggled, or 'system'
  final DateTime? paymentVerifiedAt;

  const OrderEntity({
    required this.id,
    required this.customerId,
    required this.items,
    required this.total,
    this.paymentRef,
    required this.status,
    required this.createdAt,
    this.paymentStatus = 'unpaid',
    this.paymentVerifiedBy,
    this.paymentVerifiedAt,
  });

  OrderEntity copyWith({
    String? id,
    String? customerId,
    List<Map<String, dynamic>>? items,
    double? total,
    String? paymentRef,
    String? status,
    DateTime? createdAt,
    String? paymentStatus,
    String? paymentVerifiedBy,
    DateTime? paymentVerifiedAt,
  }) {
    return OrderEntity(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      items: items ?? this.items,
      total: total ?? this.total,
      paymentRef: paymentRef ?? this.paymentRef,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      paymentVerifiedBy: paymentVerifiedBy ?? this.paymentVerifiedBy,
      paymentVerifiedAt: paymentVerifiedAt ?? this.paymentVerifiedAt,
    );
  }

  @override
  List<Object?> get props => [
    id, customerId, items, total, paymentRef, status, createdAt,
    paymentStatus, paymentVerifiedBy, paymentVerifiedAt,
  ];
}