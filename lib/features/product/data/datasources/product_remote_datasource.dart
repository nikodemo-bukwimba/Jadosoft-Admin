// lib/features/product/data/datasources/product_remote_datasource.dart

import 'package:dio/dio.dart';
import '../../../../core/error/exceptions.dart';
import '../models/product_model.dart';

abstract class ProductRemoteDataSource {
  Future<List<ProductModel>> getAll();
  Future<ProductModel> getById(String id, {String? orgId});
  Future<ProductModel> create(Map<String, dynamic> data);
  Future<ProductModel> update(String id, Map<String, dynamic> data);
  Future<void> delete(String id);

  /// Upload a local image file to the server.
  ///
  /// [localPath] is the absolute device path returned by image_picker.
  /// Returns a public https:// URL to store as image_url in the product.
  Future<String> uploadImage(String localPath);
}

/// Legacy stub — not wired to the live API; kept for compilation only.
class ProductRemoteDataSourceImpl implements ProductRemoteDataSource {
  final Dio _dio;
  ProductRemoteDataSourceImpl({required Dio dio}) : _dio = dio;

  String _msg(DioException e) {
    final data = e.response?.data;
    if (data is Map<String, dynamic> && data['message'] is String) {
      return data['message'] as String;
    }
    return 'An error occurred. Please try again.';
  }

  @override
  Future<List<ProductModel>> getAll() async {
    try {
      final response = await _dio.get('/products');
      final data = (response.data['data'] ?? response.data) as List;
      return data
          .map((e) => ProductModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ServerException(_msg(e), statusCode: e.response?.statusCode);
    }
  }

  @override
  Future<ProductModel> getById(String id, {String? orgId}) async {
    try {
      final response = await _dio.get('/products/$id');
      return ProductModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(_msg(e), statusCode: e.response?.statusCode);
    }
  }

  @override
  Future<ProductModel> create(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post('/products', data: data);
      return ProductModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(_msg(e), statusCode: e.response?.statusCode);
    }
  }

  @override
  Future<ProductModel> update(String id, Map<String, dynamic> data) async {
    try {
      final response = await _dio.put('/products/$id', data: data);
      return ProductModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(_msg(e), statusCode: e.response?.statusCode);
    }
  }

  @override
  Future<void> delete(String id) async {
    try {
      await _dio.delete('/products/$id');
    } on DioException catch (e) {
      throw ServerException(_msg(e), statusCode: e.response?.statusCode);
    }
  }

  @override
  Future<String> uploadImage(String localPath) {
    throw UnimplementedError('Use ProductApiDataSource instead.');
  }
}
