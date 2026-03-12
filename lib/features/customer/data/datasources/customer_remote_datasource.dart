import 'package:dio/dio.dart';
import '../../../../core/error/exceptions.dart';
import '../models/customer_model.dart';

abstract class CustomerRemoteDataSource {
  Future<List<CustomerModel>> getAll();
  Future<CustomerModel>       getById(String id);
  Future<CustomerModel>       create(Map<String, dynamic> data);
  Future<CustomerModel>       update(String id, Map<String, dynamic> data);
  Future<void>                delete(String id);
}

class CustomerRemoteDataSourceImpl implements CustomerRemoteDataSource {
  final Dio _dio;
  CustomerRemoteDataSourceImpl({required Dio dio}) : _dio = dio;

  @override
  Future<List<CustomerModel>> getAll() async {
    try {
      final response = await _dio.get('');
      final data = response.data as List;
      return data
          .map((e) => CustomerModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ServerException(_msg(e), statusCode: e.response?.statusCode);
    }
  }

  @override
  Future<CustomerModel> getById(String id) async {
    try {
      final response = await _dio.get('/$id');
      return CustomerModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(_msg(e), statusCode: e.response?.statusCode);
    }
  }

  @override
  Future<CustomerModel> create(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post('', data: data);
      return CustomerModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(_msg(e), statusCode: e.response?.statusCode);
    }
  }

  @override
  Future<CustomerModel> update(String id, Map<String, dynamic> data) async {
    try {
      final response = await _dio.put('/$id', data: data);
      return CustomerModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(_msg(e), statusCode: e.response?.statusCode);
    }
  }

  @override
  Future<void> delete(String id) async {
    try {
      await _dio.delete('/$id');
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
