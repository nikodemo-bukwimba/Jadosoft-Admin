import 'package:dio/dio.dart';

import '../../../../core/error/exceptions.dart';
import '../models/product_model.dart';

/// Remote data source for the Nexora Commerce Products API.
///
/// Endpoints:
///   GET    /api/v1/commerce/orgs/{orgId}/products
///   POST   /api/v1/commerce/orgs/{orgId}/products
///   GET    /api/v1/commerce/products/{id}
///   PATCH  /api/v1/commerce/products/{id}
///   DELETE /api/v1/commerce/products/{id}
///   POST   /api/v1/commerce/products/{id}/publish
///   POST   /api/v1/commerce/products/{id}/archive
abstract class ProductRemoteDatasource {
  Future<List<ProductModel>> getAll({
    required String orgId,
    int page = 1,
    int perPage = 25,
    String? status,
    String? type,
    String? search,
  });

  Future<ProductModel> getById(String id);

  Future<ProductModel> create({
    required String orgId,
    required ProductModel product,
  });

  Future<ProductModel> update(ProductModel product);

  Future<void> delete(String id);

  Future<ProductModel> publish(String id);

  Future<ProductModel> archive(String id);
}

class ProductRemoteDatasourceImpl implements ProductRemoteDatasource {
  final Dio _dio;

  const ProductRemoteDatasourceImpl({required Dio dio}) : _dio = dio;

  @override
  Future<List<ProductModel>> getAll({
    required String orgId,
    int page = 1,
    int perPage = 25,
    String? status,
    String? type,
    String? search,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'per_page': perPage,
        if (status != null) 'status': status,
        if (type != null) 'type': type,
        if (search != null && search.isNotEmpty) 'search': search,
      };

      final response = await _dio.get(
        '/api/v1/commerce/orgs/$orgId/products',
        queryParameters: queryParams,
      );

      final data = response.data;
      final List<dynamic> items = data is Map<String, dynamic>
          ? (data['data'] as List<dynamic>? ?? [])
          : (data as List<dynamic>? ?? []);

      return items
          .map((json) => ProductModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ServerException(
        message: e.response?.data?['message'] as String? ?? 'Failed to fetch products',
        statusCode: e.response?.statusCode,
      );
    }
  }

  @override
  Future<ProductModel> getById(String id) async {
    try {
      final response = await _dio.get('/api/v1/commerce/products/$id');
      return ProductModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(
        message: e.response?.data?['message'] as String? ?? 'Failed to fetch product',
        statusCode: e.response?.statusCode,
      );
    }
  }

  @override
  Future<ProductModel> create({
    required String orgId,
    required ProductModel product,
  }) async {
    try {
      final response = await _dio.post(
        '/api/v1/commerce/orgs/$orgId/products',
        data: product.toCreateJson(),
      );
      return ProductModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(
        message: e.response?.data?['message'] as String? ?? 'Failed to create product',
        statusCode: e.response?.statusCode,
      );
    }
  }

  @override
  Future<ProductModel> update(ProductModel product) async {
    try {
      final response = await _dio.patch(
        '/api/v1/commerce/products/${product.id}',
        data: product.toUpdateJson(),
      );
      return ProductModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(
        message: e.response?.data?['message'] as String? ?? 'Failed to update product',
        statusCode: e.response?.statusCode,
      );
    }
  }

  @override
  Future<void> delete(String id) async {
    try {
      await _dio.delete('/api/v1/commerce/products/$id');
    } on DioException catch (e) {
      throw ServerException(
        message: e.response?.data?['message'] as String? ?? 'Failed to delete product',
        statusCode: e.response?.statusCode,
      );
    }
  }

  @override
  Future<ProductModel> publish(String id) async {
    try {
      final response = await _dio.post(
        '/api/v1/commerce/products/$id/publish',
      );
      // API returns { message, product: { status: "active" } }
      final productData = response.data['product'] as Map<String, dynamic>?;
      if (productData != null && productData.containsKey('name')) {
        return ProductModel.fromJson(productData);
      }
      // If API only returns partial data, re-fetch the full product
      return getById(id);
    } on DioException catch (e) {
      throw ServerException(
        message: e.response?.data?['message'] as String? ?? 'Failed to publish product',
        statusCode: e.response?.statusCode,
      );
    }
  }

  @override
  Future<ProductModel> archive(String id) async {
    try {
      final response = await _dio.post(
        '/api/v1/commerce/products/$id/archive',
      );
      final productData = response.data['product'] as Map<String, dynamic>?;
      if (productData != null && productData.containsKey('name')) {
        return ProductModel.fromJson(productData);
      }
      return getById(id);
    } on DioException catch (e) {
      throw ServerException(
        message: e.response?.data?['message'] as String? ?? 'Failed to archive product',
        statusCode: e.response?.statusCode,
      );
    }
  }
}
