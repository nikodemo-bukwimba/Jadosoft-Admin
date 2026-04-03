import 'package:dio/dio.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/context/org_context.dart';
import '../models/order_model.dart';

abstract class OrderRemoteDataSource {
  Future<List<OrderModel>> getAll();
  Future<OrderModel> getById(String id);
  Future<OrderModel> create(Map<String, dynamic> data);
  Future<OrderModel> update(String id, Map<String, dynamic> data);
  Future<void> delete(String id);
  Future<OrderModel> confirm(String id);
  Future<OrderModel> ship(String id);
  Future<OrderModel> deliver(String id);
  Future<OrderModel> cancel(String id);
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

  @override
  Future<List<OrderModel>> getAll() async {
    try {
      final response = await _dio.get(
        _sellerBase,
        queryParameters: {'per_page': 100},
      );
      final data = (response.data['data'] ?? response.data) as List;
      return data
          .map((e) => OrderModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ServerException(_msg(e), statusCode: e.response?.statusCode);
    }
  }

  @override
  Future<OrderModel> getById(String id) async {
    try {
      // ✅ Correct: no org scope on single order fetch
      final response = await _dio.get('/commerce/orders/$id');
      final data =
          response.data['data'] ?? response.data['order'] ?? response.data;
      return OrderModel.fromJson(data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(_msg(e), statusCode: e.response?.statusCode);
    }
  }

  @override
  Future<OrderModel> create(Map<String, dynamic> data) async {
    try {
      final orgId = _orgContext.effectiveOrgId;

      // Build items for admin endpoint
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
        },
      );
      final body = response.data['order'] ?? response.data;
      return OrderModel.fromJson(body as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(_msg(e), statusCode: e.response?.statusCode);
    }
  }

  @override
  Future<OrderModel> update(String id, Map<String, dynamic> data) async {
    try {
      // Orders in Nexora are updated via status transitions, not PATCH
      // This is a no-op for now — status changes go through confirm/ship/deliver/cancel
      return await getById(id);
    } on DioException catch (e) {
      throw ServerException(_msg(e), statusCode: e.response?.statusCode);
    }
  }

  @override
  Future<void> delete(String id) async {
    try {
      // Nexora has no hard delete — cancel instead
      await _dio.post('/commerce/orders/$id/cancel');
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return;
      throw ServerException(_msg(e), statusCode: e.response?.statusCode);
    }
  }

  @override
  Future<OrderModel> confirm(String id) async {
    try {
      final response = await _dio.post('/commerce/orders/$id/confirm');
      final data = response.data['order'] ?? response.data;
      return OrderModel.fromJson(data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(_msg(e), statusCode: e.response?.statusCode);
    }
  }

  @override
  Future<OrderModel> ship(String id) async {
    try {
      final response = await _dio.post('/commerce/orders/$id/ship');
      final data = response.data['order'] ?? response.data;
      return OrderModel.fromJson(data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(_msg(e), statusCode: e.response?.statusCode);
    }
  }

  @override
  Future<OrderModel> deliver(String id) async {
    try {
      final response = await _dio.post('/commerce/orders/$id/deliver');
      final data = response.data['order'] ?? response.data;
      return OrderModel.fromJson(data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(_msg(e), statusCode: e.response?.statusCode);
    }
  }

  @override
  Future<OrderModel> cancel(String id) async {
    try {
      final response = await _dio.post('/commerce/orders/$id/cancel');
      final data = response.data['order'] ?? response.data;
      return OrderModel.fromJson(data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(_msg(e), statusCode: e.response?.statusCode);
    }
  }

  String _msg(DioException e) {
    final data = e.response?.data;
    if (data is Map<String, dynamic> && data['message'] is String) {
      return data['message'] as String;
    }
    return 'An error occurred. Please try again.';
  }
}
