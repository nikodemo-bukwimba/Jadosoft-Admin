// auth_repository_impl.dart
// ─────────────────────────────────────────────────────────────
// FIX: Token must be persisted to secure storage BEFORE any
// authenticated request (GET /me/roles) is made.
// Previous order:  login → fetch roles → save session   ❌
// Correct order:   login → save token → fetch roles → update session ✅
//
// FIX 2: UserModel.id is now String (ULID). _placeholderUser
// uses id: '' instead of id: 0.
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

      // ── Step 2: Parse user ────────────────────────────────
      UserModel user;
      if (loginData.containsKey('user') && loginData['user'] != null) {
        user = UserModel.fromJson(loginData['user'] as Map<String, dynamic>);
      } else {
        // Sanctum setups that return only token — need separate /user call.
        // Save a temporary session first so the interceptor has a token.
        final tempSession = AccountSessionModel(
          token: token,
          user: _placeholderUser(email),
          permissions: const [],
          savedAt: DateTime.now(),
        );
        await _local.saveSession(tempSession);
        await _local.setActiveAccount(email);
        user = await _remote.getUser();
      }

      // ── Step 3: Persist token FIRST so interceptor can use it ──
      final prelimSession = AccountSessionModel(
        token: token,
        user: user,
        permissions: const [],
        savedAt: DateTime.now(),
      );
      await _local.saveSession(prelimSession);
      await _local.setActiveAccount(user.email);

      // ── Step 4: Fetch roles + permissions ─────────────────
      List<PermissionModel> permissions = [];
      try {
        final rolesData = await _remote.getRolesAndPermissions();
        final rawPerms = rolesData['permissions'] as List<dynamic>? ?? [];
        permissions = rawPerms
            .map((p) => PermissionModel.fromJson(p as Map<String, dynamic>))
            .toList();
      } catch (_) {
        // Roles fetch failed — allow login with empty permissions.
        // Refresh later via AuthSessionRefreshRequested.
      }

      // ── Step 5: Save final session with permissions ───────
      final finalSession = AccountSessionModel(
        token: token,
        user: user,
        permissions: permissions,
        savedAt: DateTime.now(),
      );
      await _local.saveSession(finalSession);

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

      // ── Step 2: Parse user ────────────────────────────────
      UserModel user;
      if (registerData.containsKey('user') && registerData['user'] != null) {
        user = UserModel.fromJson(registerData['user'] as Map<String, dynamic>);
      } else {
        final tempSession = AccountSessionModel(
          token: token,
          user: _placeholderUser(email),
          permissions: const [],
          savedAt: DateTime.now(),
        );
        await _local.saveSession(tempSession);
        await _local.setActiveAccount(email);
        user = await _remote.getUser();
      }

      // ── Step 3: Persist token BEFORE /me/roles ────────────
      final prelimSession = AccountSessionModel(
        token: token,
        user: user,
        permissions: const [],
        savedAt: DateTime.now(),
      );
      await _local.saveSession(prelimSession);
      await _local.setActiveAccount(user.email);

      // ── Step 4: Fetch roles ───────────────────────────────
      List<PermissionModel> permissions = [];
      try {
        final rolesData = await _remote.getRolesAndPermissions();
        final rawPerms = rolesData['permissions'] as List<dynamic>? ?? [];
        permissions = rawPerms
            .map((p) => PermissionModel.fromJson(p as Map<String, dynamic>))
            .toList();
      } catch (_) {
        // New users may have no roles yet — continue
      }

      // ── Step 5: Final session ─────────────────────────────
      final finalSession = AccountSessionModel(
        token: token,
        user: user,
        permissions: permissions,
        savedAt: DateTime.now(),
      );
      await _local.saveSession(finalSession);

      return Right(finalSession);
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
  @override
  Future<Either<Failure, AccountSession>> refreshSession() async {
    try {
      final current = await _local.getActiveSession();
      if (current == null) {
        return const Left(AuthFailure('No active session to refresh'));
      }

      final user = await _remote.getUser();
      final rolesData = await _remote.getRolesAndPermissions();
      final rawPerms = rolesData['permissions'] as List<dynamic>? ?? [];
      final permissions = rawPerms
          .map((p) => PermissionModel.fromJson(p as Map<String, dynamic>))
          .toList();

      final updated = AccountSessionModel(
        token: current.token,
        user: user,
        permissions: permissions,
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
  // Temporary stand-in when the API returns only a token and we need
  // storage populated before calling /user or /me/roles.
  UserModel _placeholderUser(String email) => UserModel(
    id: '', // String — ULID, filled after /user call
    name: '',
    email: email,
    isActive: false,
    hasActiveSubscription: false,
    subscriptionStatus: 'none',
  );
}
