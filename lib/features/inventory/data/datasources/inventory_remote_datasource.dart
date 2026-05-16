// lib/features/inventory/data/datasources/inventory_remote_datasource.dart

import 'package:dio/dio.dart';
import '../../../../core/context/org_context.dart';
import '../../../../core/error/exceptions.dart';
import '../models/inventory_model.dart';

abstract class InventoryRemoteDataSource {
  Future<List<WarehouseModel>> getWarehouses(String orgId);
  Future<WarehouseModel> createWarehouse(
      String orgId, Map<String, dynamic> data);
  Future<List<InventoryBatchModel>> getBatches(
    String orgId, {
    String? warehouseId,
    String? productId,
    String? variantId,
    String? status,
  });
  Future<InventoryBatchModel> receiveStock(
      String warehouseId, Map<String, dynamic> data);
  Future<VariantStockModel> getVariantStock(String orgId, String variantId);
}

class InventoryRemoteDataSourceImpl implements InventoryRemoteDataSource {
  final Dio _dio;
  final OrgContext _orgContext;

  InventoryRemoteDataSourceImpl({
    required Dio dio,
    required OrgContext orgContext,
  })  : _dio = dio,
        _orgContext = orgContext;

  String _msg(DioException e) {
    final data = e.response?.data;
    if (data is Map<String, dynamic> && data['message'] is String) {
      return data['message'] as String;
    }
    return 'An error occurred. Please try again.';
  }

  List<T> _unwrapList<T>(dynamic raw, T Function(Map<String, dynamic>) fromJson,
      String key) {
    final List items =
        raw is Map ? ((raw[key] ?? raw['data'] ?? []) as List) : raw as List;
    return items.cast<Map<String, dynamic>>().map(fromJson).toList();
  }

  Map<String, dynamic> _unwrapSingle(dynamic raw, String key) {
    if (raw is Map<String, dynamic>) {
      return (raw[key] ?? raw['data'] ?? raw) as Map<String, dynamic>;
    }
    return raw as Map<String, dynamic>;
  }

  @override
  Future<List<WarehouseModel>> getWarehouses(String orgId) async {
    try {
      final res = await _dio.get('/inventory/orgs/$orgId/warehouses',
          queryParameters: {'per_page': 100});
      return _unwrapList(res.data, WarehouseModel.fromJson, 'warehouses');
    } on DioException catch (e) {
      throw ServerException(_msg(e), statusCode: e.response?.statusCode);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<WarehouseModel> createWarehouse(
      String orgId, Map<String, dynamic> data) async {
    try {
      final res =
          await _dio.post('/inventory/orgs/$orgId/warehouses', data: data);
      return WarehouseModel.fromJson(_unwrapSingle(res.data, 'warehouse'));
    } on DioException catch (e) {
      throw ServerException(_msg(e), statusCode: e.response?.statusCode);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<List<InventoryBatchModel>> getBatches(
    String orgId, {
    String? warehouseId,
    String? productId,
    String? variantId,
    String? status,
  }) async {
    try {
      final res = await _dio.get(
        '/inventory/orgs/$orgId/batches',
        queryParameters: {
          'per_page': 100,
          if (warehouseId != null) 'warehouse_id': warehouseId,
          if (productId != null) 'product_id': productId,
          if (variantId != null) 'variant_id': variantId,
          if (status != null) 'status': status,
        },
      );
      return _unwrapList(res.data, InventoryBatchModel.fromJson, 'batches');
    } on DioException catch (e) {
      throw ServerException(_msg(e), statusCode: e.response?.statusCode);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<InventoryBatchModel> receiveStock(
      String warehouseId, Map<String, dynamic> data) async {
    try {
      final res = await _dio.post(
          '/inventory/warehouses/$warehouseId/receive',
          data: data);
      return InventoryBatchModel.fromJson(
          _unwrapSingle(res.data, 'batch'));
    } on DioException catch (e) {
      throw ServerException(_msg(e), statusCode: e.response?.statusCode);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<VariantStockModel> getVariantStock(
      String orgId, String variantId) async {
    try {
      final res = await _dio
          .get('/inventory/orgs/$orgId/variants/$variantId/stock');
      return VariantStockModel.fromJson(
          res.data is Map<String, dynamic> ? res.data as Map<String, dynamic> : {});
    } on DioException catch (e) {
      throw ServerException(_msg(e), statusCode: e.response?.statusCode);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }
}