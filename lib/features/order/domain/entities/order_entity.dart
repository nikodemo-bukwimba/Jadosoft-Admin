// === FILE: lib/features/order/domain/entities/order_entity.dart
// Admin App — adds customerName/customerDisplay for resolved name display.
// All other fields (paymentStatus, createdByName, etc.) preserved exactly.

import 'package:equatable/equatable.dart';

class OrderEntity extends Equatable {
  final String id;
  final String customerId;

  /// Resolved customer display name — injected by CustomerNameResolver.
  /// Null until resolved; fall back to customerId in UI.
  final String? customerName;

  final List<Map<String, dynamic>> items;
  final double total;
  final String? paymentRef;
  final String status;
  final DateTime createdAt;

  // ── Payment audit fields ──────────────────────────────────
  final String paymentStatus;
  final String? paymentVerifiedBy;
  final DateTime? paymentVerifiedAt;

  // ── Order source fields ───────────────────────────────────
  final String? createdByName;
  final String? createdById;

  const OrderEntity({
    required this.id,
    required this.customerId,
    this.customerName,
    required this.items,
    required this.total,
    this.paymentRef,
    required this.status,
    required this.createdAt,
    this.paymentStatus = 'unpaid',
    this.paymentVerifiedBy,
    this.paymentVerifiedAt,
    this.createdByName,
    this.createdById,
  });

  /// Effective display label — resolved name when available, raw ID otherwise.
  String get customerDisplay =>
      (customerName != null && customerName!.isNotEmpty)
      ? customerName!
      : customerId;

  OrderEntity copyWith({
    String? id,
    String? customerId,
    String? customerName,
    List<Map<String, dynamic>>? items,
    double? total,
    String? paymentRef,
    String? status,
    DateTime? createdAt,
    String? paymentStatus,
    String? paymentVerifiedBy,
    DateTime? paymentVerifiedAt,
    String? createdByName,
    String? createdById,
  }) {
    return OrderEntity(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      items: items ?? this.items,
      total: total ?? this.total,
      paymentRef: paymentRef ?? this.paymentRef,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      paymentVerifiedBy: paymentVerifiedBy ?? this.paymentVerifiedBy,
      paymentVerifiedAt: paymentVerifiedAt ?? this.paymentVerifiedAt,
      createdByName: createdByName ?? this.createdByName,
      createdById: createdById ?? this.createdById,
    );
  }

  @override
  List<Object?> get props => [
    id,
    customerId,
    customerName,
    items,
    total,
    paymentRef,
    status,
    createdAt,
    paymentStatus,
    paymentVerifiedBy,
    paymentVerifiedAt,
    createdByName,
    createdById,
  ];
}
