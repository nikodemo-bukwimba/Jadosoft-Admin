// auth_repository_impl.dart
// ─────────────────────────────────────────────────────────────
// FLOW (login & register):
//   1. POST /auth/login (or /register) → get token
//   2. Parse user from login response (if present)
//   3. Save preliminary session (token only) so interceptor works
//   4. GET /auth/me → full user + roles + permissions
//   5. Save final session with everything
//
// Single endpoint for user data: GET /auth/me returns user, roles,
// and permissions in one response. No separate /me/roles call.
// ─────────────────────────────────────────────────────────────

import 'package:dartz/dartz.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/account_session.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_local_datasource.dart';
import '../datasources/auth_remote_datasource.dart';
import '../models/account_session_model.dart';
import '../models/user_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remote;
  final AuthLocalDataSource _local;

  AuthRepositoryImpl({
    required AuthRemoteDataSource remote,
    required AuthLocalDataSource local,
  }) : _remote = remote,
       _local = local;

  // ── login ─────────────────────────────────────────────────
  @override
  Future<Either<Failure, AccountSession>> login({
    required String email,
    required String password,
  }) async {
    try {
      // ── Step 1: Authenticate ─────────────────────────────
      final loginData = await _remote.login(email, password);
      final token = AuthRemoteDataSourceImpl.extractToken(loginData);
      if (token == null) {
        return const Left(ServerFailure('No token received from server'));
      }

      // ── Step 2: Save preliminary session so interceptor has token ──
      final prelimSession = AccountSessionModel(
        token: token,
        user: _placeholderUser(email),
        permissions: const [],
        savedAt: DateTime.now(),
      );
      await _local.saveSession(prelimSession);
      await _local.setActiveAccount(email);

      // ── Step 3: Fetch full profile (user + roles + permissions) ──
      final meResponse = await _remote.getAuthMe();

      // ── Step 4: Save final session ────────────────────────
      final finalSession = AccountSessionModel(
        token: token,
        user: meResponse.user,
        permissions: meResponse.permissions,
        savedAt: DateTime.now(),
      );
      await _local.saveSession(finalSession);
      await _local.setActiveAccount(meResponse.user.email);

      return Right(finalSession);
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(GenericFailure(e.toString()));
    }
  }

  // ── register ──────────────────────────────────────────────
  @override
  Future<Either<Failure, AccountSession>> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
    String? phone,
  }) async {
    try {
      // ── Step 1: Register ──────────────────────────────────
      final registerData = await _remote.register(
        name: name,
        email: email,
        password: password,
        passwordConfirmation: passwordConfirmation,
        phone: phone,
      );

      final token = AuthRemoteDataSourceImpl.extractToken(registerData);
      if (token == null) {
        return const Left(
          ServerFailure('No token received after registration'),
        );
      }

      // ── Step 2: Save preliminary session ──────────────────
      final prelimSession = AccountSessionModel(
        token: token,
        user: _placeholderUser(email),
        permissions: const [],
        savedAt: DateTime.now(),
      );
      await _local.saveSession(prelimSession);
      await _local.setActiveAccount(email);

      // ── Step 3: Fetch full profile ────────────────────────
      final meResponse = await _remote.getAuthMe();

      // ── Step 4: Save final session ────────────────────────
      final finalSession = AccountSessionModel(
        token: token,
        user: meResponse.user,
        permissions: meResponse.permissions,
        savedAt: DateTime.now(),
      );
      await _local.saveSession(finalSession);
      await _local.setActiveAccount(meResponse.user.email);

      return Right(finalSession);
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(GenericFailure(e.toString()));
    }
  }

  // ── logout (active account) ───────────────────────────────
  @override
  Future<Either<Failure, void>> logout() async {
    try {
      final activeEmail = await _local.getActiveEmail();
      try {
        await _remote.logout();
      } catch (_) {}
      if (activeEmail != null) {
        await _local.removeSession(activeEmail);
      }
      return const Right(null);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(GenericFailure(e.toString()));
    }
  }

  // ── logout specific account ───────────────────────────────
  @override
  Future<Either<Failure, void>> logoutAccount(String email) async {
    try {
      final activeEmail = await _local.getActiveEmail();
      if (activeEmail == email) {
        try {
          await _remote.logout();
        } catch (_) {}
      }
      await _local.removeSession(email);
      return const Right(null);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(GenericFailure(e.toString()));
    }
  }

  // ── getSavedAccounts ──────────────────────────────────────
  @override
  Future<Either<Failure, List<AccountSession>>> getSavedAccounts() async {
    try {
      final sessions = await _local.getAllSessions();
      return Right(sessions);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(GenericFailure(e.toString()));
    }
  }

  // ── getActiveSession ──────────────────────────────────────
  @override
  Future<Either<Failure, AccountSession?>> getActiveSession() async {
    try {
      final session = await _local.getActiveSession();
      return Right(session);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(GenericFailure(e.toString()));
    }
  }

  // ── switchAccount ─────────────────────────────────────────
  @override
  Future<Either<Failure, AccountSession>> switchAccount(String email) async {
    try {
      final sessions = await _local.getAllSessions();
      final target = sessions.where((s) => s.user.email == email).firstOrNull;
      if (target == null) {
        return Left(AuthFailure('No saved session found for $email'));
      }
      await _local.setActiveAccount(email);
      return Right(target);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(GenericFailure(e.toString()));
    }
  }

  // ── refreshSession ────────────────────────────────────────
  // Re-fetches user + roles + permissions from GET /auth/me.
  @override
  Future<Either<Failure, AccountSession>> refreshSession() async {
    try {
      final current = await _local.getActiveSession();
      if (current == null) {
        return const Left(AuthFailure('No active session to refresh'));
      }

      final meResponse = await _remote.getAuthMe();

      final updated = AccountSessionModel(
        token: current.token,
        user: meResponse.user,
        permissions: meResponse.permissions,
        savedAt: DateTime.now(),
      );
      await _local.saveSession(updated);
      return Right(updated);
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(GenericFailure(e.toString()));
    }
  }

  // ── Placeholder user ──────────────────────────────────────
  UserModel _placeholderUser(String email) => UserModel(
    id: '',
    name: '',
    email: email,
    isActive: false,
    hasActiveSubscription: false,
    subscriptionStatus: 'none',
  );
}
