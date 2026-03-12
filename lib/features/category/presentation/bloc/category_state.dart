import '../../domain/entities/category_entity.dart';

abstract class CategoryState {}

class CategoryInitial          extends CategoryState {}
class CategoryLoading           extends CategoryState {}

class CategoryListLoaded extends CategoryState {
  final List<CategoryEntity> items;
  CategoryListLoaded(this.items);
}

class CategoryDetailLoaded extends CategoryState {
  final CategoryEntity item;
  CategoryDetailLoaded(this.item);
}

class CategoryOperationSuccess extends CategoryState {
  final String message;
  CategoryOperationSuccess(this.message);
}

class CategoryEmpty extends CategoryState {}

class CategoryFailure extends CategoryState {
  final String message;
  CategoryFailure(this.message);
}
