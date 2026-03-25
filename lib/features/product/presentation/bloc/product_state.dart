import '../../domain/entities/product_entity.dart';

abstract class ProductState {}

class ProductInitial extends ProductState {}
class ProductLoading extends ProductState {}

class ProductListLoaded extends ProductState {
  final List<ProductEntity> items;
  ProductListLoaded(this.items);
}

class ProductDetailLoaded extends ProductState {
  final ProductEntity item;
  ProductDetailLoaded(this.item);
}

class ProductOperationSuccess extends ProductState {
  final String message;
  final ProductEntity? updatedItem;
  ProductOperationSuccess(this.message, {this.updatedItem});
}

class ProductEmpty extends ProductState {}

class ProductFailure extends ProductState {
  final String message;
  ProductFailure(this.message);
}
