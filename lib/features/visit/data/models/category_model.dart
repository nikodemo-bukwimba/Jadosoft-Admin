// category_model.dart
// Extends the domain entity with JSON serialization.

import '../../domain/entities/category_entity.dart';

class CategoryModel extends CategoryEntity {
  const CategoryModel({
    required super.id,
    required super.name,
    required super.isActive,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'] as String,
      name: json['name'] as String,
      isActive: json['isActive'] as bool? ?? false,    );
  }

  Map<String, dynamic> toJson() => {
      'id': id,
      'name': name,
      'isActive': isActive,  };

  factory CategoryModel.fromEntity(CategoryEntity entity) {
    return CategoryModel(
      id: entity.id,
      name: entity.name,
      isActive: entity.isActive,    );
  }
}
