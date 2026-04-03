import 'package:equatable/equatable.dart';

class ProductEntity extends Equatable {
  final String id;
  final String name;
  final String? description;
  final double price;
  final String categoryId;
  final String? variantId;
  final bool isAvailable;
  final bool isFeatured;
  final bool isNew;
  final String status;
  final String? imageUrl;
  final DateTime createdAt;
  // ── Inventory fields ──────────────────────────────────────────────────────
  final String? batchNumber;
  final DateTime? expiryDate;
  final String? packSize;
  final int? quantityAvailable;

  const ProductEntity({
    required this.id,
    required this.name,
    this.description,
    required this.price,
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
  });

  ProductEntity copyWith({
    String? id,
    String? name,
    String? description,
    double? price,
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
      variantId: variantId ?? this.variantId,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      categoryId: categoryId ?? this.categoryId,
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
    variantId,
    name,
    description,
    price,
    categoryId,
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
