# ============================================================
# CFA — Flutter Project Scaffold Script
# Generates the full lib/ directory structure with placeholder
# .dart files. Security-first ordering.
# ============================================================

$base = "lib"

# ─── Helper functions ────────────────────────────────────────

function New-Dir($path) {
    New-Item -ItemType Directory -Force -Path $path | Out-Null
}

function New-File($path, $content) {
    New-Item -ItemType File -Force -Path $path | Out-Null
    Set-Content -Path $path -Value $content
}

# ============================================================
# SECTION 1 — config/
# ============================================================

# config/di/
New-Dir "$base/config/di"
New-File "$base/config/di/injection_container.dart" @"
// injection_container.dart
// Register all GetIt dependencies here in strict bottom-up order:
// datasource -> repository -> use cases -> BLoC
// Use registerLazySingleton for shared services.
// Use registerFactory for BLoCs (fresh instance per widget tree).

import 'package:get_it/get_it.dart';

final sl = GetIt.instance;

Future<void> initDependencies() async {
  // TODO: register AppDatabase (async singleton — needs encryption key)
  // TODO: register DataSources
  // TODO: register Repositories
  // TODO: register UseCases
  // TODO: register BLoCs
}
"@

# config/routes/
New-Dir "$base/config/routes"
New-File "$base/config/routes/app_router.dart" @"
// app_router.dart
// GoRouter configuration.
// Use named routes only. For feature-internal sub-pages that need
// an existing BLoC, use Navigator + BlocProvider.value instead.

import 'package:go_router/go_router.dart';

class RouteNames {
  static const login     = '/login';
  static const dashboard = '/dashboard';
  // TODO: add feature routes here
}

final appRouter = GoRouter(
  initialLocation: RouteNames.login,
  routes: [
    // TODO: define GoRoute entries here
  ],
);
"@

# config/theme/
New-Dir "$base/config/theme"
New-File "$base/config/theme/app_colors.dart" @"
// app_colors.dart
// Central color constants for the entire app.
// No business logic here — visual tokens only.

import 'package:flutter/material.dart';

class AppColors {
  AppColors._();
  // TODO: define brand color constants
  // static const Color primary = Color(0xFF000000);
}
"@

# ============================================================
# SECTION 2 — core/  (security-critical modules first)
# ============================================================

# ── 2a. core/storage/  (R2 — secure storage wrapper) ────────
New-Dir "$base/core/storage"
New-File "$base/core/storage/secure_storage_service.dart" @"
// secure_storage_service.dart  [R2 — Secure Device Storage]
// Central wrapper around flutter_secure_storage.
// ALL tokens, encryption keys, and credentials must go through
// this service. Never use SharedPreferences for sensitive data.

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  final FlutterSecureStorage _storage;
  SecureStorageService(this._storage);

  Future<String?> read(String key)               => _storage.read(key: key);
  Future<void>    write(String key, String value) => _storage.write(key: key, value: value);
  Future<void>    delete(String key)              => _storage.delete(key: key);
  Future<void>    deleteAll()                     => _storage.deleteAll();
}
"@

New-File "$base/core/storage/db_key_service.dart" @"
// db_key_service.dart  [R2 — Database Encryption Key Management]
// Generates and securely stores the SQLCipher encryption key.
// Key is created once, stored in Keychain/Keystore via
// flutter_secure_storage, and NEVER hardcoded.

import 'secure_storage_service.dart';

class DbKeyService {
  final SecureStorageService _secureStorage;
  static const _keyName = 'db_encryption_key';

  DbKeyService(this._secureStorage);

  Future<String> getOrCreateDbKey() async {
    var key = await _secureStorage.read(_keyName);
    if (key == null) {
      key = _generateSecureRandom32Bytes();
      await _secureStorage.write(_keyName, key);
    }
    return key;
  }

  String _generateSecureRandom32Bytes() {
    // TODO: implement using dart:math SecureRandom or pointycastle
    throw UnimplementedError('Implement secure random key generation');
  }
}
"@

# ── 2b. core/network/  (R3, R4 — secure network layer) ──────
New-Dir "$base/core/network"
New-File "$base/core/network/dio_client.dart" @"
// dio_client.dart  [R3 — Secure Network Communication]
// Single shared Dio instance for the entire app.
// Rules enforced here:
//   - HTTPS only (no http:// in production)
//   - Certificate pinning on sensitive endpoints
//   - Timeouts: connectTimeout 15s, receiveTimeout 30s
//   - All requests go through this client — never create a
//     new Dio or http.Client instance inside a datasource.

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/foundation.dart';
import 'auth_interceptor.dart';
import 'logging_interceptor.dart';

Dio buildSecureDioClient() {
  final dio = Dio(BaseOptions(
    baseUrl: 'https://api.CFA.com/v1', // always https — R3
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 30),
    headers: {'Content-Type': 'application/json'},
  ));

  dio.interceptors.addAll([
    AuthInterceptor(),      // attaches Bearer token — R4
    LoggingInterceptor(),   // debug only — R9
    // TODO: add RetryInterceptor for token refresh on 401
  ]);

  // Certificate pinning — R3
  (dio.httpClientAdapter as IOHttpClientAdapter).onHttpClientCreate = (client) {
    client.badCertificateCallback = (cert, host, port) => false;
    // TODO: implement certificate fingerprint / trusted cert pinning
    return client;
  };

  return dio;
}
"@

New-File "$base/core/network/auth_interceptor.dart" @"
// auth_interceptor.dart  [R4 — Token Management]
// Attaches Bearer token to every request.
// Handles 401 by attempting token refresh.
// Forces full logout if refresh fails — wipes all tokens and state.
// Token refresh is transparent to the user and to individual BLoCs.

import 'package:dio/dio.dart';
import '../storage/secure_storage_service.dart';

class AuthInterceptor extends Interceptor {
  final SecureStorageService _storage;
  AuthInterceptor(this._storage);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await _storage.read('access_token');
    if (token != null) {
      options.headers['Authorization'] = 'Bearer \$token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException error, ErrorInterceptorHandler handler) async {
    if (error.response?.statusCode == 401) {
      final refreshed = await _tryRefreshToken();
      if (refreshed) {
        // TODO: retry original request with new token
        handler.next(error);
      } else {
        await _forceLogout(); // wipe everything — R4
        handler.next(error);
      }
    } else {
      handler.next(error);
    }
  }

  Future<bool> _tryRefreshToken() async {
    // TODO: call refresh endpoint, store new access token
    return false;
  }

  Future<void> _forceLogout() async {
    // TODO: delete all tokens, clear DB, navigate to login
    await _storage.deleteAll();
  }
}
"@

New-File "$base/core/network/logging_interceptor.dart" @"
// logging_interceptor.dart  [R9 — Logging & Debug Output]
// Logs only in debug mode. NEVER logs tokens, keys, PII,
// or response bodies in production.
// Guarded by kDebugMode — disabled automatically in release builds.

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (kDebugMode) {
      // Log method + path only — never log headers (contain Bearer token)
      print('[REQUEST] \${options.method} \${options.path}');
    }
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (kDebugMode) {
      // Log status code only — never log response.data (may contain PII)
      print('[RESPONSE] \${response.statusCode} \${response.realUri}');
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (kDebugMode) {
      print('[ERROR] \${err.response?.statusCode} \${err.message}');
    }
    handler.next(err);
  }
}
"@

# ── 2c. core/database/  (R2 — encrypted Drift DB) ───────────
New-Dir "$base/core/database/tables"
New-File "$base/core/database/app_database.dart" @"
// app_database.dart  [R2 — Encrypted Local Database]
// Drift database definition.
// RULES:
//   - Database must be encrypted via SQLCipher — key from DbKeyService
//   - schemaVersion must be incremented on every schema change
//   - Migrations are additive only — never modify or drop existing columns
//   - Date range queries use explicit DateTime constructors (never .month/.year)

import 'package:drift/drift.dart';
// TODO: import all feature tables
// TODO: import all DAOs

// @DriftDatabase(tables: [...], daos: [...])
class AppDatabase extends _\$AppDatabase {
  AppDatabase(QueryExecutor e) : super(e);

  @override
  int get schemaVersion => 1; // increment on every schema change

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (migrator, from, to) async {
      // if (from < 2) { await migrator.addColumn(...); }
      // if (from < 3) { await migrator.createTable(...); }
    },
  );
}
"@

New-File "$base/core/database/app_database.g.dart" @"
// app_database.g.dart
// Auto-generated by build_runner. Do not edit manually.
// Run: flutter pub run build_runner build --delete-conflicting-outputs
"@

New-File "$base/core/database/tables/.gitkeep" ""

# ── 2d. core/error/ ──────────────────────────────────────────
New-Dir "$base/core/error"
New-File "$base/core/error/exceptions.dart" @"
// exceptions.dart
// Raw exceptions thrown by datasources.
// These are caught in repository implementations and mapped
// to Failures before reaching the domain layer.

class CacheException implements Exception {
  final String message;
  CacheException(this.message);
}

class ServerException implements Exception {
  final String message;
  ServerException(this.message);
}

class AuthException implements Exception {
  final String message;
  AuthException(this.message);
}
"@

New-File "$base/core/error/failures.dart" @"
// failures.dart
// Domain-layer error types returned via Either<Failure, T>.
// UI and BLoCs handle these — never raw exceptions.

abstract class Failure {
  final String message;
  const Failure(this.message);
}

class CacheFailure     extends Failure { CacheFailure(super.message); }
class ServerFailure    extends Failure { ServerFailure(super.message); }
class AuthFailure      extends Failure { AuthFailure(super.message); }
class ValidationFailure extends Failure { ValidationFailure(super.message); }
class GenericFailure   extends Failure { GenericFailure(super.message); }
"@

# ── 2e. core/usecase/ ────────────────────────────────────────
New-Dir "$base/core/usecase"
New-File "$base/core/usecase/usecase.dart" @"
// usecase.dart
// Abstract base for all use cases.
// Every use case takes Params and returns Either<Failure, Type>.
// Use NoParams when no input is needed.

import 'package:dartz/dartz.dart';
import '../error/failures.dart';

abstract class UseCase<Type, Params> {
  Future<Either<Failure, Type>> call(Params params);
}

class NoParams {}
"@

# ============================================================
# SECTION 3 — features/auth/  (full Clean Architecture layers)
# ============================================================

# domain
New-Dir "$base/features/auth/domain/entities"
New-Dir "$base/features/auth/domain/repositories"
New-Dir "$base/features/auth/domain/usecases"

New-File "$base/features/auth/domain/entities/user_entity.dart" @"
// user_entity.dart
// Pure Dart class — no Flutter or Drift imports.
// Represents the authenticated user in the domain layer.

class UserEntity {
  final String id;
  final String email;
  // TODO: add domain fields

  const UserEntity({required this.id, required this.email});
}
"@

New-File "$base/features/auth/domain/repositories/auth_repository.dart" @"
// auth_repository.dart
// Abstract interface — implemented in data layer.
// Domain layer depends on this abstraction, never on the concrete impl.

import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/user_entity.dart';

abstract class AuthRepository {
  Future<Either<Failure, UserEntity>> login(String email, String password);
  Future<Either<Failure, void>>       logout();
  Future<Either<Failure, UserEntity>> getCurrentUser();
}
"@

New-File "$base/features/auth/domain/usecases/login_usecase.dart" @"
// login_usecase.dart  [R5 — Two-Gate Input Validation]
// Security gate: validates all input before calling the repository.
// This gate runs for ALL callers — it is the real security boundary.
// UI validation is UX only and must never be the sole defence.

import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

class LoginParams {
  final String email;
  final String password;
  LoginParams({required this.email, required this.password});
}

class LoginUseCase implements UseCase<UserEntity, LoginParams> {
  final AuthRepository repository;
  LoginUseCase(this.repository);

  @override
  Future<Either<Failure, UserEntity>> call(LoginParams p) async {
    // Security gate — R5
    if (p.email.isEmpty)    return Left(ValidationFailure('Email required'));
    if (p.password.isEmpty)  return Left(ValidationFailure('Password required'));
    if (p.password.length < 8) return Left(ValidationFailure('Password too short'));
    // TODO: add email format validation
    return repository.login(p.email, p.password);
  }
}
"@

New-File "$base/features/auth/domain/usecases/logout_usecase.dart" @"
// logout_usecase.dart  [R2 — Secure Logout]
// Clears all tokens and local database on logout.
// No session data may persist after this call.

import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/auth_repository.dart';

class LogoutUseCase implements UseCase<void, NoParams> {
  final AuthRepository repository;
  LogoutUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(NoParams params) {
    return repository.logout();
  }
}
"@

# data
New-Dir "$base/features/auth/data/models"
New-Dir "$base/features/auth/data/datasources"
New-Dir "$base/features/auth/data/repositories"

New-File "$base/features/auth/data/models/user_model.dart" @"
// user_model.dart
// Extends UserEntity with serialization logic.
// Handles fromJson / toJson for remote datasource.

import '../../domain/entities/user_entity.dart';

class UserModel extends UserEntity {
  const UserModel({required super.id, required super.email});

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id:    json['id']    as String,
      email: json['email'] as String,
    );
  }

  Map<String, dynamic> toJson() => {'id': id, 'email': email};
}
"@

New-File "$base/features/auth/data/datasources/auth_remote_datasource.dart" @"
// auth_remote_datasource.dart  [R3 — Secure Network]
// All requests go through the shared Dio client from core/network/.
// Never create a new Dio instance here.
// Malformed server responses must throw ServerException — not crash.

import 'package:dio/dio.dart';
import '../../../../core/error/exceptions.dart';
import '../models/user_model.dart';

abstract class AuthRemoteDataSource {
  Future<UserModel> login(String email, String password);
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final Dio dio;
  AuthRemoteDataSourceImpl(this.dio);

  @override
  Future<UserModel> login(String email, String password) async {
    try {
      final response = await dio.post('/auth/login', data: {
        'email': email,
        'password': password,
      });
      return UserModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(e.message ?? 'Network error');
    } catch (e) {
      throw ServerException(e.toString());
    }
  }
}
"@

New-File "$base/features/auth/data/repositories/auth_repository_impl.dart" @"
// auth_repository_impl.dart
// Implements the domain AuthRepository interface.
// Maps datasource exceptions to domain Failures via Either.
// Never leaks exceptions to the domain or presentation layers.

import 'package:dartz/dartz.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  AuthRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, UserEntity>> login(String email, String password) async {
    try {
      final user = await remoteDataSource.login(email, password);
      return Right(user);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(GenericFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> logout() async {
    // TODO: call secure logout — clear tokens + drop DB
    return const Right(null);
  }

  @override
  Future<Either<Failure, UserEntity>> getCurrentUser() async {
    // TODO: fetch from secure storage / remote
    return Left(AuthFailure('Not implemented'));
  }
}
"@

# presentation
New-Dir "$base/features/auth/presentation/bloc"
New-Dir "$base/features/auth/presentation/pages"
New-Dir "$base/features/auth/presentation/widgets"

New-File "$base/features/auth/presentation/bloc/auth_event.dart" @"
// auth_event.dart
// All events that can be sent to AuthBloc.
// UI triggers events — never calls use cases directly.

abstract class AuthEvent {}

class LoginRequested extends AuthEvent {
  final String email;
  final String password;
  LoginRequested({required this.email, required this.password});
}

class LogoutRequested extends AuthEvent {}
"@

New-File "$base/features/auth/presentation/bloc/auth_state.dart" @"
// auth_state.dart
// All states that AuthBloc can emit.
// UI reacts to states — no business logic in widgets.

import '../../domain/entities/user_entity.dart';

abstract class AuthState {}

class AuthInitial  extends AuthState {}
class AuthLoading  extends AuthState {}
class AuthSuccess  extends AuthState {
  final UserEntity user;
  AuthSuccess(this.user);
}
class AuthFailureState extends AuthState {
  final String message;
  AuthFailureState(this.message);
}
"@

New-File "$base/features/auth/presentation/bloc/auth_bloc.dart" @"
// auth_bloc.dart
// Orchestrates auth flow: receives events, calls use cases, emits states.
// No business logic here — delegate everything to use cases.
// No direct repository or datasource calls.

import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/usecase/usecase.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/logout_usecase.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final LoginUseCase  loginUseCase;
  final LogoutUseCase logoutUseCase;

  AuthBloc({required this.loginUseCase, required this.logoutUseCase})
      : super(AuthInitial()) {
    on<LoginRequested>(_onLoginRequested);
    on<LogoutRequested>(_onLogoutRequested);
  }

  Future<void> _onLoginRequested(LoginRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    final result = await loginUseCase(LoginParams(
      email: event.email, password: event.password,
    ));
    result.fold(
      (failure) => emit(AuthFailureState(failure.message)),
      (user)    => emit(AuthSuccess(user)),
    );
  }

  Future<void> _onLogoutRequested(LogoutRequested event, Emitter<AuthState> emit) async {
    await logoutUseCase(NoParams());
    emit(AuthInitial());
  }
}
"@

New-File "$base/features/auth/presentation/pages/login_page.dart" @"
// login_page.dart
// Display only — no business logic.
// Collects user input and dispatches events to AuthBloc.
// Reacts to AuthState changes via BlocBuilder/BlocListener.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthSuccess) {
            // TODO: navigate to dashboard
          } else if (state is AuthFailureState) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
        },
        child: const Center(
          child: Text('TODO: build login form'),
        ),
      ),
    );
  }
}
"@

New-File "$base/features/auth/presentation/widgets/.gitkeep" ""

# ============================================================
# SECTION 4 — features/dashboard/  (full Clean Architecture layers)
# ============================================================

New-Dir "$base/features/dashboard/domain/entities"
New-Dir "$base/features/dashboard/domain/repositories"
New-Dir "$base/features/dashboard/domain/usecases"
New-Dir "$base/features/dashboard/data/models"
New-Dir "$base/features/dashboard/data/datasources"
New-Dir "$base/features/dashboard/data/repositories"
New-Dir "$base/features/dashboard/presentation/bloc"
New-Dir "$base/features/dashboard/presentation/pages"
New-Dir "$base/features/dashboard/presentation/widgets"

New-File "$base/features/dashboard/domain/entities/.gitkeep" ""
New-File "$base/features/dashboard/domain/repositories/.gitkeep" ""
New-File "$base/features/dashboard/domain/usecases/.gitkeep" ""
New-File "$base/features/dashboard/data/models/.gitkeep" ""
New-File "$base/features/dashboard/data/datasources/.gitkeep" ""
New-File "$base/features/dashboard/data/repositories/.gitkeep" ""

New-File "$base/features/dashboard/presentation/bloc/dashboard_event.dart" @"
// dashboard_event.dart
abstract class DashboardEvent {}

class DashboardLoaded extends DashboardEvent {}
"@

New-File "$base/features/dashboard/presentation/bloc/dashboard_state.dart" @"
// dashboard_state.dart
abstract class DashboardState {}

class DashboardInitial extends DashboardState {}
class DashboardLoading extends DashboardState {}
class DashboardReady   extends DashboardState {}
class DashboardError   extends DashboardState {
  final String message;
  DashboardError(this.message);
}
"@

New-File "$base/features/dashboard/presentation/bloc/dashboard_bloc.dart" @"
// dashboard_bloc.dart
// Aggregates data from all feature BLoCs/use cases for the home screen.
// No business logic here — delegate to use cases.

import 'package:flutter_bloc/flutter_bloc.dart';
import 'dashboard_event.dart';
import 'dashboard_state.dart';

class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  DashboardBloc() : super(DashboardInitial()) {
    on<DashboardLoaded>(_onLoaded);
  }

  Future<void> _onLoaded(DashboardLoaded event, Emitter<DashboardState> emit) async {
    emit(DashboardLoading());
    // TODO: call use cases and aggregate results
    emit(DashboardReady());
  }
}
"@

New-File "$base/features/dashboard/presentation/pages/dashboard_page.dart" @"
// dashboard_page.dart
// Display only — aggregates widgets from all features.
// No business logic. Triggers DashboardLoaded on init.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/dashboard_bloc.dart';
import '../bloc/dashboard_event.dart';
import '../bloc/dashboard_state.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    context.read<DashboardBloc>().add(DashboardLoaded());
    return Scaffold(
      body: BlocBuilder<DashboardBloc, DashboardState>(
        builder: (context, state) {
          if (state is DashboardLoading) return const CircularProgressIndicator();
          if (state is DashboardReady)   return const Center(child: Text('Dashboard'));
          if (state is DashboardError)   return Center(child: Text(state.message));
          return const SizedBox.shrink();
        },
      ),
    );
  }
}
"@

New-File "$base/features/dashboard/presentation/widgets/.gitkeep" ""

# ============================================================
# Done
# ============================================================

Write-Host ""
Write-Host "============================================================" -ForegroundColor Green
Write-Host " CFA scaffold complete." -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Green
Write-Host ""
Write-Host " Structure created under: .\$base\" -ForegroundColor Cyan
Write-Host ""
Write-Host " Next steps:" -ForegroundColor Yellow
Write-Host "  1. Run: flutter pub add flutter_bloc dartz get_it go_router drift flutter_secure_storage dio"
Write-Host "  2. Run: flutter pub add --dev build_runner drift_dev"
Write-Host "  3. Run: flutter pub run build_runner build --delete-conflicting-outputs"
Write-Host "  4. Register all dependencies in injection_container.dart"
Write-Host "  5. Add your first feature using the checklist in the architecture doc"
Write-Host ""