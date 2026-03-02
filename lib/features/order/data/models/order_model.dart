import '../../domain/entities/order_entity.dart';
import '../../domain/value_objects/order_status.dart';

class OrderModel extends OrderEntity {
  const OrderModel({
    required super.id,
    required super.orderNumber,
    required super.customerName,
    required super.totalAmount,
    required super.notes,
    required super.isUrgent,
    required super.createdAt,
    required super.updatedAt,
    super.status = OrderStatusX.initial,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: json['id'] as String,
      orderNumber: json['order_number'] as String,
      customerName: json['customer_name'] as String,
      totalAmount: (json['total_amount'] as num).toDouble(),
      notes: json['notes'] as String?,
      isUrgent: json['is_urgent'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      status: OrderStatus.values.firstWhere(
        (e) => e.name == (json['status'] as String? ?? 'draft'),
        orElse: () => OrderStatusX.initial,
      ),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'order_number': orderNumber,
    'customer_name': customerName,
    'total_amount': totalAmount,
    'notes': notes,
    'is_urgent': isUrgent,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
    'status': status.name,
  };

  factory OrderModel.fromEntity(OrderEntity entity) {
    return OrderModel(
      id: entity.id,
      orderNumber: entity.orderNumber,
      customerName: entity.customerName,
      totalAmount: entity.totalAmount,
      notes: entity.notes,
      isUrgent: entity.isUrgent,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      status: entity.status,
    );
  }
}
