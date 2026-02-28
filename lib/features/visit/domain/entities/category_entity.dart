// category_entity.dart
// Pure Dart domain entity.
// Zero Flutter imports. Zero network imports.

class CategoryEntity {
  final String id;
  final String name;
  final bool isActive;

  const CategoryEntity({
    required this.id,
    required this.name,
    required this.isActive,
  });

  CategoryEntity copyWith({
     id,
     name,
     isActive,  }) {
    return CategoryEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      isActive: isActive ?? this.isActive,    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CategoryEntity && runtimeType == other.runtimeType &&
      id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'CategoryEntity(id: $id)';
}
