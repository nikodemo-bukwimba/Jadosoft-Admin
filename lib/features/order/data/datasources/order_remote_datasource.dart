// order_remote_datasource.dart — Admin App
// Sends created_by_name / created_by_id in metadata on order creation.
// Supports ?created_by_id= query filter on seller list.

import 'package:dio/dio.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/context/org_context.dart';
import '../models/order_model.dart';

abstract class OrderRemoteDataSource {
  Future<List<OrderModel>> getAll({String? createdById});
  Future<OrderModel> getById(String id);
  Future<OrderModel> create(Map<String, dynamic> data);
  Future<OrderModel> update(String id, Map<String, dynamic> data);
  Future<void> delete(String id);
  Future<OrderModel> confirm(String id);
  Future<OrderModel> ship(String id);
  Future<OrderModel> deliver(String id);
  Future<OrderModel> cancel(String id);
  Future<OrderModel> markPaid(String id, String actorId, String? paymentRef);
}

class OrderRemoteDataSourceImpl implements OrderRemoteDataSource {
  final Dio _dio;
  final OrgContext _orgContext;

  OrderRemoteDataSourceImpl({required Dio dio, required OrgContext orgContext})
    : _dio = dio,
      _orgContext = orgContext;

  // Seller-scoped list — org is the seller
  String get _sellerBase =>
      '/commerce/orgs/${_orgContext.effectiveOrgId}/orders';

  // ── List ─────────────────────────────────────────────────

  @override
  Future<List<OrderModel>> getAll({String? createdById}) async {
    try {
      final response = await _dio.get(
        _sellerBase,
        queryParameters: {
          'per_page': 100,
          if (createdById != null && createdById.isNotEmpty)
            'created_by_id': createdById,
        },
      );
      final data = (response.data['data'] ?? response.data) as List;
      return data
          .map((e) => OrderModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ServerException(_msg(e), statusCode: e.response?.statusCode);
    }
  }

  // ── Single ───────────────────────────────────────────────

  @override
  Future<OrderModel> getById(String id) async {
    try {
      final response = await _dio.get('/commerce/orders/$id');
      final data =
          response.data['data'] ?? response.data['order'] ?? response.data;
      return OrderModel.fromJson(data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(_msg(e), statusCode: e.response?.statusCode);
    }
  }

  // ── Create ───────────────────────────────────────────────

  @override
  Future<OrderModel> create(Map<String, dynamic> data) async {
    try {
      final orgId = _orgContext.effectiveOrgId;

      final items = (data['items'] as List<dynamic>)
          .map(
            (item) => {
              'variant_id': item['variantId']?.toString(),
              'quantity': item['qty'],
            },
          )
          .toList();

      final response = await _dio.post(
        '/commerce/orgs/$orgId/orders/admin',
        data: {
          'buyer_id': data['customer_id'] ?? data['customerId'],
          'items': items,
          if (data['payment_ref'] != null) 'payment_ref': data['payment_ref'],
          'currency': 'TZS',
          // Officer / admin identity — stored in order metadata by the API
          'metadata': {
            'created_by_name': data['created_by_name'],
            'created_by_id': data['created_by_id'],
          },
        },
      );
      final body = response.data['order'] ?? response.data;
      return OrderModel.fromJson(body as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(_msg(e), statusCode: e.response?.statusCode);
    }
  }

  // ── Update (no-op — transitions via confirm/ship/deliver/cancel) ─────

  @override
  Future<OrderModel> update(String id, Map<String, dynamic> data) async {
    try {
      return await getById(id);
    } on DioException catch (e) {
      throw ServerException(_msg(e), statusCode: e.response?.statusCode);
    }
  }

  // ── Delete ───────────────────────────────────────────────

  @override
  Future<void> delete(String id) async {
    try {
      await _dio.post('/commerce/orders/$id/cancel');
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return;
      throw ServerException(_msg(e), statusCode: e.response?.statusCode);
    }
  }

  // ── Status transitions ───────────────────────────────────

  @override
  Future<OrderModel> confirm(String id) async {
    try {
      final response = await _dio.post('/commerce/orders/$id/confirm');
      final data =
          response.data['order'] ?? response.data['data'] ?? response.data;
      return OrderModel.fromJson(data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(_msg(e), statusCode: e.response?.statusCode);
    }
  }

  @override
  Future<OrderModel> ship(String id) async {
    try {
      final response = await _dio.post('/commerce/orders/$id/ship');
      final data =
          response.data['order'] ?? response.data['data'] ?? response.data;
      return OrderModel.fromJson(data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(_msg(e), statusCode: e.response?.statusCode);
    }
  }

  @override
  Future<OrderModel> deliver(String id) async {
    try {
      final response = await _dio.post('/commerce/orders/$id/deliver');
      final data =
          response.data['order'] ?? response.data['data'] ?? response.data;
      return OrderModel.fromJson(data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(_msg(e), statusCode: e.response?.statusCode);
    }
  }

  @override
  Future<OrderModel> cancel(String id) async {
    try {
      final response = await _dio.post('/commerce/orders/$id/cancel');
      final data =
          response.data['order'] ?? response.data['data'] ?? response.data;
      return OrderModel.fromJson(data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(_msg(e), statusCode: e.response?.statusCode);
    }
  }

  @override
  Future<OrderModel> markPaid(
    String id,
    String actorId,
    String? paymentRef,
  ) async {
    try {
      final response = await _dio.post(
        '/commerce/orders/$id/mark-paid',
        data: {
          'actor_id': actorId,
          if (paymentRef != null) 'payment_ref': paymentRef,
        },
      );
      final data =
          response.data['order'] ?? response.data['data'] ?? response.data;
      return OrderModel.fromJson(data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(_msg(e), statusCode: e.response?.statusCode);
    }
  }

  String _msg(DioException e) {
    final data = e.response?.data;
    if (data is Map<String, dynamic>) {
      if (data['message'] is String) return data['message'] as String;
      if (data['errors'] is Map) {
        final errors = data['errors'] as Map<String, dynamic>;
        final first = errors.values.first;
        if (first is List && first.isNotEmpty) return first.first.toString();
      }
    }
    return 'An error occurred. Please try again.';
  }
}
