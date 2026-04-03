import '../../domain/entities/product_entity.dart';

class ProductModel extends ProductEntity {
  const ProductModel({
    required super.id,
    required super.name,
    super.description,
    required super.price,
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
    return ProductModel(
      id: json['id']?.toString() ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      price: (json['price'] as num? ?? 0).toDouble(),
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

  factory ProductModel.fromEntity(ProductEntity entity) {
    return ProductModel(
      id: entity.id,
      name: entity.name,
      description: entity.description,
      price: entity.price,
      categoryId: entity.categoryId,
      variantId: entity.variantId,
      isAvailable: entity.isAvailable,
      isFeatured: entity.isFeatured,
      isNew: entity.isNew,
      status: entity.status,
      imageUrl: entity.imageUrl,
      createdAt: entity.createdAt,
      batchNumber: entity.batchNumber,
      expiryDate: entity.expiryDate,
      packSize: entity.packSize,
      quantityAvailable: entity.quantityAvailable,
    );
  }
}
