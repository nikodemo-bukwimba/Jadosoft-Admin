// Admin app product api datasource
// 
// product_api_datasource.dart
// ─────────────────────────────────────────────────────────────
// Nexora Commerce Products API implementation.
// Implements the original ProductRemoteDataSource interface unchanged.
// All existing Maishell files are untouched — this is a NEW file only.
//
// Endpoints used:
//   GET    /api/v1/commerce/orgs/{orgId}/products
//   POST   /api/v1/commerce/orgs/{orgId}/products
//   GET    /api/v1/commerce/products/{id}
//   PATCH  /api/v1/commerce/products/{id}
//   POST   /api/v1/commerce/products/{id}/archive  (no hard DELETE in Nexora)
//
// OrgContext usage:
//   Products catalog is org-level (root org owns all products).
//   → Always uses requireRootOrgId() — never effectiveOrgId.
//
// Field mapping:
//   price        → variants[default].base_price
//   categoryId   → attributes.category_id + metadata.category_id
//   isAvailable  → metadata.is_available
//   isFeatured   → metadata.is_featured  (local concept — no Nexora equivalent)
//   isNew        → metadata.is_new
//   imageUrl     → media[0].url  OR  metadata.image_url (fallback)
//   status       → draft·active·archived (suspended → archived)
//
// NOTE on seller_actor_id:
//   Required by Nexora on create. Must be passed in the data map by the
//   caller. Pass it from the active auth session actor id at the form layer.
//   The form page should inject AuthBloc and read:
//     (context.read<AuthBloc>().state as AuthAuthenticated)
//       .activeSession.user.actorId
//   then include it in CreateProductParams / data map.
//
// To activate — in injection_container.dart:
//   ADD import:
//     import 'package:admin_panel/features/product/data/datasources/product_api_datasource.dart';
//
//   REPLACE (in Products section):
//     sl.registerLazySingleton<ProductRemoteDataSource>(
//       () => ProductMockDataSource(),
//     );
//   WITH:
//     sl.registerLazySingleton<ProductRemoteDataSource>(
//       () => ProductApiDataSource(dio: sl(), orgContext: sl()),
//     );
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

  ProductModel _fromNexora(Map<String, dynamic> j) {
    final variants =
        (j['variants'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final defaultVariant = variants.isEmpty
        ? null
        : variants.firstWhere(
            (v) => v['is_default'] == true,
            orElse: () => variants.first,
          );

    // ── Capture variant ID — this is what the basket endpoint needs ──
    final variantId = defaultVariant?['id']?.toString();

    final rawPrice = defaultVariant?['base_price'];
    final price = rawPrice == null
        ? 0.0
        : double.tryParse(rawPrice.toString()) ?? 0.0;

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
      variantId: variantId, // ← stored now
      name: j['name']?.toString() ?? '',
      description: j['description']?.toString(),
      price: price,
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
      // Products catalog is org-level — always root org id
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
  Future<ProductModel> getById(String id) async {
    try {
      final res = await _dio.get('/commerce/products/$id');
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
      // Products catalog is org-level — always root org id
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
      // Update product metadata only — no variant price patch (endpoint doesn't exist)
      await _dio.patch('/commerce/products/$id', data: _updateBody(data));

      // Re-fetch to return accurate state
      return await getById(id);
    } on DioException catch (e) {
      throw ServerException(_msg(e), statusCode: e.response?.statusCode);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  /// Patches the default variant base_price. Non-fatal if it fails —
  /// the product metadata update already succeeded.
  // Future<void> _updateVariantPrice(String productId, double price) async {
  //   try {
  //     final res = await _dio.get('/commerce/products/$productId');
  //     final productData = _unwrapProduct(res.data);
  //     final variants =
  //         (productData['variants'] as List?)?.cast<Map<String, dynamic>>() ??
  //         [];
  //     if (variants.isEmpty) return;
  //     final defaultVariant = variants.firstWhere(
  //       (v) => v['is_default'] == true,
  //       orElse: () => variants.first,
  //     );
  //     final variantId = defaultVariant['id']?.toString();
  //     if (variantId == null || variantId.isEmpty) return;
  //     await _dio.patch(
  //       '/commerce/products/$productId/variants/$variantId',
  //       data: {'base_price': price},
  //     );
  //   } catch (_) {
  //     // Non-fatal
  //   }
  // }

  @override
  Future<void> delete(String id) async {
    // Nexora Commerce has no hard DELETE for products.
    // Archive is the equivalent operation (active → archived).
    try {
      await _dio.post('/commerce/products/$id/archive');
    } on DioException catch (e) {
      // 404 = already gone, 422 = already archived → treat as success
      if (e.response?.statusCode == 404 || e.response?.statusCode == 422) {
        return;
      }
      throw ServerException(_msg(e), statusCode: e.response?.statusCode);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }
}
