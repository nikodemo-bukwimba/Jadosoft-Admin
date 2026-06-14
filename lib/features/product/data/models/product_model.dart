// lib/features/product/data/models/product_model.dart
//Admin app
// CHANGE: Added branchPrice, effectiveBasePrice parsing from API variants.
// All existing fields are untouched.

import '../../domain/entities/product_entity.dart';

class ProductModel extends ProductEntity {
  ProductModel({
    required super.id,
    required super.name,
    super.description,
    required super.price,
    super.branchPrice,
    super.effectiveBasePrice,
    super.effectivePrice,
    super.discountPercentage,
    super.promotionId,
    super.hasPromotion,
    required super.categoryId,
    super.variantId,
    required super.isAvailable,
    required super.isFeatured,
    required super.isNew,
    required super.status,
    super.imageUrl,
    required super.createdAt,
    super.batchNumber,
    super.expiryDate,
    super.packSize,
    super.quantityAvailable,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    final basePrice = (json['base_price'] as num? ?? json['price'] as num? ?? 0)
        .toDouble();

    // branch_price is populated when the API is called with a branch org_id
    final rawBranch = json['branch_price'];
    final branchPrice = rawBranch != null
        ? double.tryParse(rawBranch.toString())
        : null;

    final rawBase = json['effective_base_price'];
    final effectiveBase = rawBase != null
        ? double.tryParse(rawBase.toString())
        : (branchPrice ?? basePrice);

    final rawEffective = json['effective_price'];
    final effectivePrice = rawEffective != null
        ? double.tryParse(rawEffective.toString())
        : effectiveBase;

    return ProductModel(
      id: json['id']?.toString() ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      price: basePrice,
      branchPrice: branchPrice,
      effectiveBasePrice: effectiveBase,
      effectivePrice: effectivePrice,
      discountPercentage: (json['discount_percentage'] as num?)?.toDouble(),
      promotionId: json['promotion_id'] as String?,
      hasPromotion: json['has_promotion'] as bool? ?? false,
      categoryId: json['category_id']?.toString() ?? '',
      variantId: json['variant_id'] as String?,
      isAvailable: json['is_available'] as bool? ?? false,
      isFeatured: json['is_featured'] as bool? ?? false,
      isNew: json['is_new'] as bool? ?? false,
      status: json['status'] as String? ?? 'draft',
      imageUrl: json['image_url'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'].toString())
          : DateTime.now(),
      batchNumber: json['batch_number'] as String?,
      expiryDate: json['expiry_date'] != null
          ? DateTime.tryParse(json['expiry_date'].toString())
          : null,
      packSize: json['pack_size'] as String?,
      quantityAvailable: (json['quantity_available'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'price': price,
    'branch_price': branchPrice,
    'effective_base_price': effectiveBasePrice,
    'effective_price': effectivePrice,
    'discount_percentage': discountPercentage,
    'promotion_id': promotionId,
    'has_promotion': hasPromotion,
    'category_id': categoryId,
    if (variantId != null) 'variant_id': variantId,
    'is_available': isAvailable,
    'is_featured': isFeatured,
    'is_new': isNew,
    'status': status,
    'image_url': imageUrl,
    'created_at': createdAt.toIso8601String(),
    'batch_number': batchNumber,
    'expiry_date': expiryDate?.toIso8601String(),
    'pack_size': packSize,
    'quantity_available': quantityAvailable,
  };

  factory ProductModel.fromEntity(ProductEntity e) {
    if (e is ProductModel) return e;
    return ProductModel(
      id: e.id,
      name: e.name,
      description: e.description,
      price: e.price,
      branchPrice: e.branchPrice,
      effectiveBasePrice: e.effectiveBasePrice,
      effectivePrice: e.effectivePrice,
      discountPercentage: e.discountPercentage,
      promotionId: e.promotionId,
      hasPromotion: e.hasPromotion,
      categoryId: e.categoryId,
      variantId: e.variantId,
      isAvailable: e.isAvailable,
      isFeatured: e.isFeatured,
      isNew: e.isNew,
      status: e.status,
      imageUrl: e.imageUrl,
      createdAt: e.createdAt,
      batchNumber: e.batchNumber,
      expiryDate: e.expiryDate,
      packSize: e.packSize,
      quantityAvailable: e.quantityAvailable,
    );
  }

  @override
  ProductModel copyWith({
    String? id,
    String? name,
    String? description,
    double? price,
    double? branchPrice,
    double? effectiveBasePrice,
    double? effectivePrice,
    double? discountPercentage,
    String? promotionId,
    bool? hasPromotion,
    String? categoryId,
    String? variantId,
    bool? isAvailable,
    bool? isFeatured,
    bool? isNew,
    String? status,
    String? imageUrl,
    DateTime? createdAt,
    String? batchNumber,
    DateTime? expiryDate,
    String? packSize,
    int? quantityAvailable,
  }) {
    return ProductModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      branchPrice: branchPrice ?? this.branchPrice,
      effectiveBasePrice: effectiveBasePrice ?? this.effectiveBasePrice,
      effectivePrice: effectivePrice ?? this.effectivePrice,
      discountPercentage: discountPercentage ?? this.discountPercentage,
      promotionId: promotionId ?? this.promotionId,
      hasPromotion: hasPromotion ?? this.hasPromotion,
      categoryId: categoryId ?? this.categoryId,
      variantId: variantId ?? this.variantId,
      isAvailable: isAvailable ?? this.isAvailable,
      isFeatured: isFeatured ?? this.isFeatured,
      isNew: isNew ?? this.isNew,
      status: status ?? this.status,
      imageUrl: imageUrl ?? this.imageUrl,
      createdAt: createdAt ?? this.createdAt,
      batchNumber: batchNumber ?? this.batchNumber,
      expiryDate: expiryDate ?? this.expiryDate,
      packSize: packSize ?? this.packSize,
      quantityAvailable: quantityAvailable ?? this.quantityAvailable,
    );
  }
}
