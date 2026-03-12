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
    required super.createdAt,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      price: (json['price'] as num).toDouble(),
      categoryId: json['category_id'] as String,
      isAvailable: json['is_available'] as bool? ?? false,
      isFeatured: json['is_featured'] as bool? ?? false,
      isNew: json['is_new'] as bool? ?? false,
      status: json['status'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
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
      createdAt: entity.createdAt,
    );
  }
}