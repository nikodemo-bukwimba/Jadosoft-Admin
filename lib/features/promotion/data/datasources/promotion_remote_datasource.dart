import 'package:dio/dio.dart';
import '../../../../core/error/exceptions.dart';
import '../models/promotion_model.dart';

abstract class PromotionRemoteDataSource {
  Future<List<PromotionModel>> getAll();
  Future<PromotionModel>       getById(String id);
  Future<PromotionModel>       create(Map<String, dynamic> data);
  Future<PromotionModel>       update(String id, Map<String, dynamic> data);
  Future<void>                delete(String id);
}

class PromotionRemoteDataSourceImpl implements PromotionRemoteDataSource {
  final Dio _dio;
  PromotionRemoteDataSourceImpl({required Dio dio}) : _dio = dio;

  @override
  Future<List<PromotionModel>> getAll() async {
    try {
      final response = await _dio.get('/promotions');
      final data = response.data as List;
      return data
          .map((e) => PromotionModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ServerException(_msg(e), statusCode: e.response?.statusCode);
    }
  }

  @override
  Future<PromotionModel> getById(String id) async {
    try {
      final response = await _dio.get('/promotions/$id');
      return PromotionModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(_msg(e), statusCode: e.response?.statusCode);
    }
  }

  @override
  Future<PromotionModel> create(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post('/promotions', data: data);
      return PromotionModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(_msg(e), statusCode: e.response?.statusCode);
    }
  }

  @override
  Future<PromotionModel> update(String id, Map<String, dynamic> data) async {
    try {
      final response = await _dio.put('/promotions/$id', data: data);
      return PromotionModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(_msg(e), statusCode: e.response?.statusCode);
    }
  }

  @override
  Future<void> delete(String id) async {
    try {
      await _dio.delete('/promotions/$id');
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
