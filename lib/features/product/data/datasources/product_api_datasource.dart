//Admin app

// lib/features/product/data/datasources/product_api_datasource.dart
//
// MODIFICATION vs original:
//   _fromNexora() now reads the four promotion virtual attributes that
//   PromotionPricingService sets on each variant when the Nexora API
//   returns products via /commerce/orgs/{orgId}/products:
//
//     effective_price     → ProductEntity.effectivePrice
//     discount_percentage → ProductEntity.discountPercentage
//     has_promotion       → ProductEntity.hasPromotion
//     promotion_id        → ProductEntity.promotionId
//
// All other logic is unchanged.
// ─────────────────────────────────────────────────────────────

import 'package:dio/dio.dart';
import '../../../../core/context/org_context.dart';
import '../../../../core/error/exceptions.dart';
import '../models/product_model.dart';
import 'product_remote_datasource.dart';

class ProductApiDataSource implements ProductRemoteDataSource {
  final Dio _dio;
  final OrgContext _orgContext;

  ProductApiDataSource({required Dio dio, required OrgContext orgContext})
    : _dio = dio,
      _orgContext = orgContext;

  // ── Error helper ───────────────────────────────────────────

  String _msg(DioException e) {
    final data = e.response?.data;
    if (data is Map<String, dynamic> && data['message'] is String) {
      return data['message'] as String;
    }
    return 'An error occurred. Please try again.';
  }

  // ── Response unwrapper ─────────────────────────────────────

  Map<String, dynamic> _unwrapProduct(dynamic raw) {
    if (raw is Map<String, dynamic>) {
      if (raw.containsKey('product')) {
        return raw['product'] as Map<String, dynamic>;
      }
      if (raw.containsKey('data') && raw['data'] is Map) {
        return raw['data'] as Map<String, dynamic>;
      }
      return raw;
    }
    return {};
  }

  // ── Nexora JSON → ProductModel ─────────────────────────────
  //
  // CHANGE (promotion fields):
  //   After resolving basePrice from the default variant, we also read
  //   the four promotion virtual attributes that the backend
  //   PromotionPricingService sets on the variant object.
  //
  //   Reading at variant level (not product root) because that is where
  //   the backend sets them — they are per-variant values.

  ProductModel _fromNexora(Map<String, dynamic> j) {
    final variants =
        (j['variants'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final defaultVariant = variants.isEmpty
        ? null
        : variants.firstWhere(
            (v) => v['is_default'] == true,
            orElse: () => variants.first,
          );

    // ── Variant ID — needed by basket endpoint ─────────────────
    final variantId = defaultVariant?['id']?.toString();

    // ── Base price ─────────────────────────────────────────────
    final rawPrice = defaultVariant?['base_price'];
    final price = rawPrice == null
        ? 0.0
        : double.tryParse(rawPrice.toString()) ?? 0.0;

    // ── Promotion pricing (NEW) ────────────────────────────────
    // These four fields are set by PromotionPricingService on the server.
    // Fall back gracefully: effectivePrice = price when not present.
    final rawEffective = defaultVariant?['effective_price'];
    final effectivePrice = rawEffective == null
        ? price
        : double.tryParse(rawEffective.toString()) ?? price;

    final discountPercentage = (defaultVariant?['discount_percentage'] as num?)
        ?.toDouble();

    final hasPromotion = defaultVariant?['has_promotion'] as bool? ?? false;

    final promotionId = defaultVariant?['promotion_id'] as String?;

    // ── Metadata / attributes ───────────────────────────────────
    final meta = (j['metadata'] as Map<String, dynamic>?) ?? {};
    final attrs = (j['attributes'] as Map<String, dynamic>?) ?? {};
    final categoryId =
        (attrs['category_id'] ?? meta['category_id'])?.toString() ?? '';

    bool parseBool(dynamic v, bool fallback) {
      if (v == null) return fallback;
      if (v is bool) return v;
      if (v is int) return v == 1;
      final s = v.toString().toLowerCase();
      return s == 'true' || s == '1';
    }

    return ProductModel(
      id: j['id']?.toString() ?? '',
      variantId: variantId,
      name: j['name']?.toString() ?? '',
      description: j['description']?.toString(),
      price: price,
      // ── Promotion fields (NEW) ────────────────────────────────
      effectivePrice: effectivePrice,
      discountPercentage: discountPercentage,
      hasPromotion: hasPromotion,
      promotionId: promotionId,
      // ─────────────────────────────────────────────────────────
      categoryId: categoryId,
      isAvailable: parseBool(meta['is_available'], j['status'] == 'active'),
      isFeatured: parseBool(meta['is_featured'], false),
      isNew: parseBool(meta['is_new'], false),
      status: _mapStatus(j['status']?.toString() ?? 'draft'),
      imageUrl: _resolveImage(j, meta),
      createdAt: j['created_at'] != null
          ? DateTime.tryParse(j['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      batchNumber: meta['batch_number']?.toString(),
      expiryDate: meta['expiry_date'] != null
          ? DateTime.tryParse(meta['expiry_date'].toString())
          : null,
      packSize: meta['pack_size']?.toString(),
      quantityAvailable: meta['quantity_available'] != null
          ? int.tryParse(meta['quantity_available'].toString())
          : null,
    );
  }

  String _mapStatus(String s) => switch (s) {
    'active' => 'active',
    'archived' || 'suspended' => 'archived',
    _ => 'draft',
  };

  String? _resolveImage(Map<String, dynamic> j, Map<String, dynamic> meta) {
    final media = (j['media'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    if (media.isNotEmpty) return media.first['url'] as String?;
    return meta['image_url'] as String? ?? j['image_url'] as String?;
  }

  // ── ProductModel data → Nexora create body ─────────────────

  Map<String, dynamic> _createBody(Map<String, dynamic> d) => {
    'name': d['name'] ?? '',
    'description': d['description'],
    'type': 'physical',
    'seller_actor_id': d['seller_actor_id'] ?? '',
    'track_inventory': true,
    'requires_confirmation': false,
    'attributes': {'category_id': d['category_id'] ?? ''},
    'metadata': {
      'category_id': d['category_id'] ?? '',
      'is_available': d['is_available'] ?? true,
      'is_featured': d['is_featured'] ?? false,
      'is_new': d['is_new'] ?? true,
      if (d['image_url'] != null) 'image_url': d['image_url'],
      if (d['batch_number'] != null) 'batch_number': d['batch_number'],
      if (d['expiry_date'] != null) 'expiry_date': d['expiry_date'],
      if (d['pack_size'] != null) 'pack_size': d['pack_size'],
      if (d['quantity_available'] != null)
        'quantity_available': d['quantity_available'],
    },
    'variants': [
      {
        'base_price': d['price'] ?? 0,
        'currency': 'TZS',
        'name': d['name'] ?? 'Default',
        'is_default': true,
      },
    ],
  };

  Map<String, dynamic> _updateBody(Map<String, dynamic> d) => {
    'name': d['name'] ?? '',
    'description': d['description'],
    'attributes': {'category_id': d['category_id'] ?? ''},
    'metadata': {
      'category_id': d['category_id'] ?? '',
      'is_available': d['is_available'] ?? true,
      'is_featured': d['is_featured'] ?? false,
      'is_new': d['is_new'] ?? true,
      if (d['image_url'] != null) 'image_url': d['image_url'],
      if (d['batch_number'] != null) 'batch_number': d['batch_number'],
      if (d['expiry_date'] != null) 'expiry_date': d['expiry_date'],
      if (d['pack_size'] != null) 'pack_size': d['pack_size'],
      if (d['quantity_available'] != null)
        'quantity_available': d['quantity_available'],
    },
  };

  // ── ProductRemoteDataSource interface ──────────────────────

  @override
  Future<List<ProductModel>> getAll() async {
    try {
      final orgId = _orgContext.requireRootOrgId();
      final res = await _dio.get(
        '/commerce/orgs/$orgId/products',
        queryParameters: {'per_page': 100},
      );
      final raw = res.data;
      final List<dynamic> items = raw is Map
          ? (raw['data'] ?? raw['products'] ?? []) as List
          : raw as List;
      return items.cast<Map<String, dynamic>>().map(_fromNexora).toList();
    } on DioException catch (e) {
      throw ServerException(_msg(e), statusCode: e.response?.statusCode);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<ProductModel> getById(String id, {String? orgId}) async {
    try {
      // Pass requesting org so backend includes branch-specific promotions.
      final effectiveOrgId = orgId ?? _orgContext.effectiveOrgId;
      final res = await _dio.get(
        '/commerce/products/$id',
        queryParameters: {'org_id': effectiveOrgId},
      );
      return _fromNexora(_unwrapProduct(res.data));
    } on DioException catch (e) {
      throw ServerException(_msg(e), statusCode: e.response?.statusCode);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<ProductModel> create(Map<String, dynamic> data) async {
    try {
      final orgId = _orgContext.requireRootOrgId();
      final res = await _dio.post(
        '/commerce/orgs/$orgId/products',
        data: _createBody(data),
      );
      return _fromNexora(_unwrapProduct(res.data));
    } on DioException catch (e) {
      throw ServerException(_msg(e), statusCode: e.response?.statusCode);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<ProductModel> update(String id, Map<String, dynamic> data) async {
    try {
      final newStatus = data['status']?.toString();

      if (newStatus == 'active') {
        await _dio.post('/commerce/products/$id/publish');
      } else if (newStatus == 'archived') {
        await _dio.post('/commerce/products/$id/archive');
      } else {
        await _dio.patch('/commerce/products/$id', data: _updateBody(data));
      }

      return await getById(id);
    } on DioException catch (e) {
      throw ServerException(_msg(e), statusCode: e.response?.statusCode);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> delete(String id) async {
    try {
      await _dio.post('/commerce/products/$id/archive');
    } on DioException catch (e) {
      if (e.response?.statusCode == 404 || e.response?.statusCode == 422) {
        return;
      }
      throw ServerException(_msg(e), statusCode: e.response?.statusCode);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }
}
