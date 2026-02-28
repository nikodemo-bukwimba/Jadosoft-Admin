// injection_container.dart
// ─────────────────────────────────────────────────────────────
// Full GetIt registrations — bottom-up order:
//   infrastructure → datasources → repositories → use cases → BLoCs
// ─────────────────────────────────────────────────────────────

import 'package:dio/dio.dart';
import 'package:fca/features/category/domain/usecases/create_isActive_usecase.dart';
import 'package:fca/features/category/domain/usecases/delete_isActive_usecase.dart';
import 'package:fca/features/category/domain/usecases/update_isActive_usecase.dart';
import 'package:fca/features/hello/data/datasources/hello_remote_datasource.dart';
import 'package:fca/features/hello/data/repositories/hello_repository_impl.dart';
import 'package:fca/features/hello/domain/repositories/hello_repository.dart';
import 'package:fca/features/hello/domain/usecases/create_hello_usecase.dart';
import 'package:fca/features/hello/domain/usecases/delete_hello_usecase.dart';
import 'package:fca/features/hello/domain/usecases/get_all_hello_usecase.dart';
import 'package:fca/features/hello/domain/usecases/get_hello_usecase.dart';
import 'package:fca/features/hello/domain/usecases/update_hello_usecase.dart';
import 'package:fca/features/hello/presentation/bloc/hello_bloc.dart';
import 'package:fca/features/profile/data/datasources/profile_remote_datasource.dart';
import 'package:fca/features/profile/data/repositories/profile_repository_impl.dart';
import 'package:fca/features/profile/domain/repositories/profile_repository.dart';
import 'package:fca/features/profile/domain/usecases/get_profile_usecase.dart';
import 'package:fca/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:fca/core/network/auth_interceptor.dart';
import 'package:fca/core/network/dio_client.dart';
import 'package:fca/core/storage/secure_storage_service.dart';
import 'package:fca/features/auth/data/datasources/auth_local_datasource.dart';
import 'package:fca/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:fca/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:fca/features/auth/domain/repositories/auth_repository.dart';
import 'package:fca/features/auth/domain/usecases/auth_usecases.dart';
import 'package:fca/features/auth/domain/usecases/login_usecase.dart';
import 'package:fca/features/auth/domain/usecases/logout_usecase.dart';
import 'package:fca/features/auth/domain/usecases/register_usecase.dart';
import 'package:fca/features/auth/domain/usecases/switch_account_usecase.dart';
import 'package:fca/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:fca/features/visit/domain/usecases/create_isActive_usecase.dart';
import 'package:fca/features/visit/domain/usecases/delete_isActive_usecase.dart';
import 'package:fca/features/visit/domain/usecases/update_isActive_usecase.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:fca/features/category/data/datasources/category_remote_datasource.dart';
import 'package:fca/features/category/data/repositories/category_repository_impl.dart';
import 'package:fca/features/category/domain/repositories/category_repository.dart';
import 'package:fca/features/category/domain/usecases/get_all_category_usecase.dart';
import 'package:fca/features/category/domain/usecases/get_category_usecase.dart';

import 'package:fca/features/category/presentation/bloc/category_bloc.dart';
import 'package:fca/features/visit/data/datasources/visit_remote_datasource.dart';
import 'package:fca/features/visit/data/repositories/visit_repository_impl.dart';
import 'package:fca/features/visit/domain/repositories/visit_repository.dart';
import 'package:fca/features/visit/domain/usecases/get_all_visit_usecase.dart';
import 'package:fca/features/visit/domain/usecases/get_visit_usecase.dart';
import 'package:fca/features/visit/presentation/bloc/visit_bloc.dart';

final sl = GetIt.instance;

Future<void> initDependencies() async {
  // ── 1. Infrastructure ─────────────────────────────────────

  sl.registerLazySingleton<FlutterSecureStorage>(
    () => const FlutterSecureStorage(
      aOptions: AndroidOptions(encryptedSharedPreferences: true),
    ),
  );

  sl.registerLazySingleton<SecureStorageService>(
    () => SecureStorageService(sl<FlutterSecureStorage>()),
  );

  sl.registerLazySingleton<AuthInterceptor>(
    () => AuthInterceptor(sl<SecureStorageService>()),
  );

  // Single Dio instance shared by ALL features
  sl.registerLazySingleton<Dio>(
    () => buildSecureDioClient(authInterceptor: sl<AuthInterceptor>()),
  );

  // ── 2. Auth datasources ───────────────────────────────────

  sl.registerLazySingleton<AuthLocalDataSource>(
    () => AuthLocalDataSourceImpl(sl<SecureStorageService>()),
  );

  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(sl<Dio>()),
  );

  // ── 3. Auth repository ────────────────────────────────────

  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      remote: sl<AuthRemoteDataSource>(),
      local: sl<AuthLocalDataSource>(),
    ),
  );

  // ── 4. Auth use cases ─────────────────────────────────────

  sl.registerLazySingleton(() => LoginUseCase(sl<AuthRepository>()));
  sl.registerLazySingleton(() => RegisterUseCase(sl<AuthRepository>()));
  sl.registerLazySingleton(() => LogoutUseCase(sl<AuthRepository>()));
  sl.registerLazySingleton(() => LogoutAccountUseCase(sl<AuthRepository>()));
  sl.registerLazySingleton(() => SwitchAccountUseCase(sl<AuthRepository>()));
  sl.registerLazySingleton(() => GetActiveSessionUseCase(sl<AuthRepository>()));
  sl.registerLazySingleton(() => GetSavedAccountsUseCase(sl<AuthRepository>()));
  sl.registerLazySingleton(() => RefreshSessionUseCase(sl<AuthRepository>()));

  // ── 5. Auth BLoC (factory — fresh per widget tree) ────────

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

  // ── 6. Profile datasource + repository + use case ─────────

  sl.registerLazySingleton<ProfileRemoteDataSource>(
    () => ProfileRemoteDataSourceImpl(sl<Dio>()),
  );

  sl.registerLazySingleton<ProfileRepository>(
    () => ProfileRepositoryImpl(sl<ProfileRemoteDataSource>()),
  );

  sl.registerLazySingleton(() => GetProfileUseCase(sl<ProfileRepository>()));

  // ── 7. Profile BLoC (factory) ─────────────────────────────

  sl.registerFactory<ProfileBloc>(() => ProfileBloc(sl<GetProfileUseCase>()));

  // ── GENERATOR MANAGED

  // ── Visit (generated 2026-02-27) ─────────
  sl.registerLazySingleton<VisitRemoteDataSource>(
    () => VisitRemoteDataSourceImpl(dio: sl()),
  );
  sl.registerLazySingleton<VisitRepository>(
    () => VisitRepositoryImpl(remoteDataSource: sl()),
  );
  sl.registerLazySingleton(() => GetAllVisitUseCase(sl()));
  sl.registerLazySingleton(() => GetVisitUseCase(sl()));
  sl.registerLazySingleton(() => CreateVisitUseCase(sl()));
  sl.registerLazySingleton(() => UpdateVisitUseCase(sl()));
  sl.registerLazySingleton(() => DeleteVisitUseCase(sl()));
  sl.registerFactory<VisitBloc>(() => VisitBloc(getAllUseCase: sl(), getUseCase: sl(), createUseCase: sl(), updateUseCase: sl(), deleteUseCase: sl()));

  // ── Category (generated 2026-02-27) ─────────

  sl.registerLazySingleton<CategoryRemoteDataSource>(
    () => CategoryRemoteDataSourceImpl(dio: sl()),
  );
  sl.registerLazySingleton<CategoryRepository>(
    () => CategoryRepositoryImpl(remoteDataSource: sl()),
  );
  sl.registerLazySingleton(() => GetAllCategoryUseCase(sl()));
  sl.registerLazySingleton(() => GetCategoryUseCase(sl()));
  sl.registerLazySingleton(() => CreateCategoryUseCase(sl()));
  sl.registerLazySingleton(() => UpdateCategoryUseCase(sl()));
  sl.registerLazySingleton(() => DeleteCategoryUseCase(sl()));
  sl.registerFactory<CategoryBloc>(
    () => CategoryBloc(
      getAllUseCase: sl(),
      getUseCase: sl(),
      createUseCase: sl(),
      updateUseCase: sl(),
      deleteUseCase: sl(),
    ),
  );

  sl.registerLazySingleton<HelloRemoteDataSource>(
    () => HelloRemoteDataSourceImpl(dio: sl()),
  );
  sl.registerLazySingleton<HelloRepository>(
    () => HelloRepositoryImpl(remoteDataSource: sl()),
  );
  sl.registerLazySingleton(() => GetAllHelloUseCase(sl()));
  sl.registerLazySingleton(() => GetHelloUseCase(sl()));
  sl.registerLazySingleton(() => CreateHelloUseCase(sl()));
  sl.registerLazySingleton(() => UpdateHelloUseCase(sl()));
  sl.registerLazySingleton(() => DeleteHelloUseCase(sl()));
  sl.registerFactory<HelloBloc>(
    () => HelloBloc(
      getAllUseCase: sl(),
      getUseCase: sl(),
      createUseCase: sl(),
      updateUseCase: sl(),
      deleteUseCase: sl(),
    ),
  );


}








