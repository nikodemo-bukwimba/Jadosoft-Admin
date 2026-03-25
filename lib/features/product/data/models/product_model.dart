import '../../domain/entities/product_entity.dart';

class ProductModel extends ProductEntity {
  const ProductModel({
    required super.id,
    required super.name,
    super.description,
    required super.price,
    required super.categoryId,
    required super.isAvailable,
    required super.isFeatured,
    required super.isNew,
    required super.status,
    super.imageUrl,
    required super.createdAt,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id']?.toString() ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      price: (json['price'] as num? ?? 0).toDouble(),
      categoryId: json['category_id']?.toString() ?? '',
      isAvailable: json['is_available'] as bool? ?? false,
      isFeatured: json['is_featured'] as bool? ?? false,
      isNew: json['is_new'] as bool? ?? false,
      status: json['status'] as String? ?? 'draft',
      imageUrl: json['image_url'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'].toString())
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'price': price,
    'category_id': categoryId,
    'is_available': isAvailable,
    'is_featured': isFeatured,
    'is_new': isNew,
    'status': status,
    'image_url': imageUrl,
    'created_at': createdAt.toIso8601String(),
  };

  factory ProductModel.fromEntity(ProductEntity entity) {
    return ProductModel(
      id: entity.id,
      name: entity.name,
      description: entity.description,
      price: entity.price,
      categoryId: entity.categoryId,
      isAvailable: entity.isAvailable,
      isFeatured: entity.isFeatured,
      isNew: entity.isNew,
      status: entity.status,
      imageUrl: entity.imageUrl,
      createdAt: entity.createdAt,
    );
  }
}
