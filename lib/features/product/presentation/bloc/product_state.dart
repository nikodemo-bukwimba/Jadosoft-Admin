import 'package:equatable/equatable.dart';

import '../../domain/entities/product_entity.dart';

/// Base class for all product BLoC states.
abstract class ProductState extends Equatable {
  const ProductState();

  @override
  List<Object?> get props => [];
}

/// Initial state before any action.
class ProductInitial extends ProductState {
  const ProductInitial();
}

/// Loading products list.
class ProductListLoading extends ProductState {
  const ProductListLoading();
}

/// Products list loaded successfully.
class ProductListLoaded extends ProductState {
  final List<ProductEntity> products;
  final int currentPage;
  final bool hasMore;

  const ProductListLoaded({
    required this.products,
    this.currentPage = 1,
    this.hasMore = true,
  });

  @override
  List<Object?> get props => [products, currentPage, hasMore];
}

/// Loading a single product detail.
class ProductDetailLoading extends ProductState {
  const ProductDetailLoading();
}

/// Single product loaded.
class ProductDetailLoaded extends ProductState {
  final ProductEntity product;

  const ProductDetailLoaded(this.product);

  @override
  List<Object?> get props => [product];
}

/// A product operation (create/update/delete/transition) is in progress.
class ProductOperationInProgress extends ProductState {
  final String message;

  const ProductOperationInProgress({this.message = 'Processing...'});

  @override
  List<Object?> get props => [message];
}

/// A product operation completed successfully.
class ProductOperationSuccess extends ProductState {
  final String message;
  final ProductEntity? product;

  const ProductOperationSuccess({
    required this.message,
    this.product,
  });

  @override
  List<Object?> get props => [message, product];
}

/// An error occurred during any product operation.
class ProductError extends ProductState {
  final String message;

  const ProductError(this.message);

  @override
  List<Object?> get props => [message];
}
