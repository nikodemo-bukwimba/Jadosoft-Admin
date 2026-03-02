import 'package:equatable/equatable.dart';
import '../value_objects/order_status.dart';

class OrderEntity extends Equatable {
  final String id;
  final String orderNumber;
  final String customerName;
  final double totalAmount;
  final String? notes;
  final bool isUrgent;
  final DateTime createdAt;
  final DateTime updatedAt;
  final OrderStatus status;

  const OrderEntity({
    required this.id,
    required this.orderNumber,
    required this.customerName,
    required this.totalAmount,
    this.notes,
    required this.isUrgent,
    required this.createdAt,
    required this.updatedAt,
    this.status = OrderStatusX.initial,
  });

  OrderEntity copyWith({
    String? id,
    String? orderNumber,
    String? customerName,
    double? totalAmount,
    String? notes,
    bool? isUrgent,
    DateTime? createdAt,
    DateTime? updatedAt,
    OrderStatus? status,
  }) {
    return OrderEntity(
      id: id ?? this.id,
      orderNumber: orderNumber ?? this.orderNumber,
      customerName: customerName ?? this.customerName,
      totalAmount: totalAmount ?? this.totalAmount,
      notes: notes ?? this.notes,
      isUrgent: isUrgent ?? this.isUrgent,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      status: status ?? this.status,
    );
  }

  @override
  List<Object?> get props => [id, orderNumber, customerName, totalAmount, notes, isUrgent, createdAt, updatedAt, status];
}
