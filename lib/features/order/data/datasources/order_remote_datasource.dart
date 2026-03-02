import 'package:dio/dio.dart';
import '../../../../core/error/exceptions.dart';
import '../models/order_model.dart';

abstract class OrderRemoteDataSource {
  Future<List<OrderModel>> getAll();
  Future<OrderModel>       getById(String id);
  Future<OrderModel>       create(Map<String, dynamic> data);
  Future<OrderModel>       update(String id, Map<String, dynamic> data);
  Future<void>                delete(String id);
}

class OrderRemoteDataSourceImpl implements OrderRemoteDataSource {
  final Dio _dio;
  OrderRemoteDataSourceImpl({required Dio dio}) : _dio = dio;

  @override
  Future<List<OrderModel>> getAll() async {
    try {
      final response = await _dio.get('/orders');
      final data = response.data as List;
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
      final response = await _dio.get('/orders/$id');
      return OrderModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(_msg(e), statusCode: e.response?.statusCode);
    }
  }

  @override
  Future<OrderModel> create(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post('/orders', data: data);
      return OrderModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(_msg(e), statusCode: e.response?.statusCode);
    }
  }

  @override
  Future<OrderModel> update(String id, Map<String, dynamic> data) async {
    try {
      final response = await _dio.put('/orders/$id', data: data);
      return OrderModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(_msg(e), statusCode: e.response?.statusCode);
    }
  }

  @override
  Future<void> delete(String id) async {
    try {
      await _dio.delete('/orders/$id');
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
