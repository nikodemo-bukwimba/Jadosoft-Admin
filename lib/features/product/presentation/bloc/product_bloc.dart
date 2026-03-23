import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/services/product_domain_service.dart';
import '../../domain/usecases/create_product_usecase.dart';
import '../../domain/usecases/delete_product_usecase.dart';
import '../../domain/usecases/get_all_product_usecase.dart';
import '../../domain/usecases/get_product_usecase.dart';
import '../../domain/usecases/update_product_usecase.dart';
import 'product_event.dart';
import 'product_state.dart';

/// BLoC for the product feature.
///
/// Handles CRUD operations and Level 2 status transitions
/// (publish, archive) via [ProductDomainService].
class ProductBloc extends Bloc<ProductEvent, ProductState> {
  final GetAllProductUsecase _getAllProducts;
  final GetProductUsecase _getProduct;
  final CreateProductUsecase _createProduct;
  final UpdateProductUsecase _updateProduct;
  final DeleteProductUsecase _deleteProduct;
  final ProductDomainService _domainService;

  ProductBloc({
    required GetAllProductUsecase getAllProducts,
    required GetProductUsecase getProduct,
    required CreateProductUsecase createProduct,
    required UpdateProductUsecase updateProduct,
    required DeleteProductUsecase deleteProduct,
    required ProductDomainService domainService,
  })  : _getAllProducts = getAllProducts,
        _getProduct = getProduct,
        _createProduct = createProduct,
        _updateProduct = updateProduct,
        _deleteProduct = deleteProduct,
        _domainService = domainService,
        super(const ProductInitial()) {
    on<ProductLoadAllRequested>(_onLoadAll);
    on<ProductLoadOneRequested>(_onLoadOne);
    on<ProductCreateRequested>(_onCreate);
    on<ProductUpdateRequested>(_onUpdate);
    on<ProductDeleteRequested>(_onDelete);
    on<ProductPublishRequested>(_onPublish);
    on<ProductArchiveRequested>(_onArchive);
    on<ProductToggleFeaturedRequested>(_onToggleFeatured);
  }

  Future<void> _onLoadAll(
    ProductLoadAllRequested event,
    Emitter<ProductState> emit,
  ) async {
    emit(const ProductListLoading());
    final result = await _getAllProducts(GetAllProductParams(
      page: event.page,
      perPage: event.perPage,
      status: event.status,
      type: event.type,
      search: event.search,
    ));
    result.fold(
      (failure) => emit(ProductError(failure.message)),
      (products) => emit(ProductListLoaded(
        products: products,
        currentPage: event.page,
        hasMore: products.length >= event.perPage,
      )),
    );
  }

  Future<void> _onLoadOne(
    ProductLoadOneRequested event,
    Emitter<ProductState> emit,
  ) async {
    emit(const ProductDetailLoading());
    final result = await _getProduct(event.id);
    result.fold(
      (failure) => emit(ProductError(failure.message)),
      (product) => emit(ProductDetailLoaded(product)),
    );
  }

  Future<void> _onCreate(
    ProductCreateRequested event,
    Emitter<ProductState> emit,
  ) async {
    emit(const ProductOperationInProgress(message: 'Creating product...'));
    final result = await _createProduct(event.product);
    result.fold(
      (failure) => emit(ProductError(failure.message)),
      (product) => emit(ProductOperationSuccess(
        message: 'Product created successfully.',
        product: product,
      )),
    );
  }

  Future<void> _onUpdate(
    ProductUpdateRequested event,
    Emitter<ProductState> emit,
  ) async {
    emit(const ProductOperationInProgress(message: 'Updating product...'));
    final result = await _updateProduct(event.product);
    result.fold(
      (failure) => emit(ProductError(failure.message)),
      (product) => emit(ProductOperationSuccess(
        message: 'Product updated successfully.',
        product: product,
      )),
    );
  }

  Future<void> _onDelete(
    ProductDeleteRequested event,
    Emitter<ProductState> emit,
  ) async {
    emit(const ProductOperationInProgress(message: 'Deleting product...'));
    final result = await _deleteProduct(event.id);
    result.fold(
      (failure) => emit(ProductError(failure.message)),
      (_) => emit(const ProductOperationSuccess(
        message: 'Product deleted successfully.',
      )),
    );
  }

  // ── Level 2 Transition Handlers ──────────────────────────────────

  Future<void> _onPublish(
    ProductPublishRequested event,
    Emitter<ProductState> emit,
  ) async {
    emit(const ProductOperationInProgress(message: 'Publishing product...'));
    final result = await _domainService.publish(event.product);
    result.fold(
      (failure) => emit(ProductError(failure.message)),
      (product) => emit(ProductOperationSuccess(
        message: 'Product published successfully.',
        product: product,
      )),
    );
  }

  Future<void> _onArchive(
    ProductArchiveRequested event,
    Emitter<ProductState> emit,
  ) async {
    emit(const ProductOperationInProgress(message: 'Archiving product...'));
    final result = await _domainService.archive(event.product);
    result.fold(
      (failure) => emit(ProductError(failure.message)),
      (product) => emit(ProductOperationSuccess(
        message: 'Product archived successfully.',
        product: product,
      )),
    );
  }

  // ── Client-side Toggle ───────────────────────────────────────────

  Future<void> _onToggleFeatured(
    ProductToggleFeaturedRequested event,
    Emitter<ProductState> emit,
  ) async {
    // Toggle isFeatured locally — this is a client-side boolean,
    // not a status transition. In the future this could call an API
    // endpoint for persisting the flag.
    final toggled = event.product.copyWith(
      isFeatured: !event.product.isFeatured,
    );
    emit(ProductDetailLoaded(toggled));
  }
}
