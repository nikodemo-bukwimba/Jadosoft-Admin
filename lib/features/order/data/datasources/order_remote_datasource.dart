// === FILE: lib/features/order/data/datasources/order_remote_datasource.dart
// Admin App — adds CustomerNameResolver so customer names appear in order
// list and detail. Order IDs are now copyable in the detail page.
// All other logic (ship/deliver/markPaid etc.) preserved exactly.

import 'package:dio/dio.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/context/org_context.dart';
import '../../../../core/utils/customer_name_resolver.dart';
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
  late final CustomerNameResolver _nameResolver;

  OrderRemoteDataSourceImpl({required Dio dio, required OrgContext orgContext})
      : _dio = dio,
        _orgContext = orgContext {
    _nameResolver = CustomerNameResolver(
      dio: dio,
      // Root org so all customers across all branches are in the cache.
      orgId: () => orgContext.rootOrgId ?? orgContext.effectiveOrgId,
    );
  }

  String get _sellerBase =>
      '/commerce/orgs/${_orgContext.effectiveOrgId}/orders';

  // ── Inject customer name then parse ──────────────────────────────────────
  Future<OrderModel> _process(Map<String, dynamic> json) async {
    final injected = await _nameResolver.inject(json);
    return OrderModel.fromJson(injected);
  }

  // ── List ──────────────────────────────────────────────────────────────────
  @override
  Future<List<OrderModel>> getAll({String? createdById}) async {
    try {
      await _nameResolver.warmUp();
      final response = await _dio.get(
        _sellerBase,
        queryParameters: {
          'per_page': 100,
          if (createdById != null && createdById.isNotEmpty)
            'created_by_id': createdById,
        },
      );
      final data = (response.data['data'] ?? response.data) as List;
      return Future.wait(
        data.whereType<Map<String, dynamic>>().map(_process),
      );
    } on DioException catch (e) {
      throw ServerException(_msg(e), statusCode: e.response?.statusCode);
    }
  }

  // ── Single ────────────────────────────────────────────────────────────────
  @override
  Future<OrderModel> getById(String id) async {
    try {
      await _nameResolver.warmUp();
      final response = await _dio.get('/commerce/orders/$id');
      final data =
          response.data['data'] ?? response.data['order'] ?? response.data;
      return _process(data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(_msg(e), statusCode: e.response?.statusCode);
    }
  }

  // ── Create ────────────────────────────────────────────────────────────────
  @override
  Future<OrderModel> create(Map<String, dynamic> data) async {
    try {
      final orgId = _orgContext.effectiveOrgId;

      final items = (data['items'] as List<dynamic>).map((item) {
        final map = item as Map<String, dynamic>;
        return {
          'variant_id': map['variantId']?.toString(),
          'quantity': map['qty'],
          if (map['unitPrice'] != null)
            'unit_price': (map['unitPrice'] as num).toDouble(),
        };
      }).toList();

      final promotionPricing = <String, dynamic>{};
      for (final item in (data['items'] as List<dynamic>)) {
        final map = item as Map<String, dynamic>;
        if (map['promotionId'] != null) {
          promotionPricing[map['variantId'].toString()] = {
            'promotion_id': map['promotionId'],
            'discount_percentage': map['discountPercentage'],
            'base_price': map['basePrice'],
            'effective_price': map['unitPrice'],
            'subtotal': map['subtotal'],
          };
        }
      }

      final clientTotal = (data['client_total'] as num?)?.toDouble();

      final response = await _dio.post(
        '/commerce/orgs/$orgId/orders/admin',
        data: {
          'buyer_id': data['customer_id'] ?? data['customerId'],
          'items': items,
          if (data['payment_ref'] != null) 'payment_ref': data['payment_ref'],
          'currency': 'TZS',
          'metadata': {
            'created_by_name': data['created_by_name'],
            'created_by_id': data['created_by_id'],
            if (promotionPricing.isNotEmpty)
              'promotion_pricing': promotionPricing,
            if (clientTotal != null) 'client_total': clientTotal,
          },
        },
      );

      final body =
          (response.data['order'] ?? response.data) as Map<String, dynamic>;
      return _process(body);
    } on DioException catch (e) {
      throw ServerException(_msg(e), statusCode: e.response?.statusCode);
    }
  }

  // ── Update (no-op — transitions via confirm/ship/deliver/cancel) ──────────
  @override
  Future<OrderModel> update(String id, Map<String, dynamic> data) async {
    try {
      return await getById(id);
    } on DioException catch (e) {
      throw ServerException(_msg(e), statusCode: e.response?.statusCode);
    }
  }

  // ── Delete ────────────────────────────────────────────────────────────────
  @override
  Future<void> delete(String id) async {
    try {
      await _dio.post('/commerce/orders/$id/cancel');
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return;
      throw ServerException(_msg(e), statusCode: e.response?.statusCode);
    }
  }

  // ── Status transitions ────────────────────────────────────────────────────
  @override
  Future<OrderModel> confirm(String id) async {
    try {
      final response = await _dio.post('/commerce/orders/$id/confirm');
      final data =
          response.data['order'] ?? response.data['data'] ?? response.data;
      return _process(data as Map<String, dynamic>);
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
      return _process(data as Map<String, dynamic>);
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
      return _process(data as Map<String, dynamic>);
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
      return _process(data as Map<String, dynamic>);
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
      return _process(data as Map<String, dynamic>);
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