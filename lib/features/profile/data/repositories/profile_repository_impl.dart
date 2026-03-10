// profile_repository_impl.dart
// ─────────────────────────────────────────────────────────────
// Cache-first strategy:
//
//   1. Read active user's email from SecureStorageService.
//   2. Check ProfileCacheDao for a fresh row (within TTL).
//   3. If fresh  → return cached ProfileModel immediately.
//   4. If stale/missing → call remote → save result → return.
//   5. If remote fails AND stale cache exists → return stale data.
//      (graceful degradation: user sees last-known profile instead
//       of an error screen when briefly offline)
//
// TTL is controlled by AppConstants.profileCacheTtlMinutes.
// ─────────────────────────────────────────────────────────────

import 'dart:convert';

import 'package:dartz/dartz.dart';
import 'package:admin_panel/core/constants/app_constants.dart';
import 'package:admin_panel/core/database/app_database.dart';
import 'package:admin_panel/core/database/profile_cache_dao.dart';
import 'package:admin_panel/core/error/exceptions.dart';
import 'package:admin_panel/core/error/failures.dart';
import 'package:admin_panel/core/storage/secure_storage_service.dart';
import 'package:drift/drift.dart' show Value;

import '../../../../features/auth/data/models/user_model.dart';
import '../../domain/entities/profile_entity.dart';
import '../../domain/repositories/profile_repository.dart';
import '../datasources/profile_remote_datasource.dart';
import '../models/profile_model.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  final ProfileRemoteDataSource _remote;
  final ProfileCacheDao _cacheDao;
  final SecureStorageService _storage;

  ProfileRepositoryImpl({
    required ProfileRemoteDataSource remote,
    required ProfileCacheDao cacheDao,
    required SecureStorageService storage,
  }) : _remote = remote,
       _cacheDao = cacheDao,
       _storage = storage;

  @override
  Future<Either<Failure, ProfileEntity>> getOwnProfile() async {
    // ── Step 1: Identify active user ──────────────────────
    final email = await _storage.read(AppConstants.activeAccountKey);

    // ── Step 2: Try cache ─────────────────────────────────
    CachedProfile? cached;
    if (email != null) {
      cached = await _cacheDao.getByEmail(email);
    }

    if (cached != null && _isFresh(cached.fetchedAtMs)) {
      return Right(_fromCacheRow(cached));
    }

    // ── Step 3: Fetch remote ──────────────────────────────
    try {
      final profile = await _remote.getOwnProfile();

      // ── Step 4: Persist to cache ──────────────────────
      if (email != null) {
        await _cacheDao.upsert(
          CachedProfilesCompanion(
            email: Value(email),
            userJson: Value(_encodeUser(profile.user)),
            rolesJson: Value(_encodeRoles(profile.roles)),
            permissionsJson: Value(_encodePermissions(profile.permissions)),
            statsJson: Value(
              profile.stats != null ? _encodeStats(profile.stats!) : null,
            ),
            fetchedAtMs: Value(DateTime.now().millisecondsSinceEpoch),
          ),
        );
      }

      return Right(profile);
    } on AuthException catch (e) {
      // ── Step 5a: Auth error — don't serve stale, force re-login ─
      return Left(AuthFailure(e.message));
    } on NetworkException catch (e) {
      // ── Step 5b: Network failure — serve stale cache if available ─
      if (cached != null) {
        return Right(_fromCacheRow(cached));
      }
      return Left(NetworkFailure(e.message));
    } on ServerException catch (e) {
      if (cached != null) {
        return Right(_fromCacheRow(cached));
      }
      return Left(ServerFailure(e.message));
    } catch (e) {
      if (cached != null) {
        return Right(_fromCacheRow(cached));
      }
      return Left(GenericFailure(e.toString()));
    }
  }

  // ─────────────────────────────────────────────────────────
  // Helpers
  // ─────────────────────────────────────────────────────────

  bool _isFresh(int fetchedAtMs) {
    final age = DateTime.now().millisecondsSinceEpoch - fetchedAtMs;
    return age < AppConstants.profileCacheTtlMinutes * 60 * 1000;
  }

  ProfileModel _fromCacheRow(CachedProfile row) {
    final userMap = jsonDecode(row.userJson) as Map<String, dynamic>;
    final roleList = jsonDecode(row.rolesJson) as List<dynamic>;
    final permList = jsonDecode(row.permissionsJson) as List<dynamic>;

    final user = UserModel.fromJson(userMap);
    final roles = roleList
        .map((r) => RoleModel.fromJson(r as Map<String, dynamic>))
        .toList();
    final permissions = permList
        .map((p) => PermissionModel.fromJson(p as Map<String, dynamic>))
        .toList();

    ProfileStats? stats;
    if (row.statsJson != null) {
      stats = _decodeStats(row.statsJson!);
    }

    return ProfileModel(
      user: user,
      roles: roles,
      permissions: permissions,
      stats: stats,
      fetchedAt: DateTime.fromMillisecondsSinceEpoch(row.fetchedAtMs),
    );
  }

  // ── Serialisers ───────────────────────────────────────────

  String _encodeUser(dynamic user) {
    if (user is UserModel) return jsonEncode(user.toJson());
    // Fallback — build UserModel from entity fields
    return jsonEncode(
      UserModel(
        id: user.id,
        name: user.name,
        email: user.email,
        phone: user.phone,
        isActive: user.isActive,
        emailVerifiedAt: user.emailVerifiedAt,
        primaryRole: user.primaryRole,
        roles: user.roles,
        hasActiveSubscription: user.hasActiveSubscription,
        subscriptionStatus: user.subscriptionStatus,
        createdAt: user.createdAt,
      ).toJson(),
    );
  }

  String _encodeRoles(List<dynamic> roles) => jsonEncode(
    roles
        .map((r) => RoleModel(id: r.id, name: r.name, slug: r.slug).toJson())
        .toList(),
  );

  String _encodePermissions(List<dynamic> perms) => jsonEncode(
    perms
        .map(
          (p) => PermissionModel(id: p.id, name: p.name, slug: p.slug).toJson(),
        )
        .toList(),
  );

  String _encodeStats(ProfileStats s) => jsonEncode({
    'total_subscriptions': s.totalSubscriptions,
    'active_subscriptions': s.activeSubscriptions,
    'total_payments': s.totalPayments,
    'successful_payments': s.successfulPayments,
    'total_paid': s.totalPaid,
    'subscription_status': s.subscriptionStatus,
    'is_verified': s.isVerified,
    'is_recently_active': s.isRecentlyActive,
  });

  ProfileStats _decodeStats(String raw) {
    final m = jsonDecode(raw) as Map<String, dynamic>;
    return ProfileStats(
      totalSubscriptions: m['total_subscriptions'] as int,
      activeSubscriptions: m['active_subscriptions'] as int,
      totalPayments: m['total_payments'] as int,
      successfulPayments: m['successful_payments'] as int,
      totalPaid: (m['total_paid'] as num).toDouble(),
      subscriptionStatus: m['subscription_status'] as String,
      isVerified: m['is_verified'] as bool,
      isRecentlyActive: m['is_recently_active'] as bool,
    );
  }
}
