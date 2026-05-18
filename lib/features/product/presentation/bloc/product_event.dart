// lib/features/product/presentation/bloc/product_event.dart
//
// MODIFICATION: Added ProductLoadWithPromotionsRequested.
// All existing events are untouched.
// ─────────────────────────────────────────────────────────────

import '../../domain/entities/product_entity.dart';
import '../../domain/usecases/create_product_usecase.dart';

abstract class ProductEvent {}

// ── Existing events (unchanged) ────────────────────────────────────────────

class ProductLoadAllRequested extends ProductEvent {}

class ProductLoadOneRequested extends ProductEvent {
  final String id;
  ProductLoadOneRequested(this.id);
}

class ProductCreateRequested extends ProductEvent {
  final CreateProductParams params;
  ProductCreateRequested(this.params);
}

class ProductUpdateRequested extends ProductEvent {
  final ProductEntity entity;
  ProductUpdateRequested(this.entity);
}

class ProductDeleteRequested extends ProductEvent {
  final String id;
  ProductDeleteRequested(this.id);
}

class ProductFormReset extends ProductEvent {}

class ProductPublishRequested extends ProductEvent {
  final String id;
  ProductPublishRequested(this.id);
}

class ProductFeatureRequested extends ProductEvent {
  final String id;
  ProductFeatureRequested(this.id);
}

class ProductUnfeatureRequested extends ProductEvent {
  final String id;
  ProductUnfeatureRequested(this.id);
}

class ProductArchiveRequested extends ProductEvent {
  final String id;
  ProductArchiveRequested(this.id);
}

// ── NEW: Promotion-aware list load ─────────────────────────────────────────
//
// Dispatches GetProductsWithPromotionsUseCase instead of
// GetAllProductUseCase.  Emits the same ProductListLoaded / ProductEmpty /
// ProductFailure states so all existing BlocBuilders work without any change.
//
// When to dispatch this vs ProductLoadAllRequested:
//   • Use ProductLoadWithPromotionsRequested from ProductListPage (or anywhere
//     you want guaranteed promotion-aware pricing).
//   • ProductLoadAllRequested remains safe and unchanged for callers that do
//     not need promotion awareness (e.g. the promotion form product-picker).

class ProductLoadWithPromotionsRequested extends ProductEvent {}
