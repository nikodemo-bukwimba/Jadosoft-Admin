import 'package:dio/dio.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/context/org_context.dart';
import '../models/order_model.dart';

abstract class OrderRemoteDataSource {
  Future<List<OrderModel>> getAll();
  Future<OrderModel>       getById(String id);
  Future<OrderModel>       create(Map<String, dynamic> data);
  Future<OrderModel>       update(String id, Map<String, dynamic> data);
  Future<void>             delete(String id);
  Future<OrderModel>       confirm(String id);
  Future<OrderModel>       ship(String id);
  Future<OrderModel>       deliver(String id);
  Future<OrderModel>       cancel(String id);
}

class OrderRemoteDataSourceImpl implements OrderRemoteDataSource {
  final Dio _dio;
  final OrgContext _orgContext;

  OrderRemoteDataSourceImpl({
    required Dio dio,
    required OrgContext orgContext,
  })  : _dio = dio,
        _orgContext = orgContext;

  String get _base => '/commerce/${_orgContext.effectiveOrgId}/orders';

  @override
  Future<List<OrderModel>> getAll() async {
    try {
      final response = await _dio.get(_base);
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
      final response = await _dio.get('$_base/$id');
      final data = response.data['data'] ?? response.data;
      return OrderModel.fromJson(data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(_msg(e), statusCode: e.response?.statusCode);
    }
  }

  @override
  Future<OrderModel> create(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post(_base, data: data);
      final body = response.data['data'] ?? response.data;
      return OrderModel.fromJson(body as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(_msg(e), statusCode: e.response?.statusCode);
    }
  }

  @override
  Future<OrderModel> update(String id, Map<String, dynamic> data) async {
    try {
      final response = await _dio.put('$_base/$id', data: data);
      final body = response.data['data'] ?? response.data;
      return OrderModel.fromJson(body as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(_msg(e), statusCode: e.response?.statusCode);
    }
  }

  @override
  Future<void> delete(String id) async {
    try {
      await _dio.delete('$_base/$id');
    } on DioException catch (e) {
      throw ServerException(_msg(e), statusCode: e.response?.statusCode);
    }
  }

  @override
  Future<OrderModel> confirm(String id) async {
    try {
      final response = await _dio.post('$_base/$id/confirm');
      final body = response.data['data'] ?? response.data;
      return OrderModel.fromJson(body as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(_msg(e), statusCode: e.response?.statusCode);
    }
  }

  @override
  Future<OrderModel> ship(String id) async {
    try {
      final response = await _dio.post('$_base/$id/ship');
      final body = response.data['data'] ?? response.data;
      return OrderModel.fromJson(body as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(_msg(e), statusCode: e.response?.statusCode);
    }
  }

  @override
  Future<OrderModel> deliver(String id) async {
    try {
      final response = await _dio.post('$_base/$id/deliver');
      final body = response.data['data'] ?? response.data;
      return OrderModel.fromJson(body as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(_msg(e), statusCode: e.response?.statusCode);
    }
  }

  @override
  Future<OrderModel> cancel(String id) async {
    try {
      final response = await _dio.post('$_base/$id/cancel');
      final body = response.data['data'] ?? response.data;
      return OrderModel.fromJson(body as Map<String, dynamic>);
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