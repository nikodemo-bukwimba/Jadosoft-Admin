import '../datasources/payment_remote_datasource.dart';
import '../models/payment_model.dart';

class PaymentMockDataSource implements PaymentRemoteDataSource {
  final List<PaymentModel> _payments = [
    PaymentModel(
      id: 'pay-001',
      orderId: 'ord-001',
      customerId: 'cust-001',
      amount: 31000.0,
      currency: 'TZS',
      provider: 'M-Pesa',
      transactionRef: 'MPESA-2024-001',
      status: 'confirmed',
      initiatedAt: DateTime.now().subtract(const Duration(days: 14, minutes: 5)),
      confirmedAt: DateTime.now().subtract(const Duration(days: 14)),
      failureReason: null,
    ),
    PaymentModel(
      id: 'pay-002',
      orderId: 'ord-002',
      customerId: 'cust-002',
      amount: 24000.0,
      currency: 'TZS',
      provider: 'Airtel Money',
      transactionRef: 'AIRTEL-2024-002',
      status: 'confirmed',
      initiatedAt: DateTime.now().subtract(const Duration(days: 7, minutes: 3)),
      confirmedAt: DateTime.now().subtract(const Duration(days: 7)),
      failureReason: null,
    ),
    PaymentModel(
      id: 'pay-003',
      orderId: 'ord-003',
      customerId: 'cust-003',
      amount: 76500.0,
      currency: 'TZS',
      provider: 'M-Pesa',
      transactionRef: 'MPESA-2024-003',
      status: 'confirmed',
      initiatedAt: DateTime.now().subtract(const Duration(days: 3, minutes: 2)),
      confirmedAt: DateTime.now().subtract(const Duration(days: 3)),
      failureReason: null,
    ),
    PaymentModel(
      id: 'pay-004',
      orderId: 'ord-004',
      customerId: 'cust-004',
      amount: 17500.0,
      currency: 'TZS',
      provider: 'M-Pesa',
      transactionRef: null,
      status: 'pending',
      initiatedAt: DateTime.now().subtract(const Duration(days: 1)),
      confirmedAt: null,
      failureReason: null,
    ),
    PaymentModel(
      id: 'pay-005',
      orderId: 'ord-005',
      customerId: 'cust-005',
      amount: 33600.0,
      currency: 'TZS',
      provider: 'Airtel Money',
      transactionRef: null,
      status: 'failed',
      initiatedAt: DateTime.now().subtract(const Duration(days: 5, minutes: 10)),
      confirmedAt: null,
      failureReason: 'Insufficient funds in customer account',
    ),
    PaymentModel(
      id: 'pay-006',
      orderId: 'ord-006',
      customerId: 'cust-001',
      amount: 54000.0,
      currency: 'TZS',
      provider: 'M-Pesa',
      transactionRef: 'MPESA-2024-006',
      status: 'confirmed',
      initiatedAt: DateTime.now().subtract(const Duration(hours: 6, minutes: 2)),
      confirmedAt: DateTime.now().subtract(const Duration(hours: 6)),
      failureReason: null,
    ),
  ];

  @override
  Future<List<PaymentModel>> getAll() async {
    await Future.delayed(const Duration(milliseconds: 400));
    return List.from(_payments.reversed);
  }

  @override
  Future<PaymentModel> getById(String id) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _payments.firstWhere((p) => p.id == id);
  }

  @override
  Future<PaymentModel> create(Map<String, dynamic> data) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final model = PaymentModel(
      id: 'pay-${DateTime.now().millisecondsSinceEpoch}',
      orderId: data['order_id'] as String,
      customerId: data['customer_id'] as String,
      amount: (data['amount'] as num).toDouble(),
      currency: data['currency'] as String? ?? 'TZS',
      provider: data['provider'] as String,
      transactionRef: data['transaction_ref'] as String?,
      status: 'pending',
      initiatedAt: DateTime.now(),
      confirmedAt: null,
      failureReason: null,
    );
    _payments.add(model);
    return model;
  }

  @override
  Future<PaymentModel> update(String id, Map<String, dynamic> data) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final index = _payments.indexWhere((p) => p.id == id);
    final existing = _payments[index];
    final updated = PaymentModel(
      id: id,
      orderId: data['order_id'] as String? ?? existing.orderId,
      customerId: data['customer_id'] as String? ?? existing.customerId,
      amount: data['amount'] != null
          ? (data['amount'] as num).toDouble()
          : existing.amount,
      currency: data['currency'] as String? ?? existing.currency,
      provider: data['provider'] as String? ?? existing.provider,
      transactionRef:
          data['transaction_ref'] as String? ?? existing.transactionRef,
      status: data['status'] as String? ?? existing.status,
      initiatedAt: existing.initiatedAt,
      confirmedAt: data['confirmed_at'] != null
          ? DateTime.parse(data['confirmed_at'] as String)
          : existing.confirmedAt,
      failureReason:
          data['failure_reason'] as String? ?? existing.failureReason,
    );
    _payments[index] = updated;
    return updated;
  }

  @override
  Future<void> delete(String id) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _payments.removeWhere((p) => p.id == id);
  }
}