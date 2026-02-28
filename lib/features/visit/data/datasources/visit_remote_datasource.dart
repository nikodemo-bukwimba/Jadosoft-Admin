// visit_remote_datasource.dart
// All HTTP calls go through the shared Dio instance from core/network/.

import 'package:dio/dio.dart';
import '../../../../core/error/exceptions.dart';
import '../models/category_model.dart';
import '../../domain/repositories/visit_repository.dart';

abstract class VisitRemoteDataSource {
  Future<List<CategoryModel>> getAll({VisitFilterParams? filters});
  Future<CategoryModel>       getById(String id);
  Future<CategoryModel>       create(Map<String, dynamic> data);
  Future<CategoryModel>       update(String id, Map<String, dynamic> data);
  Future<void>                           delete(String id);
}

class VisitRemoteDataSourceImpl implements VisitRemoteDataSource {
  final Dio _dio;

  VisitRemoteDataSourceImpl({required Dio dio}) : _dio = dio;

  @override
  Future<List<CategoryModel>> getAll({VisitFilterParams? filters}) async {
    try {
      final response = await _dio.get('/visits');
      final data = response.data as List;
      return data.map((e) =>
          CategoryModel.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw ServerException(_extractMessage(e), statusCode: e.response?.statusCode);
    }
  }

  @override
  Future<CategoryModel> getById(String id) async {
    try {
      final response = await _dio.get('/visits/$id');
      return CategoryModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(_extractMessage(e), statusCode: e.response?.statusCode);
    }
  }

  @override
  Future<CategoryModel> create(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post('/visits', data: data);
      return CategoryModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(_extractMessage(e), statusCode: e.response?.statusCode);
    }
  }

  @override
  Future<CategoryModel> update(String id, Map<String, dynamic> data) async {
    try {
      final response = await _dio.put('/visits/$id', data: data);
      return CategoryModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(_extractMessage(e), statusCode: e.response?.statusCode);
    }
  }

  @override
  Future<void> delete(String id) async {
    try {
      await _dio.delete('/visits/$id');
    } on DioException catch (e) {
      throw ServerException(_extractMessage(e), statusCode: e.response?.statusCode);
    }
  }

  String _extractMessage(DioException e) {
    final data = e.response?.data;
    if (data is Map<String, dynamic> && data['message'] is String) {
      return data['message'] as String;
    }
    return e.message ?? 'An error occurred. Please try again.';
  }
}
