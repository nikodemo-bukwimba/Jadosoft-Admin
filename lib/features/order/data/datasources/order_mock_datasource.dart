import '../../domain/value_objects/order_status.dart';
import '../datasources/order_remote_datasource.dart';
import '../models/order_model.dart';

class OrderMockDataSource implements OrderRemoteDataSource {
  final List<OrderModel> _orders = [
    OrderModel(
      id: 'ord-001',
      customerId: 'cust-001',
      items: [
        {'productId': 'prod-001', 'name': 'Amoxicillin 500mg', 'qty': 10, 'unitPrice': 2500.0, 'subtotal': 25000.0},
        {'productId': 'prod-002', 'name': 'Paracetamol 1000mg', 'qty': 5, 'unitPrice': 1200.0, 'subtotal': 6000.0},
      ],
      total: 31000.0,
      paymentRef: 'MPESA-2024-001',
      status: OrderStatus.delivered.name,
      createdAt: DateTime.now().subtract(const Duration(days: 14)),
    ),
    OrderModel(
      id: 'ord-002',
      customerId: 'cust-002',
      items: [
        {'productId': 'prod-003', 'name': 'Metformin 850mg', 'qty': 30, 'unitPrice': 800.0, 'subtotal': 24000.0},
      ],
      total: 24000.0,
      paymentRef: 'AIRTEL-2024-002',
      status: OrderStatus.shipped.name,
      createdAt: DateTime.now().subtract(const Duration(days: 7)),
    ),
    OrderModel(
      id: 'ord-003',
      customerId: 'cust-003',
      items: [
        {'productId': 'prod-004', 'name': 'Omeprazole 20mg', 'qty': 20, 'unitPrice': 1500.0, 'subtotal': 30000.0},
        {'productId': 'prod-005', 'name': 'Vitamin C 1000mg', 'qty': 10, 'unitPrice': 900.0, 'subtotal': 9000.0},
        {'productId': 'prod-001', 'name': 'Amoxicillin 500mg', 'qty': 15, 'unitPrice': 2500.0, 'subtotal': 37500.0},
      ],
      total: 76500.0,
      paymentRef: 'MPESA-2024-003',
      status: OrderStatus.confirmed.name,
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
    ),
    OrderModel(
      id: 'ord-004',
      customerId: 'cust-004',
      items: [
        {'productId': 'prod-006', 'name': 'Ibuprofen 400mg', 'qty': 25, 'unitPrice': 700.0, 'subtotal': 17500.0},
      ],
      total: 17500.0,
      paymentRef: null,
      status: OrderStatus.draft.name,
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
    OrderModel(
      id: 'ord-005',
      customerId: 'cust-005',
      items: [
        {'productId': 'prod-007', 'name': 'Azithromycin 250mg', 'qty': 6, 'unitPrice': 3200.0, 'subtotal': 19200.0},
        {'productId': 'prod-002', 'name': 'Paracetamol 1000mg', 'qty': 12, 'unitPrice': 1200.0, 'subtotal': 14400.0},
      ],
      total: 33600.0,
      paymentRef: null,
      status: OrderStatus.cancelled.name,
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
    ),
    OrderModel(
      id: 'ord-006',
      customerId: 'cust-001',
      items: [
        {'productId': 'prod-008', 'name': 'Atorvastatin 40mg', 'qty': 30, 'unitPrice': 1800.0, 'subtotal': 54000.0},
      ],
      total: 54000.0,
      paymentRef: 'MPESA-2024-006',
      status: OrderStatus.confirmed.name,
      createdAt: DateTime.now().subtract(const Duration(hours: 6)),
    ),
  ];

  @override
  Future<List<OrderModel>> getAll() async {
    await Future.delayed(const Duration(milliseconds: 400));
    return List.from(_orders.reversed);
  }

  @override
  Future<OrderModel> getById(String id) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _orders.firstWhere((o) => o.id == id);
  }

  @override
  Future<OrderModel> create(Map<String, dynamic> data) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final model = OrderModel(
      id: 'ord-${DateTime.now().millisecondsSinceEpoch}',
      customerId: data['customer_id'] as String,
      items: List<Map<String, dynamic>>.from(data['items'] as List? ?? []),
      total: (data['total'] as num).toDouble(),
      paymentRef: data['payment_ref'] as String?,
      status: OrderStatus.draft.name,
      createdAt: DateTime.now(),
    );
    _orders.add(model);
    return model;
  }

  @override
  Future<OrderModel> update(String id, Map<String, dynamic> data) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final index = _orders.indexWhere((o) => o.id == id);
    final updated = OrderModel(
      id: id,
      customerId: data['customer_id'] as String? ?? _orders[index].customerId,
      items: data['items'] != null
          ? List<Map<String, dynamic>>.from(data['items'] as List)
          : _orders[index].items,
      total: data['total'] != null
          ? (data['total'] as num).toDouble()
          : _orders[index].total,
      paymentRef: data['payment_ref'] as String? ?? _orders[index].paymentRef,
      status: data['status'] as String? ?? _orders[index].status,
      createdAt: _orders[index].createdAt,
    );
    _orders[index] = updated;
    return updated;
  }

  @override
  Future<void> delete(String id) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _orders.removeWhere((o) => o.id == id);
  }
}