// lib/features/product/presentation/bloc/product_bloc.dart
//
// MODIFICATION: Added:
//   1. Optional constructor parameter: GetProductsWithPromotionsUseCase
//   2. Handler for ProductLoadWithPromotionsRequested
//
// All existing handlers, states, and constructor parameters are UNCHANGED.
// The bloc is backward-compatible — callers that do not inject
// getProductsWithPromotionsUseCase continue to work; they just cannot
// dispatch ProductLoadWithPromotionsRequested.
// ─────────────────────────────────────────────────────────────

import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/usecase/usecase.dart';
import '../../domain/services/product_domain_service.dart';
import '../../domain/usecases/create_product_usecase.dart';
import '../../domain/usecases/delete_product_usecase.dart';
import '../../domain/usecases/get_product_usecase.dart';
import '../../domain/usecases/get_all_product_usecase.dart';
import '../../domain/usecases/get_products_with_promotions_usecase.dart';
import '../../domain/usecases/update_product_usecase.dart';
import '../../domain/value_objects/product_status.dart';
import 'product_event.dart';
import 'product_state.dart';

class ProductBloc extends Bloc<ProductEvent, ProductState> {
  final GetAllProductUseCase getAllUseCase;
  final GetProductUseCase getUseCase;
  final CreateProductUseCase createUseCase;
  final UpdateProductUseCase updateUseCase;
  final DeleteProductUseCase deleteUseCase;
  final ProductDomainService domainService;

  // NEW — optional; null means promotion-aware loading is not available
  final GetProductsWithPromotionsUseCase? getWithPromotionsUseCase;

  ProductBloc({
    required this.getAllUseCase,
    required this.getUseCase,
    required this.createUseCase,
    required this.updateUseCase,
    required this.deleteUseCase,
    required this.domainService,
    // NEW — inject when promotion-aware loading is desired
    this.getWithPromotionsUseCase,
  }) : super(ProductInitial()) {
    on<ProductLoadAllRequested>(_onLoadAll);
    on<ProductLoadWithPromotionsRequested>(_onLoadWithPromotions); // NEW
    on<ProductLoadOneRequested>(_onLoadOne);
    on<ProductCreateRequested>(_onCreate);
    on<ProductUpdateRequested>(_onUpdate);
    on<ProductDeleteRequested>(_onDelete);
    on<ProductFormReset>((_, emit) => emit(ProductInitial()));
    on<ProductPublishRequested>(_onPublish);
    on<ProductFeatureRequested>(_onFeature);
    on<ProductUnfeatureRequested>(_onUnfeature);
    on<ProductArchiveRequested>(_onArchive);
  }

  // ── Existing handlers (unchanged) ─────────────────────────

  Future<void> _onLoadAll(
    ProductLoadAllRequested event,
    Emitter<ProductState> emit,
  ) async {
    emit(ProductLoading());
    final result = await getAllUseCase(NoParams());
    result.fold(
      (f) => emit(ProductFailure(f.message)),
      (items) =>
          items.isEmpty ? emit(ProductEmpty()) : emit(ProductListLoaded(items)),
    );
  }

  Future<void> _onLoadOne(
    ProductLoadOneRequested event,
    Emitter<ProductState> emit,
  ) async {
    emit(ProductLoading());
    final result = await getUseCase(GetProductParams(id: event.id));
    result.fold(
      (f) => emit(ProductFailure(f.message)),
      (item) => emit(ProductDetailLoaded(item)),
    );
  }

  Future<void> _onCreate(
    ProductCreateRequested event,
    Emitter<ProductState> emit,
  ) async {
    emit(ProductLoading());
    final result = await createUseCase(event.params);
    result.fold(
      (f) => emit(ProductFailure(f.message)),
      (_) => emit(ProductOperationSuccess('Product created successfully')),
    );
  }

  Future<void> _onUpdate(
    ProductUpdateRequested event,
    Emitter<ProductState> emit,
  ) async {
    emit(ProductLoading());
    final result = await updateUseCase(
      UpdateProductParams(entity: event.entity),
    );
    result.fold(
      (f) => emit(ProductFailure(f.message)),
      (_) => emit(ProductOperationSuccess('Product updated successfully')),
    );
  }

  Future<void> _onDelete(
    ProductDeleteRequested event,
    Emitter<ProductState> emit,
  ) async {
    emit(ProductLoading());
    final result = await deleteUseCase(DeleteProductParams(id: event.id));
    result.fold(
      (f) => emit(ProductFailure(f.message)),
      (_) => emit(ProductOperationSuccess('Product deleted successfully')),
    );
  }

  Future<void> _onPublish(
    ProductPublishRequested event,
    Emitter<ProductState> emit,
  ) async {
    emit(ProductLoading());
    final result = await domainService.transition(
      id: event.id,
      targetStatus: ProductStatus.active,
    );
    result.fold(
      (f) => emit(ProductFailure(f.message)),
      (entity) => emit(
        ProductOperationSuccess('Publish successful', updatedItem: entity),
      ),
    );
  }

  Future<void> _onFeature(
    ProductFeatureRequested event,
    Emitter<ProductState> emit,
  ) async {
    emit(ProductLoading());
    final result = await domainService.transition(
      id: event.id,
      targetStatus: ProductStatus.featured,
    );
    result.fold(
      (f) => emit(ProductFailure(f.message)),
      (entity) => emit(
        ProductOperationSuccess(
          'Mark Featured successful',
          updatedItem: entity,
        ),
      ),
    );
  }

  Future<void> _onUnfeature(
    ProductUnfeatureRequested event,
    Emitter<ProductState> emit,
  ) async {
    emit(ProductLoading());
    final result = await domainService.transition(
      id: event.id,
      targetStatus: ProductStatus.active,
    );
    result.fold(
      (f) => emit(ProductFailure(f.message)),
      (entity) => emit(
        ProductOperationSuccess(
          'Remove Featured successful',
          updatedItem: entity,
        ),
      ),
    );
  }

  Future<void> _onArchive(
    ProductArchiveRequested event,
    Emitter<ProductState> emit,
  ) async {
    emit(ProductLoading());
    final result = await domainService.transition(
      id: event.id,
      targetStatus: ProductStatus.archived,
    );
    result.fold(
      (f) => emit(ProductFailure(f.message)),
      (entity) => emit(
        ProductOperationSuccess('Archive successful', updatedItem: entity),
      ),
    );
  }

  // ── NEW: Promotion-aware list load ─────────────────────────
  //
  // Falls back to plain GetAllProductUseCase when
  // getWithPromotionsUseCase is not injected.

  Future<void> _onLoadWithPromotions(
    ProductLoadWithPromotionsRequested event,
    Emitter<ProductState> emit,
  ) async {
    emit(ProductLoading());

    if (getWithPromotionsUseCase == null) {
      // Graceful fallback — behaves exactly like ProductLoadAllRequested
      final result = await getAllUseCase(NoParams());
      result.fold(
        (f) => emit(ProductFailure(f.message)),
        (items) => items.isEmpty
            ? emit(ProductEmpty())
            : emit(ProductListLoaded(items)),
      );
      return;
    }

    final result = await getWithPromotionsUseCase!(NoParams());
    result.fold(
      (f) => emit(ProductFailure(f.message)),
      (items) =>
          items.isEmpty ? emit(ProductEmpty()) : emit(ProductListLoaded(items)),
    );
  }
}
