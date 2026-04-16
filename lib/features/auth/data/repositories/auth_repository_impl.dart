// auth_repository_impl.dart
// ─────────────────────────────────────────────────────────────
// FLOW (login & register):
//   1. POST /auth/login (or /register) → get token
//   2. Save preliminary session so interceptor has a token
//   3. GET /auth/me (no org_id) → server picks best membership
//   4. Server returns user.org_id → we persist it in OrgContext
//   5. Save final session
//
// On refreshSession:
//   - Read stored org_id from OrgContext
//   - Pass it to getAuthMe(orgId:) → correct permissions every time
//
// This eliminates the hardcoded AppConstants.orgId from the auth flow.
// ─────────────────────────────────────────────────────────────

import 'package:dartz/dartz.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/context/org_context.dart';
import '../../domain/entities/account_session.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_local_datasource.dart';
import '../datasources/auth_remote_datasource.dart';
import '../models/account_session_model.dart';
import '../models/user_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remote;
  final AuthLocalDataSource _local;
  final OrgContext _orgContext;

  AuthRepositoryImpl({
    required AuthRemoteDataSource remote,
    required AuthLocalDataSource local,
    required OrgContext orgContext,
  }) : _remote = remote,
       _local = local,
       _orgContext = orgContext;

  // ── login ─────────────────────────────────────────────────
  @override
  Future<Either<Failure, AccountSession>> login({
    required String email,
    required String password,
  }) async {
    try {
      // Step 1: Authenticate
      final loginData = await _remote.login(email, password);
      final token = AuthRemoteDataSourceImpl.extractToken(loginData);
      if (token == null) {
        return const Left(ServerFailure('No token received from server'));
      }

      // Step 2: Save preliminary session so interceptor has a token
      final prelimSession = AccountSessionModel(
        token: token,
        user: _placeholderUser(email),
        permissions: const [],
        savedAt: DateTime.now(),
      );
      await _local.saveSession(prelimSession);
      await _local.setActiveAccount(email);

      // Step 3: Fetch full profile — no org_id on first call.
      // Server picks the user's highest-level active membership.
      final meResponse = await _remote.getAuthMe();

      // Step 4: Persist the resolved org_id in OrgContext so
      // refreshSession() can pass it back on the next call.
      if (meResponse.resolvedOrgId != null) {
        await _persistOrgId(meResponse.resolvedOrgId!, meResponse.user.actorId, meResponse.user.name);
      }

      // Step 5: Save final session
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
      final registerData = await _remote.register(
        name: name,
        email: email,
        password: password,
        passwordConfirmation: passwordConfirmation,
        phone: phone,
      );

      final token = AuthRemoteDataSourceImpl.extractToken(registerData);
      if (token == null) {
        return const Left(ServerFailure('No token received after registration'));
      }

      final prelimSession = AccountSessionModel(
        token: token,
        user: _placeholderUser(email),
        permissions: const [],
        savedAt: DateTime.now(),
      );
      await _local.saveSession(prelimSession);
      await _local.setActiveAccount(email);

      // New registrants have no membership yet → no org_id needed
      final meResponse = await _remote.getAuthMe();

      if (meResponse.resolvedOrgId != null) {
        await _persistOrgId(meResponse.resolvedOrgId!, meResponse.user.actorId, meResponse.user.name);
      }

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

  // ── logout ────────────────────────────────────────────────
  @override
  Future<Either<Failure, void>> logout() async {
    try {
      final activeEmail = await _local.getActiveEmail();
      try { await _remote.logout(); } catch (_) {}
      if (activeEmail != null) await _local.removeSession(activeEmail);
      await _orgContext.clear();
      return const Right(null);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(GenericFailure(e.toString()));
    }
  }

  // ── logoutAccount ─────────────────────────────────────────
  @override
  Future<Either<Failure, void>> logoutAccount(String email) async {
    try {
      final activeEmail = await _local.getActiveEmail();
      if (activeEmail == email) {
        try { await _remote.logout(); } catch (_) {}
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
      return Right(await _local.getAllSessions());
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
      return Right(await _local.getActiveSession());
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
      if (target == null) return Left(AuthFailure('No saved session found for $email'));
      await _local.setActiveAccount(email);
      return Right(target);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(GenericFailure(e.toString()));
    }
  }

  // ── refreshSession ────────────────────────────────────────
  // Uses the org_id stored in OrgContext so branch/officer users
  // always get the correct permission set for their membership org.
  @override
  Future<Either<Failure, AccountSession>> refreshSession() async {
    try {
      final current = await _local.getActiveSession();
      if (current == null) return const Left(AuthFailure('No active session to refresh'));

      // Use persisted org_id (from OrgContext) for correct scoping
      await _orgContext.restore();
      final storedOrgId = _orgContext.rootOrgId;

      final meResponse = await _remote.getAuthMe(orgId: storedOrgId);

      // Update stored org_id if server returned one
      if (meResponse.resolvedOrgId != null) {
        await _persistOrgId(meResponse.resolvedOrgId!, meResponse.user.actorId, meResponse.user.name);
      }

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

  // ── Helpers ───────────────────────────────────────────────

  Future<void> _persistOrgId(String orgId, String? actorId, String actorName) async {
    await _orgContext.restore();
    await _orgContext.setRootOrg(
      id: orgId,
      name: _orgContext.rootOrgName ?? 'Barick Pharmacy',
      role: _orgContext.orgRole != OrgRole.unknown
          ? _orgContext.orgRole
          : OrgRole.orgAdmin,
      actorId: actorId,
      actorName: actorName,
    );
  }

  UserModel _placeholderUser(String email) => UserModel(
    id: '',
    name: '',
    email: email,
    isActive: false,
    hasActiveSubscription: false,
    subscriptionStatus: 'none',
  );
}