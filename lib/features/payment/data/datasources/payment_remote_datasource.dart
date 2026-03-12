import 'package:dio/dio.dart';
import '../../../../core/error/exceptions.dart';
import '../models/payment_model.dart';

abstract class PaymentRemoteDataSource {
  Future<List<PaymentModel>> getAll();
  Future<PaymentModel>       getById(String id);
  Future<PaymentModel>       create(Map<String, dynamic> data);
  Future<PaymentModel>       update(String id, Map<String, dynamic> data);
  Future<void>                delete(String id);
}

class PaymentRemoteDataSourceImpl implements PaymentRemoteDataSource {
  final Dio _dio;
  PaymentRemoteDataSourceImpl({required Dio dio}) : _dio = dio;

  @override
  Future<List<PaymentModel>> getAll() async {
    try {
      final response = await _dio.get('');
      final data = response.data as List;
      return data
          .map((e) => PaymentModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ServerException(_msg(e), statusCode: e.response?.statusCode);
    }
  }

  @override
  Future<PaymentModel> getById(String id) async {
    try {
      final response = await _dio.get('/$id');
      return PaymentModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(_msg(e), statusCode: e.response?.statusCode);
    }
  }

  @override
  Future<PaymentModel> create(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post('', data: data);
      return PaymentModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(_msg(e), statusCode: e.response?.statusCode);
    }
  }

  @override
  Future<PaymentModel> update(String id, Map<String, dynamic> data) async {
    try {
      final response = await _dio.put('/$id', data: data);
      return PaymentModel.fromJson(response.data as Map<String, dynamic>);
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
