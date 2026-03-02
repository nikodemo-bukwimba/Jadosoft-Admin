// injection_container.dart
// ─────────────────────────────────────────────────────────────
// Full GetIt registrations — bottom-up order:
//   infrastructure → datasources → repositories → use cases → BLoCs
// ─────────────────────────────────────────────────────────────

// ── END GENERATOR FEATURE IMPORTS
import 'package:dio/dio.dart';
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

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';


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


  // ── END GENERATOR MANAGED
}

