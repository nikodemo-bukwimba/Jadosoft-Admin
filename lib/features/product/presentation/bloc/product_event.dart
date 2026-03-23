import 'package:equatable/equatable.dart';

import '../../domain/entities/product_entity.dart';

/// Base class for all product BLoC events.
abstract class ProductEvent extends Equatable {
  const ProductEvent();

  @override
  List<Object?> get props => [];
}

/// Load all products with optional filters.
class ProductLoadAllRequested extends ProductEvent {
  final int page;
  final int perPage;
  final String? status;
  final String? type;
  final String? search;

  const ProductLoadAllRequested({
    this.page = 1,
    this.perPage = 25,
    this.status,
    this.type,
    this.search,
  });

  @override
  List<Object?> get props => [page, perPage, status, type, search];
}

/// Load a single product by ID.
class ProductLoadOneRequested extends ProductEvent {
  final String id;

  const ProductLoadOneRequested(this.id);

  @override
  List<Object?> get props => [id];
}

/// Create a new product.
class ProductCreateRequested extends ProductEvent {
  final ProductEntity product;

  const ProductCreateRequested(this.product);

  @override
  List<Object?> get props => [product];
}

/// Update an existing product.
class ProductUpdateRequested extends ProductEvent {
  final ProductEntity product;

  const ProductUpdateRequested(this.product);

  @override
  List<Object?> get props => [product];
}

/// Delete a product.
class ProductDeleteRequested extends ProductEvent {
  final String id;

  const ProductDeleteRequested(this.id);

  @override
  List<Object?> get props => [id];
}

// ── Status Transition Events (Level 2) ─────────────────────────────

/// Publish a draft product → active.
class ProductPublishRequested extends ProductEvent {
  final ProductEntity product;

  const ProductPublishRequested(this.product);

  @override
  List<Object?> get props => [product];
}

/// Archive an active product → archived.
class ProductArchiveRequested extends ProductEvent {
  final ProductEntity product;

  const ProductArchiveRequested(this.product);

  @override
  List<Object?> get props => [product];
}

// ── UI State Events ────────────────────────────────────────────────

/// Toggle the "featured" flag on a product (client-side only).
class ProductToggleFeaturedRequested extends ProductEvent {
  final ProductEntity product;

  const ProductToggleFeaturedRequested(this.product);

  @override
  List<Object?> get props => [product];
}
