// order_model.dart — Admin App
import 'dart:convert';
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
    super.paymentStatus = 'unpaid',
    super.paymentVerifiedBy,
    super.paymentVerifiedAt,
    super.createdByName,
    super.createdById,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    final meta = _meta(json);
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
      paymentStatus:
          meta['payment_status']?.toString() ??
          json['payment_status']?.toString() ??
          'unpaid',
      paymentVerifiedBy:
          meta['payment_verified_by']?.toString() ??
          json['payment_verified_by']?.toString(),
      paymentVerifiedAt:
          (meta['payment_verified_at'] ?? json['payment_verified_at']) != null
          ? DateTime.tryParse(
              (meta['payment_verified_at'] ?? json['payment_verified_at'])
                  .toString(),
            )
          : null,
      // ── Order source ────────────────────────────────────
      createdByName:
          meta['created_by_name']?.toString() ??
          json['created_by_name']?.toString(),
      createdById:
          meta['created_by_id']?.toString() ??
          json['created_by_id']?.toString(),
    );
  }

  static String _mapStatus(String s) => switch (s) {
    'pending' => 'draft',
    'confirmed' => 'confirmed',
    'processing' => 'confirmed',
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
    'payment_status': paymentStatus,
    if (paymentVerifiedBy != null) 'payment_verified_by': paymentVerifiedBy,
    if (paymentVerifiedAt != null)
      'payment_verified_at': paymentVerifiedAt!.toIso8601String(),
    if (createdByName != null) 'created_by_name': createdByName,
    if (createdById != null) 'created_by_id': createdById,
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
      paymentStatus: entity.paymentStatus,
      paymentVerifiedBy: entity.paymentVerifiedBy,
      paymentVerifiedAt: entity.paymentVerifiedAt,
      createdByName: entity.createdByName,
      createdById: entity.createdById,
    );
  }

  static Map<String, dynamic> _meta(Map<String, dynamic> json) {
    final raw = json['metadata'];
    if (raw == null) return {};
    if (raw is Map<String, dynamic>) return raw;
    if (raw is String) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map<String, dynamic>) return decoded;
      } catch (_) {}
    }
    return {};
  }
}
