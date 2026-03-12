// injection_container.dart
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// Dependency injection setup using get_it.
//
// TOKEN REFRESH CONFIGURATION:
//   By default TokenRefreshConfig.disabled() is used â€” safe for backends
//   where tokens never expire (e.g. Laravel Sanctum with default settings).
//   Swap to TokenRefreshConfig.enabled(...) on line marked [REFRESH CONFIG].
//
// CACHE:
//   AppDatabase is a singleton â€” one SQLite file, shared by all DAOs.
//   Profile and Dashboard repositories are now cache-first: they read
//   from Drift first and only hit the API when the TTL has expired.
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// â”€â”€ GENERATOR FEATURE IMPORTS â€” append only â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

import 'package:admin_panel/features/actor/data/datasources/actor_remote_datasource.dart';
import 'package:admin_panel/features/actor/data/datasources/actor_local_datasource.dart';
import 'package:admin_panel/features/actor/data/repositories/actor_repository_impl.dart';
import 'package:admin_panel/features/actor/domain/repositories/actor_repository.dart';
import 'package:admin_panel/features/actor/domain/usecases/get_all_actor_usecase.dart';
import 'package:admin_panel/features/actor/domain/usecases/get_actor_usecase.dart';
import 'package:admin_panel/features/actor/domain/usecases/create_actor_usecase.dart';
import 'package:admin_panel/features/actor/domain/usecases/update_actor_usecase.dart';
import 'package:admin_panel/features/actor/domain/usecases/delete_actor_usecase.dart';
import 'package:admin_panel/features/actor/presentation/bloc/actor_bloc.dart';
import 'package:admin_panel/core/database/actor_cache_dao.dart';

// â”€â”€ END GENERATOR FEATURE IMPORTS

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';

import '../../core/database/app_database.dart';
import '../../core/database/dashboard_cache_dao.dart';
import '../../core/database/profile_cache_dao.dart';
import '../../core/network/auth_interceptor.dart';
import '../../core/network/dio_client.dart';
import '../../core/network/token_refresh_config.dart';
import '../../core/storage/secure_storage_service.dart';
import '../../features/auth/data/datasources/auth_local_datasource.dart';
import '../../features/auth/data/datasources/auth_remote_datasource.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/domain/usecases/auth_usecases.dart';
import '../../features/auth/domain/usecases/login_usecase.dart';
import '../../features/auth/domain/usecases/logout_usecase.dart';
import '../../features/auth/domain/usecases/register_usecase.dart';
import '../../features/auth/domain/usecases/switch_account_usecase.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/dashboard/data/datasources/dashboard_remote_datasource.dart';
import '../../features/dashboard/data/repositories/dashboard_repository_impl.dart';
import '../../features/dashboard/domain/repositories/dashboard_repository.dart';
import '../../features/dashboard/domain/usecases/get_dashboard_stats_usecase.dart';
import '../../features/dashboard/presentation/bloc/dashboard_bloc.dart';
import '../../features/profile/data/datasources/profile_remote_datasource.dart';
import '../../features/profile/data/repositories/profile_repository_impl.dart';
import '../../features/profile/domain/repositories/profile_repository.dart';
import '../../features/profile/domain/usecases/get_profile_usecase.dart';
import '../../features/profile/presentation/bloc/profile_bloc.dart';

// â”€â”€ GENERATOR IMPORTS â€” append only â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// â”€â”€ END GENERATOR IMPORTS â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

final sl = GetIt.instance;

Future<void> initDependencies() async {
  // â”€â”€ 1. Infrastructure â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  // encryptedSharedPreferences removed â€” deprecated in flutter_secure_storage v11.
  // The library now uses custom ciphers automatically on Android.
  sl.registerLazySingleton<FlutterSecureStorage>(
    () => const FlutterSecureStorage(),
  );

  sl.registerLazySingleton<SecureStorageService>(
    () => SecureStorageService(sl<FlutterSecureStorage>()),
  );

  // â”€â”€ [REFRESH CONFIG] â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  // Swap to TokenRefreshConfig.enabled(...) when your backend
  // expires tokens. See token_refresh_config.dart for examples.
  sl.registerLazySingleton<TokenRefreshConfig>(
    () => const TokenRefreshConfig.disabled(),
  );

  sl.registerLazySingleton<AuthInterceptor>(
    () => AuthInterceptor(
      sl<SecureStorageService>(),
      refreshConfig: sl<TokenRefreshConfig>(),
    ),
  );

  // Single Dio instance shared by ALL features.
  // buildSecureDioClient calls authInterceptor.setDio() internally.
  sl.registerLazySingleton<Dio>(
    () => buildSecureDioClient(authInterceptor: sl<AuthInterceptor>()),
  );

  // â”€â”€ 2. Local cache (Drift) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  // Single database instance â€” one SQLite file for the whole app.
  sl.registerLazySingleton<AppDatabase>(() => AppDatabase());

  // DAOs are lightweight accessors on the same database instance.
  // profileCacheDao / dashboardCacheDao are generated by Drift.
  // Run: flutter pub run build_runner build --delete-conflicting-outputs
  sl.registerLazySingleton<ProfileCacheDao>(
    () => sl<AppDatabase>().profileCacheDao,
  );
  sl.registerLazySingleton<DashboardCacheDao>(
    () => sl<AppDatabase>().dashboardCacheDao,
  );

  // â”€â”€ 3. Auth datasources â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  sl.registerLazySingleton<AuthLocalDataSource>(
    () => AuthLocalDataSourceImpl(sl<SecureStorageService>()),
  );

  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(sl<Dio>()),
  );

  // â”€â”€ 4. Auth repository â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      remote: sl<AuthRemoteDataSource>(),
      local: sl<AuthLocalDataSource>(),
    ),
  );

  // â”€â”€ 5. Auth use cases â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  sl.registerLazySingleton(() => LoginUseCase(sl<AuthRepository>()));
  sl.registerLazySingleton(() => RegisterUseCase(sl<AuthRepository>()));
  sl.registerLazySingleton(() => LogoutUseCase(sl<AuthRepository>()));
  sl.registerLazySingleton(() => LogoutAccountUseCase(sl<AuthRepository>()));
  sl.registerLazySingleton(() => SwitchAccountUseCase(sl<AuthRepository>()));
  sl.registerLazySingleton(() => GetActiveSessionUseCase(sl<AuthRepository>()));
  sl.registerLazySingleton(() => GetSavedAccountsUseCase(sl<AuthRepository>()));
  sl.registerLazySingleton(() => RefreshSessionUseCase(sl<AuthRepository>()));

  // â”€â”€ 6. Auth BLoC (factory â€” fresh per widget tree) â”€â”€â”€â”€â”€â”€â”€â”€

  sl.registerFactory<AuthBloc>(
    () => AuthBloc(
      login: sl<LoginUseCase>(),
      register: sl<RegisterUseCase>(),
      logout: sl<LogoutUseCase>(),
      logoutAccount: sl<LogoutAccountUseCase>(),
      switchAccount: sl<SwitchAccountUseCase>(),
      getActiveSession: sl<GetActiveSessionUseCase>(),
      getSavedAccounts: sl<GetSavedAccountsUseCase>(),
      refreshSession: sl<RefreshSessionUseCase>(),
    ),
  );

  // â”€â”€ 7. Profile datasource + repository + use case â”€â”€â”€â”€â”€â”€â”€â”€â”€

  sl.registerLazySingleton<ProfileRemoteDataSource>(
    () => ProfileRemoteDataSourceImpl(sl<Dio>()),
  );

  sl.registerLazySingleton<ProfileRepository>(
    () => ProfileRepositoryImpl(
      remote: sl<ProfileRemoteDataSource>(),
      cacheDao: sl<ProfileCacheDao>(),
      storage: sl<SecureStorageService>(),
    ),
  );

  sl.registerLazySingleton(() => GetProfileUseCase(sl<ProfileRepository>()));

  // â”€â”€ 8. Profile BLoC (factory) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  sl.registerFactory<ProfileBloc>(() => ProfileBloc(sl<GetProfileUseCase>()));

  // â”€â”€ 9. Dashboard datasource + repository + use case â”€â”€â”€â”€â”€â”€â”€

  sl.registerLazySingleton<DashboardRemoteDataSource>(
    () => DashboardRemoteDataSourceImpl(sl<Dio>()),
  );

  sl.registerLazySingleton<DashboardRepository>(
    () => DashboardRepositoryImpl(
      remote: sl<DashboardRemoteDataSource>(),
      cacheDao: sl<DashboardCacheDao>(),
    ),
  );

  sl.registerLazySingleton(
    () => GetDashboardStatsUseCase(sl<DashboardRepository>()),
  );

  // â”€â”€ 10. Dashboard BLoC (factory) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  sl.registerFactory<DashboardBloc>(
    () => DashboardBloc(getDashboardStats: sl<GetDashboardStatsUseCase>()),
  );

  // â”€â”€ GENERATOR MANAGED â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  // DAO â€” depends on AppDatabase (already registered)
  sl.registerLazySingleton<ActorCacheDao>(() => ActorCacheDao(sl()));

  // Data sources
  sl.registerLazySingleton<ActorRemoteDataSource>(
    () => ActorRemoteDataSourceImpl(dio: sl()),
  );
  sl.registerLazySingleton<ActorLocalDataSource>(
    () => ActorLocalDataSourceImpl(dao: sl()),
  );

  // Repository â€” API-first with cache fallback
  sl.registerLazySingleton<ActorRepository>(
    () => ActorRepositoryImpl(remote: sl(), local: sl()),
  );

  // Use cases
  sl.registerLazySingleton(() => GetAllActorUseCase(sl()));
  sl.registerLazySingleton(() => GetActorUseCase(sl()));
  sl.registerLazySingleton(() => CreateActorUseCase(sl()));
  sl.registerLazySingleton(() => UpdateActorUseCase(sl()));
  sl.registerLazySingleton(() => DeleteActorUseCase(sl()));

  // BLoC
  sl.registerFactory<ActorBloc>(
    () => ActorBloc(
      getAllUseCase: sl(),
      getUseCase: sl(),
      createUseCase: sl(),
      updateUseCase: sl(),
      deleteUseCase: sl(),
    ),
  );
  // â”€â”€ END GENERATOR MANAGED â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
}





















