// category_state.dart
// All states emitted by CategoryBloc.

part of 'category_bloc.dart';

abstract class CategoryState {}

class CategoryInitial          extends CategoryState {}
class CategoryLoading          extends CategoryState {}
class CategoryEmpty            extends CategoryState {}

class CategoryListLoaded extends CategoryState {
  final List<CategoryEntity> items;
  final int? totalCount;

  CategoryListLoaded(this.items, {this.totalCount});
}

class CategoryDetailLoaded extends CategoryState {
  final CategoryEntity item;
  CategoryDetailLoaded(this.item);
}

class CategoryOperationSuccess extends CategoryState {
  final String message;
  final CategoryEntity? updatedItem;

  CategoryOperationSuccess(this.message, {this.updatedItem});
}

class CategoryFailure extends CategoryState {
  final String message;
  CategoryFailure(this.message);
}
