// ============================================================================
// PRODUCT FEATURE — DI REGISTRATION
// ============================================================================
//
// Add this block to: lib/config/di/injection_container.dart
//
// Insert inside the main init() function, AFTER the category feature
// registration (Seq 8) since Products (Seq 9) depends on Categories.
//
// The orgId is resolved from the authenticated user's OrgContext —
// the organization's actor_id. This mirrors how the Nexora Commerce API
// scopes product endpoints: GET/POST /api/v1/commerce/orgs/{orgId}/products
// ============================================================================

import 'package:get_it/get_it.dart';

import '../../features/product/data/datasources/product_mock_datasource.dart';
import '../../features/product/data/datasources/product_remote_datasource.dart';
import '../../features/product/data/repositories/product_repository_impl.dart';
import '../../features/product/domain/guards/product_transition_guard.dart';
import '../../features/product/domain/repositories/product_repository.dart';
import '../../features/product/domain/services/product_domain_service.dart';
import '../../features/product/domain/usecases/create_product_usecase.dart';
import '../../features/product/domain/usecases/delete_product_usecase.dart';
import '../../features/product/domain/usecases/get_all_product_usecase.dart';
import '../../features/product/domain/usecases/get_product_usecase.dart';
import '../../features/product/domain/usecases/update_product_usecase.dart';
import '../../features/product/presentation/bloc/product_bloc.dart';

/// Registers all product feature dependencies into [GetIt].
///
/// Call this inside the main `init()` function of injection_container.dart,
/// after category registration (Seq 8).
///
/// [useMock] — set to `true` for development/testing to use the
/// in-memory mock datasource instead of the remote API.
void registerProductFeature(GetIt sl, {bool useMock = false}) {
  // ── Datasource ──────────────────────────────────────────────────
  if (useMock) {
    sl.registerLazySingleton<ProductRemoteDatasource>(
      () => ProductMockDatasource(),
    );
  } else {
    sl.registerLazySingleton<ProductRemoteDatasource>(
      () => ProductRemoteDatasourceImpl(dio: sl()),
    );
  }

  // ── Repository ──────────────────────────────────────────────────
  // orgId is resolved from OrgContext (the authenticated user's
  // current organization actor_id). This is injected here at DI time.
  //
  // Option A: Resolve from an OrgContext service already in the container:
  //   sl.registerLazySingleton<ProductRepository>(
  //     () => ProductRepositoryImpl(
  //       remoteDatasource: sl(),
  //       orgId: sl<OrgContext>().currentOrgId,
  //     ),
  //   );
  //
  // Option B: Resolve from the AuthBloc / AccountSession:
  //   sl.registerLazySingleton<ProductRepository>(
  //     () => ProductRepositoryImpl(
  //       remoteDatasource: sl(),
  //       orgId: sl<AccountSession>().orgActorId,
  //     ),
  //   );
  //
  // For now, using a factory so orgId is resolved fresh each time:
  sl.registerFactory<ProductRepository>(
    () => ProductRepositoryImpl(
      remoteDatasource: sl(),
      orgId: sl<String>(instanceName: 'currentOrgId'),
    ),
  );

  // ── Guard ───────────────────────────────────────────────────────
  sl.registerLazySingleton<ProductTransitionGuard>(
    () => const ProductTransitionGuard(),
  );

  // ── Domain Service ──────────────────────────────────────────────
  sl.registerFactory<ProductDomainService>(
    () => ProductDomainService(
      repository: sl(),
      guard: sl(),
    ),
  );

  // ── Use Cases ───────────────────────────────────────────────────
  sl.registerFactory(() => GetAllProductUsecase(sl()));
  sl.registerFactory(() => GetProductUsecase(sl()));
  sl.registerFactory(() => CreateProductUsecase(sl()));
  sl.registerFactory(() => UpdateProductUsecase(sl()));
  sl.registerFactory(() => DeleteProductUsecase(sl()));

  // ── BLoC ────────────────────────────────────────────────────────
  sl.registerFactory<ProductBloc>(
    () => ProductBloc(
      getAllProducts: sl(),
      getProduct: sl(),
      createProduct: sl(),
      updateProduct: sl(),
      deleteProduct: sl(),
      domainService: sl(),
    ),
  );
}
