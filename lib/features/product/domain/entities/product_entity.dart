import 'package:equatable/equatable.dart';

class ProductEntity extends Equatable {
  final String id;
  final String name;
  final String? description;
  final double price;
  final String categoryId;
  final bool isAvailable;
  final bool isFeatured;
  final bool isNew;
  final String status;
  final String? imageUrl;
  final DateTime createdAt;

  const ProductEntity({
    required this.id,
    required this.name,
    this.description,
    required this.price,
    required this.categoryId,
    required this.isAvailable,
    required this.isFeatured,
    required this.isNew,
    required this.status,
    this.imageUrl,
    required this.createdAt,
  });

  ProductEntity copyWith({
    String? id,
    String? name,
    String? description,
    double? price,
    String? categoryId,
    bool? isAvailable,
    bool? isFeatured,
    bool? isNew,
    String? status,
    String? imageUrl,
    DateTime? createdAt,
  }) {
    return ProductEntity(
      id: id ?? this.id,
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
    );
  }

  @override
  List<Object?> get props => [
    id,
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
  ];
}
