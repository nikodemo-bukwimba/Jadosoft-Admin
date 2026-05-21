// lib/features/product/data/datasources/product_api_datasource.dart

import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform;
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

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

  String _msg(DioException e) {
    final data = e.response?.data;
    if (data is Map<String, dynamic> && data['message'] is String) {
      return data['message'] as String;
    }
    return 'An error occurred. Please try again.';
  }

  Map<String, dynamic> _unwrapProduct(dynamic raw) {
    if (raw is Map<String, dynamic>) {
      if (raw.containsKey('product'))
        return raw['product'] as Map<String, dynamic>;
      if (raw.containsKey('data') && raw['data'] is Map)
        return raw['data'] as Map<String, dynamic>;
      return raw;
    }
    return {};
  }

  ProductModel _fromNexora(Map<String, dynamic> j) {
    final variants =
        (j['variants'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final defaultVariant = variants.isEmpty
        ? null
        : variants.firstWhere(
            (v) => v['is_default'] == true,
            orElse: () => variants.first,
          );

    final variantId = defaultVariant?['id']?.toString();
    final rawPrice = defaultVariant?['base_price'];
    final price = rawPrice == null
        ? 0.0
        : double.tryParse(rawPrice.toString()) ?? 0.0;
    final rawEffective = defaultVariant?['effective_price'];
    final effectivePrice = rawEffective == null
        ? price
        : double.tryParse(rawEffective.toString()) ?? price;
    final discountPercentage = (defaultVariant?['discount_percentage'] as num?)
        ?.toDouble();
    final hasPromotion = defaultVariant?['has_promotion'] as bool? ?? false;
    final promotionId = defaultVariant?['promotion_id'] as String?;

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
      effectivePrice: effectivePrice,
      discountPercentage: discountPercentage,
      hasPromotion: hasPromotion,
      promotionId: promotionId,
      categoryId: categoryId,
      isAvailable: parseBool(meta['is_available'], j['status'] == 'active'),
      isFeatured: parseBool(meta['is_featured'], false),
      isNew: parseBool(meta['is_new'], false),
      status: _mapStatus(j['status']?.toString() ?? 'draft'),
      imageUrl: _resolveImage(j),
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

  String? _resolveImage(Map<String, dynamic> j) {
    final media = (j['media'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    if (media.isEmpty) return null;
    final primary = media.firstWhere(
      (m) => m['is_primary'] == true,
      orElse: () => media.first,
    );
    return primary['url'] as String?;
  }

  Map<String, dynamic> _createBody(Map<String, dynamic> d) {
    final imageUrl = d['image_url'] as String?;
    return {
      'name': d['name'] ?? '',
      'description': d['description'],
      'type': 'physical',
      'seller_actor_id': d['seller_actor_id'] ?? '',
      'track_inventory': true,
      'requires_confirmation': false,
      'attributes': {'category_id': d['category_id'] ?? ''},
      if (imageUrl != null && imageUrl.isNotEmpty)
        'media': [
          {'url': imageUrl, 'type': 'image', 'is_primary': true},
        ],
      'metadata': {
        'category_id': d['category_id'] ?? '',
        'is_available': d['is_available'] ?? true,
        'is_featured': d['is_featured'] ?? false,
        'is_new': d['is_new'] ?? true,
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
  }

  Map<String, dynamic> _updateBody(Map<String, dynamic> d) {
    final imageUrl = d['image_url'] as String?;
    return {
      'name': d['name'] ?? '',
      'description': d['description'],
      'attributes': {'category_id': d['category_id'] ?? ''},
      if (imageUrl != null && imageUrl.isNotEmpty)
        'media': [
          {'url': imageUrl, 'type': 'image', 'is_primary': true},
        ],
      'metadata': {
        'category_id': d['category_id'] ?? '',
        'is_available': d['is_available'] ?? true,
        'is_featured': d['is_featured'] ?? false,
        'is_new': d['is_new'] ?? true,
        if (d['batch_number'] != null) 'batch_number': d['batch_number'],
        if (d['expiry_date'] != null) 'expiry_date': d['expiry_date'],
        if (d['pack_size'] != null) 'pack_size': d['pack_size'],
        if (d['quantity_available'] != null)
          'quantity_available': d['quantity_available'],
      },
    };
  }

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

      // ── Patch product-level fields ─────────────────────────────
      await _dio.patch('/commerce/products/$id', data: _updateBody(data));

      // ── Patch variant price if provided ────────────────────────
      final variantId = data['variant_id']?.toString();
      final newPrice = data['price'];
      if (variantId != null && variantId.isNotEmpty && newPrice != null) {
        await _dio.patch(
          '/commerce/variants/$variantId',
          data: {'base_price': newPrice, 'currency': data['currency'] ?? 'TZS'},
        );
      }

      // ── Status transitions ─────────────────────────────────────
      if (newStatus == 'active') {
        await _dio.post('/commerce/products/$id/publish');
      } else if (newStatus == 'archived') {
        await _dio.post('/commerce/products/$id/archive');
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
      if (e.response?.statusCode == 404 || e.response?.statusCode == 422)
        return;
      throw ServerException(_msg(e), statusCode: e.response?.statusCode);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  // ── Image upload ─────────────────────────────────────────────
  //
  // Desktop (Windows/macOS/Linux): file_picker returns the raw uncompressed
  // file — a typical photo can be 5–15 MB, exceeding PHP's default
  // post_max_size of 8 MB.  We compress with the `image` package before
  // sending: resize to fit within 1200 px, re-encode as JPEG @ 85 quality.
  // This brings most photos under 500 KB.
  //
  // Mobile: image_picker already applies maxWidth/maxHeight/imageQuality,
  // so no further compression is needed.

  static bool get _isDesktop =>
      defaultTargetPlatform == TargetPlatform.windows ||
      defaultTargetPlatform == TargetPlatform.macOS ||
      defaultTargetPlatform == TargetPlatform.linux;

  static const int _maxDimension = 1200;
  static const int _jpegQuality = 85;

  @override
  Future<String> uploadImage(String localPath) async {
    try {
      final file = File(localPath);
      if (!await file.exists()) {
        throw ServerException('Image file not found at: $localPath');
      }

      String uploadPath = localPath;
      String uploadName = p.basename(localPath);

      // Compress on desktop before sending
      if (_isDesktop) {
        final compressed = await _compressForDesktop(file);
        if (compressed != null) {
          uploadPath = compressed.path;
          uploadName = p.basename(compressed.path);
        }
      }

      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(uploadPath, filename: uploadName),
        'type': 'product',
      });

      final res = await _dio.post('/media/upload', data: formData);
      final url = res.data?['url'] as String?;

      if (url == null || url.isEmpty) {
        throw const ServerException(
          'Upload succeeded but server returned no URL.',
        );
      }

      return url;
    } on DioException catch (e) {
      throw ServerException(
        'Image upload failed: ${_msg(e)}',
        statusCode: e.response?.statusCode,
      );
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException('Image upload error: $e');
    }
  }

  /// Decodes [source], resizes to fit [_maxDimension] on the longest axis,
  /// and re-encodes as JPEG at [_jpegQuality].  Writes to a temp file.
  /// Returns null on any error so the caller can fall back to the original.
  Future<File?> _compressForDesktop(File source) async {
    try {
      final bytes = await source.readAsBytes();
      final decoded = img.decodeImage(bytes);
      if (decoded == null) return null;

      img.Image resized = decoded;
      if (decoded.width > _maxDimension || decoded.height > _maxDimension) {
        resized = img.copyResize(
          decoded,
          width: decoded.width >= decoded.height ? _maxDimension : -1,
          height: decoded.height > decoded.width ? _maxDimension : -1,
          interpolation: img.Interpolation.linear,
        );
      }

      final Uint8List jpegBytes = Uint8List.fromList(
        img.encodeJpg(resized, quality: _jpegQuality),
      );

      final tempDir = await getTemporaryDirectory();
      final tempFile = File(
        p.join(
          tempDir.path,
          'upload_${DateTime.now().millisecondsSinceEpoch}.jpg',
        ),
      );
      await tempFile.writeAsBytes(jpegBytes);
      return tempFile;
    } catch (_) {
      return null; // fall back to original file
    }
  }
}
