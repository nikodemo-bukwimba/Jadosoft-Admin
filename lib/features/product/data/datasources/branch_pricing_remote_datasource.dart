// lib/features/product/data/datasources/branch_pricing_remote_datasource.dart
//Admin app overriding price setting...

import 'package:dio/dio.dart';
import '../../../../core/error/exceptions.dart';
import '../models/branch_variant_price_model.dart';

// ── Abstract interface ──────────────────────────────────────────────────────

abstract class BranchPricingRemoteDataSource {
  Future<List<BranchVariantPriceModel>> listOverrides(String orgId);

  Future<BranchVariantPriceModel> setOverride({
    required String orgId,
    required String variantId,
    required double price,
    String currency,
  });

  Future<void> removeOverride({
    required String orgId,
    required String variantId,
  });
}

// ── Dio implementation ──────────────────────────────────────────────────────

class BranchPricingApiDataSource implements BranchPricingRemoteDataSource {
  final Dio _dio;

  BranchPricingApiDataSource({required Dio dio}) : _dio = dio;

  String _msg(DioException e) {
    final data = e.response?.data;
    if (data is Map<String, dynamic> && data['message'] is String) {
      return data['message'] as String;
    }
    return 'An error occurred. Please try again.';
  }

  @override
  Future<List<BranchVariantPriceModel>> listOverrides(String orgId) async {
    try {
      final res = await _dio.get('/commerce/orgs/$orgId/branch-prices');
      final raw = res.data;
      final List<dynamic> items = raw is Map
          ? ((raw['data'] ?? raw['overrides'] ?? []) as List)
          : (raw as List);
      return items
          .cast<Map<String, dynamic>>()
          .map(BranchVariantPriceModel.fromJson)
          .toList();
    } on DioException catch (e) {
      throw ServerException(_msg(e), statusCode: e.response?.statusCode);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<BranchVariantPriceModel> setOverride({
    required String orgId,
    required String variantId,
    required double price,
    String currency = 'TZS',
  }) async {
    try {
      final res = await _dio.put(
        '/commerce/orgs/$orgId/variants/$variantId/price',
        data: {'price': price, 'currency': currency},
      );
      final raw = res.data;
      final json = raw is Map<String, dynamic>
          ? (raw['override'] as Map<String, dynamic>? ?? raw)
          : raw as Map<String, dynamic>;
      return BranchVariantPriceModel.fromJson(json);
    } on DioException catch (e) {
      throw ServerException(_msg(e), statusCode: e.response?.statusCode);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> removeOverride({
    required String orgId,
    required String variantId,
  }) async {
    try {
      await _dio.delete('/commerce/orgs/$orgId/variants/$variantId/price');
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return;
      throw ServerException(_msg(e), statusCode: e.response?.statusCode);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }
}