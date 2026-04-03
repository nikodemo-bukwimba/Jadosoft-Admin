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
      id: json['id']?.toString() ?? '',
      customerId:
          (json['buyer_org_id'] ??
                  json['buyer_actor_id'] ??
                  json['customer_id'])
              ?.toString() ??
          '',
      items: _parseItems(json['items']),
      total:
          double.tryParse(
            json['total']?.toString() ?? json['subtotal']?.toString() ?? '0',
          ) ??
          0.0,
      paymentRef:
          json['payment_ref']?.toString() ?? json['order_number']?.toString(),
      status: _mapStatus(json['status']?.toString() ?? 'pending'),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  static String _mapStatus(String s) => switch (s) {
    'pending' => 'draft', // map Nexora pending → our draft
    'confirmed' => 'confirmed',
    'processing' => 'confirmed', // treat processing same as confirmed
    'shipped' => 'shipped',
    'delivered' => 'delivered',
    'cancelled' => 'cancelled',
    'refunded' => 'cancelled',
    _ => 'draft',
  };

  static List<Map<String, dynamic>> _parseItems(dynamic raw) {
    if (raw == null) return [];
    if (raw is! List) return [];
    return raw.map((e) {
      final m = Map<String, dynamic>.from(e as Map);
      return {
        'productId':
            (m['product_id'] ?? m['productId'] ?? m['variant_id'] ?? '')
                .toString(),
        'name': (m['product_name'] ?? m['variant_name'] ?? m['name'] ?? '')
            .toString(),
        'qty': int.tryParse((m['quantity'] ?? m['qty'] ?? 0).toString()) ?? 0,
        'unitPrice':
            double.tryParse(
              (m['unit_price'] ?? m['unitPrice'] ?? 0).toString(),
            ) ??
            0.0,
        'subtotal': double.tryParse((m['subtotal'] ?? 0).toString()) ?? 0.0,
      };
    }).toList();
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
