import '../../domain/entities/order_entity.dart';

class OrderModel extends OrderEntity {
  const OrderModel({
    required super.id,
    required super.customerId,
    required super.items,
    required super.total,
    super.paymentRef,
    required super.status,
    required super.createdAt,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: json['id'] as String,
      customerId: json['customer_id'] as String,
      items: List<Map<String, dynamic>>.from(json['items'] as List),
      total: (json['total'] as num).toDouble(),
      paymentRef: json['payment_ref'] as String?,
      status: json['status'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'customer_id': customerId,
    'items': items,
    'total': total,
    'payment_ref': paymentRef,
    'status': status,
    'created_at': createdAt.toIso8601String(),
  };

  factory OrderModel.fromEntity(OrderEntity entity) {
    return OrderModel(
      id: entity.id,
      customerId: entity.customerId,
      items: entity.items,
      total: entity.total,
      paymentRef: entity.paymentRef,
      status: entity.status,
      createdAt: entity.createdAt,
    );
  }
}