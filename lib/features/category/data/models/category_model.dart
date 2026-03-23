import '../../domain/entities/category_entity.dart';

class CategoryModel extends CategoryEntity {
  const CategoryModel({required super.id, required super.name, super.description, required super.isActive});

  factory CategoryModel.fromJson(Map<String, dynamic> json) => CategoryModel(
    id: json['id']?.toString() ?? '', name: json['name'] as String? ?? '',
    description: json['description'] as String?, isActive: json['is_active'] as bool? ?? false);

  Map<String, dynamic> toJson() => {'name': name, 'description': description, 'is_active': isActive};

  factory CategoryModel.fromEntity(CategoryEntity e) => CategoryModel(
    id: e.id, name: e.name, description: e.description, isActive: e.isActive);
}
