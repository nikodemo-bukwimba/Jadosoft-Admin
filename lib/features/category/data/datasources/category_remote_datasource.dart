import 'package:dio/dio.dart';
import '../../../../core/error/exceptions.dart';
import '../models/category_model.dart';

abstract class CategoryRemoteDataSource {
  Future<List<CategoryModel>> getAll();
  Future<CategoryModel>       getById(String id);
  Future<CategoryModel>       create(Map<String, dynamic> data);
  Future<CategoryModel>       update(String id, Map<String, dynamic> data);
  Future<void>                delete(String id);
}

class CategoryRemoteDataSourceImpl implements CategoryRemoteDataSource {
  final Dio _dio;
  CategoryRemoteDataSourceImpl({required Dio dio}) : _dio = dio;

  @override
  Future<List<CategoryModel>> getAll() async {
    try {
      final response = await _dio.get('');
      final data = response.data as List;
      return data
          .map((e) => CategoryModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ServerException(_msg(e), statusCode: e.response?.statusCode);
    }
  }

  @override
  Future<CategoryModel> getById(String id) async {
    try {
      final response = await _dio.get('/$id');
      return CategoryModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(_msg(e), statusCode: e.response?.statusCode);
    }
  }

  @override
  Future<CategoryModel> create(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post('', data: data);
      return CategoryModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(_msg(e), statusCode: e.response?.statusCode);
    }
  }

  @override
  Future<CategoryModel> update(String id, Map<String, dynamic> data) async {
    try {
      final response = await _dio.put('/$id', data: data);
      return CategoryModel.fromJson(response.data as Map<String, dynamic>);
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
