// lib/features/product/domain/entities/product_entity.dart

import 'package:equatable/equatable.dart';

class ProductEntity extends Equatable {
  final String id;
  final String name;
  final String? description;
  final double price; // base price — never changes
  final double effectivePrice; // promotion price if active, else == price
  final double? discountPercentage; // null if no active promotion
  final String? promotionId; // null if no active promotion
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

  const ProductEntity({
    required this.id,
    required this.name,
    this.description,
    required this.price,
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
  }) : effectivePrice = effectivePrice ?? price;

  /// The price to display prominently in the UI.
  double get displayPrice => effectivePrice;

  /// True when there is a live discount reducing the price.
  bool get isOnPromotion => hasPromotion && effectivePrice < price;

  ProductEntity copyWith({
    String? id,
    String? name,
    String? description,
    double? price,
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
