// FILE: lib/features/auth/data/repositories/auth_repository_impl.dart
// CHANGE: Two places updated — both marked with ── NEW ──
//
//   1. _persistOrgAndBranch() replaces _persistOrgId().
//      After every /auth/me call we now also call orgContext.switchBranch()
//      with the branch that came back from the server.
//      Without this, OrgContext.activeBranchId was never updated even
//      when the session had the correct branchId.
//
//   2. refreshSession() now passes the root org ID (not the branch ID)
//      to getAuthMe() — using the branch ID was causing /auth/me to look
//      up the wrong membership and return no officer branch data.
//
// Everything else (login, register, logout, switchAccount, etc.) is
// structurally unchanged — only _persistOrgId() is renamed/extended.

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

  // ── login ──────────────────────────────────────────────────────────
  @override
  Future<Either<Failure, AccountSession>> login({
    required String email,
    required String password,
  }) async {
    try {
      final loginData = await _remote.login(email, password);
      final token = AuthRemoteDataSourceImpl.extractToken(loginData);
      if (token == null) {
        return const Left(ServerFailure('No token received from server'));
      }

      // Preliminary session so the interceptor has a token for /auth/me
      final prelimSession = AccountSessionModel(
        token: token,
        user: _placeholderUser(email),
        permissions: const [],
        savedAt: DateTime.now(),
      );
      await _local.saveSession(prelimSession);
      await _local.setActiveAccount(email);

      // /auth/me — no org_id on first call; server picks best membership
      final meResponse = await _remote.getAuthMe();

      // ── NEW: persist org AND branch into OrgContext ──────────────────
      if (meResponse.resolvedOrgId != null) {
        await _persistOrgAndBranch(
          orgId: meResponse.resolvedOrgId!,
          rootOrgId: meResponse.rootOrgId,
          actorId: meResponse.user.actorId,
          actorName: meResponse.user.name,
          branchId: meResponse.user.branchId,
          branchName: meResponse.user.branchName,
        );
      }
      // ─────────────────────────────────────────────────────────────────

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

  // ── register ───────────────────────────────────────────────────────
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
        return const Left(
          ServerFailure('No token received after registration'),
        );
      }

      final prelimSession = AccountSessionModel(
        token: token,
        user: _placeholderUser(email),
        permissions: const [],
        savedAt: DateTime.now(),
      );
      await _local.saveSession(prelimSession);
      await _local.setActiveAccount(email);

      final meResponse = await _remote.getAuthMe();

      // ── NEW ──────────────────────────────────────────────────────────
      if (meResponse.resolvedOrgId != null) {
        await _persistOrgAndBranch(
          orgId: meResponse.resolvedOrgId!,
          rootOrgId: meResponse.rootOrgId,
          actorId: meResponse.user.actorId,
          actorName: meResponse.user.name,
          branchId: meResponse.user.branchId,
          branchName: meResponse.user.branchName,
        );
      }
      // ─────────────────────────────────────────────────────────────────

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

  // ── logout ─────────────────────────────────────────────────────────
  @override
  Future<Either<Failure, void>> logout() async {
    try {
      final activeEmail = await _local.getActiveEmail();
      try {
        await _remote.logout();
      } catch (_) {}
      if (activeEmail != null) await _local.removeSession(activeEmail);
      await _orgContext.clear();
      return const Right(null);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(GenericFailure(e.toString()));
    }
  }

  // ── logoutAccount ──────────────────────────────────────────────────
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

  // ── getSavedAccounts ───────────────────────────────────────────────
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

  // ── getActiveSession ───────────────────────────────────────────────
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

  // ── switchAccount ──────────────────────────────────────────────────
  @override
  Future<Either<Failure, AccountSession>> switchAccount(String email) async {
    try {
      final sessions = await _local.getAllSessions();
      final target = sessions.where((s) => s.user.email == email).firstOrNull;
      if (target == null)
        return Left(AuthFailure('No saved session found for $email'));
      await _local.setActiveAccount(email);
      return Right(target);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(GenericFailure(e.toString()));
    }
  }

  // ── refreshSession ─────────────────────────────────────────────────
  @override
  Future<Either<Failure, AccountSession>> refreshSession() async {
    try {
      final current = await _local.getActiveSession();
      if (current == null) {
        return const Left(AuthFailure('No active session to refresh'));
      }

      await _orgContext.restore();

      // ── CHANGE: pass rootOrgId, not activeBranchId ──────────────────
      // Previously storedOrgId = _orgContext.rootOrgId, but if OrgContext
      // had a branch set as effectiveOrgId the wrong membership was resolved
      // and branch data never came back.
      // /auth/me must always receive the ROOT org id so it finds the
      // highest-level membership and then looks up pm_officers separately.
      await _orgContext.restore();
      final rootOrgId = _orgContext.rootOrgId; // null for fresh acceptance
      final meResponse = await _remote.getAuthMe(orgId: rootOrgId);
      // rootOrgId null → server picks best membership → returns root_org_id in response

      // ── NEW: update branch in OrgContext on every refresh ────────────
      if (meResponse.resolvedOrgId != null) {
        await _persistOrgAndBranch(
          orgId: meResponse.resolvedOrgId!,
          rootOrgId: meResponse.rootOrgId,
          actorId: meResponse.user.actorId,
          actorName: meResponse.user.name,
          branchId: meResponse.user.branchId,
          branchName: meResponse.user.branchName,
        );
      }
      // ─────────────────────────────────────────────────────────────────

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

  // ── Private helpers ────────────────────────────────────────────────

  /// Persists org context AND branch context into OrgContext + secure storage.
  ///
  /// Replaces the old _persistOrgId() which never called switchBranch(),
  /// meaning OrgContext.activeBranchId was always stale after a transfer.
  Future<void> _persistOrgAndBranch({
    required String orgId,
    required String actorName,
    String? rootOrgId,
    String? actorId,
    String? branchId,
    String? branchName,
  }) async {
    await _orgContext.restore();

    final effectiveRootId = rootOrgId ?? orgId;

    await _orgContext.setRootOrg(
      id: effectiveRootId,
      name: _orgContext.rootOrgName ?? actorName,
      role: _orgContext.orgRole != OrgRole.unknown
          ? _orgContext.orgRole
          : OrgRole.orgAdmin,
      actorId: actorId,
      actorName: actorName,
    );

    // ── NEW: always sync the branch into OrgContext ───────────────────
    // For field officers branchId is always set.
    // For org admins it will be null — switchBranch(null) clears the filter,
    // which is the correct "all branches" view for admins.
    await _orgContext.switchBranch(branchId: branchId, branchName: branchName);
    // ─────────────────────────────────────────────────────────────────
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
