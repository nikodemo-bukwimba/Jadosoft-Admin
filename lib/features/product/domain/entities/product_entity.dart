import 'package:equatable/equatable.dart';

import '../value_objects/product_status.dart';

/// Product types supported by the Nexora Commerce API.
enum ProductType {
  physical,
  service,
  digital,
  bundle;

  String get label {
    switch (this) {
      case ProductType.physical:
        return 'Physical';
      case ProductType.service:
        return 'Service';
      case ProductType.digital:
        return 'Digital';
      case ProductType.bundle:
        return 'Bundle';
    }
  }

  static ProductType fromString(String value) {
    return ProductType.values.firstWhere(
      (t) => t.name == value.toLowerCase(),
      orElse: () => ProductType.physical,
    );
  }
}

/// Domain entity for a product in the Barick Pharmacy admin system.
///
/// Maps to the Nexora Commerce Products API. The API requires at least
/// one variant per product; this entity exposes a single [price] field
/// which the data layer wraps into a default variant on create/update.
///
/// [isFeatured], [isNew], and [isAvailable] are client-side boolean
/// overlay flags — they are NOT part of the status machine.
///
/// Status machine: draft → active → archived
class ProductEntity extends Equatable {
  final String id;
  final String name;
  final String? description;
  final ProductType type;
  final String sellerActorId;
  final String? categoryId;
  final String? categoryName;
  final double price;
  final String currency;
  final String? sku;
  final String? imageUrl;
  final List<String> imageUrls;
  final ProductStatus status;
  final bool isFeatured;
  final bool isNew;
  final bool isAvailable;
  final bool trackInventory;
  final bool requiresConfirmation;
  final String? defaultVariantId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const ProductEntity({
    required this.id,
    required this.name,
    this.description,
    this.type = ProductType.physical,
    required this.sellerActorId,
    this.categoryId,
    this.categoryName,
    required this.price,
    this.currency = 'TZS',
    this.sku,
    this.imageUrl,
    this.imageUrls = const [],
    this.status = ProductStatus.draft,
    this.isFeatured = false,
    this.isNew = false,
    this.isAvailable = true,
    this.trackInventory = false,
    this.requiresConfirmation = false,
    this.defaultVariantId,
    this.createdAt,
    this.updatedAt,
  });

  /// Whether the product is in draft status and can be published.
  bool get canPublish => status == ProductStatus.draft;

  /// Whether the product is active and can be archived.
  bool get canArchive => status == ProductStatus.active;

  /// Formatted price string with currency.
  String get formattedPrice {
    final formatted = price.toStringAsFixed(2).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );
    return '$currency $formatted';
  }

  /// Returns overlay tag labels for display on cards/tiles.
  List<String> get overlayTags {
    final tags = <String>[];
    if (isNew) tags.add('NEW');
    if (isFeatured) tags.add('FEATURED');
    if (!isAvailable) tags.add('UNAVAILABLE');
    return tags;
  }

  ProductEntity copyWith({
    String? id,
    String? name,
    String? description,
    ProductType? type,
    String? sellerActorId,
    String? categoryId,
    String? categoryName,
    double? price,
    String? currency,
    String? sku,
    String? imageUrl,
    List<String>? imageUrls,
    ProductStatus? status,
    bool? isFeatured,
    bool? isNew,
    bool? isAvailable,
    bool? trackInventory,
    bool? requiresConfirmation,
    String? defaultVariantId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ProductEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      type: type ?? this.type,
      sellerActorId: sellerActorId ?? this.sellerActorId,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      price: price ?? this.price,
      currency: currency ?? this.currency,
      sku: sku ?? this.sku,
      imageUrl: imageUrl ?? this.imageUrl,
      imageUrls: imageUrls ?? this.imageUrls,
      status: status ?? this.status,
      isFeatured: isFeatured ?? this.isFeatured,
      isNew: isNew ?? this.isNew,
      isAvailable: isAvailable ?? this.isAvailable,
      trackInventory: trackInventory ?? this.trackInventory,
      requiresConfirmation: requiresConfirmation ?? this.requiresConfirmation,
      defaultVariantId: defaultVariantId ?? this.defaultVariantId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        type,
        sellerActorId,
        categoryId,
        categoryName,
        price,
        currency,
        sku,
        imageUrl,
        imageUrls,
        status,
        isFeatured,
        isNew,
        isAvailable,
        trackInventory,
        requiresConfirmation,
        defaultVariantId,
        createdAt,
        updatedAt,
      ];
}
