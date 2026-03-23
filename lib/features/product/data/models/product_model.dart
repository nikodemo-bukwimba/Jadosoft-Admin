import '../../domain/entities/product_entity.dart';
import '../../domain/value_objects/product_status.dart';

/// Data model for [ProductEntity].
///
/// Handles JSON serialization/deserialization for the Nexora Commerce
/// Products API. On read, extracts price from the first (default) variant.
/// On create, wraps the single price field into a default variant payload.
class ProductModel extends ProductEntity {
  const ProductModel({
    required super.id,
    required super.name,
    super.description,
    super.type,
    required super.sellerActorId,
    super.categoryId,
    super.categoryName,
    required super.price,
    super.currency,
    super.sku,
    super.imageUrl,
    super.imageUrls,
    super.status,
    super.isFeatured,
    super.isNew,
    super.isAvailable,
    super.trackInventory,
    super.requiresConfirmation,
    super.defaultVariantId,
    super.createdAt,
    super.updatedAt,
  });

  /// Deserializes a product from the API JSON response.
  ///
  /// The API returns variants as an array. We extract the base_price
  /// and currency from the first (default) variant.
  factory ProductModel.fromJson(Map<String, dynamic> json) {
    // Extract price from default variant
    double price = 0.0;
    String currency = 'TZS';
    String? sku;
    String? defaultVariantId;

    final variants = json['variants'] as List<dynamic>?;
    if (variants != null && variants.isNotEmpty) {
      final defaultVariant = variants.first as Map<String, dynamic>;
      price = _parseDouble(defaultVariant['base_price']);
      currency = defaultVariant['currency'] as String? ?? 'TZS';
      sku = defaultVariant['sku'] as String?;
      defaultVariantId = defaultVariant['id'] as String?;
    }

    // Extract image URLs from media/attributes
    final imageUrls = <String>[];
    String? imageUrl;
    final media = json['media'] as List<dynamic>?;
    if (media != null) {
      for (final item in media) {
        if (item is Map<String, dynamic>) {
          final url = item['url'] as String?;
          if (url != null) imageUrls.add(url);
        } else if (item is String) {
          imageUrls.add(item);
        }
      }
    }
    if (imageUrls.isNotEmpty) imageUrl = imageUrls.first;

    // Fallback: check top-level image_url
    imageUrl ??= json['image_url'] as String?;

    // Parse category
    String? categoryId;
    String? categoryName;
    final category = json['category'];
    if (category is Map<String, dynamic>) {
      categoryId = category['id'] as String?;
      categoryName = category['name'] as String?;
    } else {
      categoryId = json['category_id'] as String?;
    }

    return ProductModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      type: ProductType.fromString(json['type'] as String? ?? 'physical'),
      sellerActorId: json['seller_actor_id'] as String? ?? '',
      categoryId: categoryId,
      categoryName: categoryName,
      price: price,
      currency: currency,
      sku: sku,
      imageUrl: imageUrl,
      imageUrls: imageUrls,
      status: ProductStatus.fromString(json['status'] as String? ?? 'draft'),
      isFeatured: json['is_featured'] as bool? ?? false,
      isNew: _isNewProduct(json['created_at']),
      isAvailable: json['is_available'] as bool? ?? true,
      trackInventory: json['track_inventory'] as bool? ?? false,
      requiresConfirmation: json['requires_confirmation'] as bool? ?? false,
      defaultVariantId: defaultVariantId,
      createdAt: _parseDateTime(json['created_at']),
      updatedAt: _parseDateTime(json['updated_at']),
    );
  }

  /// Converts to JSON for product creation.
  /// Wraps [price] and [currency] into a default variant.
  Map<String, dynamic> toCreateJson() {
    return {
      'name': name,
      'type': type.name,
      'seller_actor_id': sellerActorId,
      if (description != null && description!.isNotEmpty)
        'description': description,
      'requires_confirmation': requiresConfirmation,
      'track_inventory': trackInventory,
      'variants': [
        {
          'base_price': price,
          'currency': currency,
          if (sku != null && sku!.isNotEmpty) 'sku': sku,
          'name': 'Default',
        },
      ],
      if (categoryId != null) 'category_id': categoryId,
    };
  }

  /// Converts to JSON for product update (PATCH).
  /// Does not include variants — use variant-specific endpoints.
  Map<String, dynamic> toUpdateJson() {
    return {
      'name': name,
      if (description != null) 'description': description,
      'requires_confirmation': requiresConfirmation,
      'track_inventory': trackInventory,
    };
  }

  /// Creates a [ProductModel] from a [ProductEntity].
  factory ProductModel.fromEntity(ProductEntity entity) {
    return ProductModel(
      id: entity.id,
      name: entity.name,
      description: entity.description,
      type: entity.type,
      sellerActorId: entity.sellerActorId,
      categoryId: entity.categoryId,
      categoryName: entity.categoryName,
      price: entity.price,
      currency: entity.currency,
      sku: entity.sku,
      imageUrl: entity.imageUrl,
      imageUrls: entity.imageUrls,
      status: entity.status,
      isFeatured: entity.isFeatured,
      isNew: entity.isNew,
      isAvailable: entity.isAvailable,
      trackInventory: entity.trackInventory,
      requiresConfirmation: entity.requiresConfirmation,
      defaultVariantId: entity.defaultVariantId,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  /// A product is considered "new" if created within the last 14 days.
  static bool _isNewProduct(dynamic createdAt) {
    final dt = _parseDateTime(createdAt);
    if (dt == null) return false;
    return DateTime.now().difference(dt).inDays <= 14;
  }
}
