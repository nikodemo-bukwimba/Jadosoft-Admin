// lib/features/product/domain/entities/product_entity.dart
//
// CHANGE: Added branchPrice and effectiveBasePrice fields.
//
// branchPrice      — branch override price set via BranchPricingService.
//                    null when the viewing org has no override (uses root base).
// effectiveBasePrice — branchPrice ?? price.  This is the base BEFORE promotion.
//                    Previously all callers assumed price == base; now use this.
//
// displayPrice and isOnPromotion are unchanged in semantics — they still reflect
// the final price shown to the user (after branch price + promotion applied).

import 'package:equatable/equatable.dart';

class ProductEntity extends Equatable {
  final String id;
  final String name;
  final String? description;

  /// Root catalog base price — the price set at root org level.
  /// Never mutated by branch overrides or promotions.
  final double price;

  /// Branch-specific base price override (null = no branch override).
  /// When set, this is the base before promotion discount is applied.
  final double? branchPrice;

  /// The effective base used for promotion calculations:
  ///   branchPrice ?? price
  final double effectiveBasePrice;

  /// Final display price after all discounts (effectiveBasePrice × discount).
  /// Equals effectiveBasePrice when no promotion is active.
  final double effectivePrice;

  final double? discountPercentage;
  final String? promotionId;
  final bool hasPromotion;
  final String categoryId;
  final String? variantId;
  final bool isAvailable;
  final bool isFeatured;
  final bool isNew;
  final String status;
  final String? imageUrl;
  final DateTime createdAt;
  final String? batchNumber;
  final DateTime? expiryDate;
  final String? packSize;
  final int? quantityAvailable;

  ProductEntity({
    required this.id,
    required this.name,
    this.description,
    required this.price,
    this.branchPrice,
    double? effectiveBasePrice,
    double? effectivePrice,
    this.discountPercentage,
    this.promotionId,
    this.hasPromotion = false,
    required this.categoryId,
    this.variantId,
    required this.isAvailable,
    required this.isFeatured,
    required this.isNew,
    required this.status,
    this.imageUrl,
    required this.createdAt,
    this.batchNumber,
    this.expiryDate,
    this.packSize,
    this.quantityAvailable,
  }) : effectiveBasePrice = effectiveBasePrice ?? branchPrice ?? price,
       effectivePrice =
           effectivePrice ?? effectiveBasePrice ?? branchPrice ?? price;

  /// The price to display prominently in the UI.
  double get displayPrice => effectivePrice;

  /// True when a branch override is active for this org.
  bool get hasBranchPrice => branchPrice != null && branchPrice != price;

  /// True when there is a live discount reducing the price.
  bool get isOnPromotion => hasPromotion && effectivePrice < effectiveBasePrice;

  ProductEntity copyWith({
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
    return ProductEntity(
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

  @override
  List<Object?> get props => [
    id,
    name,
    description,
    price,
    branchPrice,
    effectiveBasePrice,
    effectivePrice,
    discountPercentage,
    promotionId,
    hasPromotion,
    categoryId,
    variantId,
    isAvailable,
    isFeatured,
    isNew,
    status,
    imageUrl,
    createdAt,
    batchNumber,
    expiryDate,
    packSize,
    quantityAvailable,
  ];
}
