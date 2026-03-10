// dashboard_repository_impl.dart
// ─────────────────────────────────────────────────────────────
// Cache-first strategy:
//
//   1. Check DashboardCacheDao for a fresh row (within TTL).
//   2. If fresh  → return cached DashboardStats immediately.
//   3. If stale/missing → call remote → save result → return.
//   4. If remote fails AND stale cache exists → return stale data.
//      (admin sees last-known snapshot instead of an error screen
//       when briefly offline — better than a blank dashboard)
//
// Auth failures (401/403) bypass the stale-cache fallback — the
// user should not see admin data if their role changed server-side.
//
// TTL is controlled by AppConstants.dashboardCacheTtlMinutes.
// ─────────────────────────────────────────────────────────────

import 'dart:convert';

import 'package:dartz/dartz.dart';
import 'package:drift/drift.dart' show Value;
import 'package:admin_panel/core/constants/app_constants.dart';
import 'package:admin_panel/core/database/app_database.dart';
import 'package:admin_panel/core/database/dashboard_cache_dao.dart';
import 'package:admin_panel/core/error/exceptions.dart';
import 'package:admin_panel/core/error/failures.dart';
import '../../domain/entities/dashboard_stats.dart';
import '../../domain/repositories/dashboard_repository.dart';
import '../datasources/dashboard_remote_datasource.dart';
import '../models/dashboard_stats_model.dart';

class DashboardRepositoryImpl implements DashboardRepository {
  final DashboardRemoteDataSource _remote;
  final DashboardCacheDao _cacheDao;

  DashboardRepositoryImpl({
    required DashboardRemoteDataSource remote,
    required DashboardCacheDao cacheDao,
  }) : _remote = remote,
       _cacheDao = cacheDao;

  @override
  Future<Either<Failure, DashboardStats>> getDashboardStats() async {
    // ── Step 1: Try cache ─────────────────────────────────
    final cached = await _cacheDao.get();

    if (cached != null && _isFresh(cached.fetchedAtMs)) {
      return Right(_fromCacheRow(cached));
    }

    // ── Step 2: Fetch remote ──────────────────────────────
    try {
      final stats = await _remote.getDashboardStats();

      // ── Step 3: Persist to cache ──────────────────────
      await _cacheDao.upsert(
        CachedDashboardStatsCompanion(
          cacheKey: const Value(DashboardCacheDao.cacheKey),
          statsJson: Value(_encode(stats)),
          fetchedAtMs: Value(DateTime.now().millisecondsSinceEpoch),
        ),
      );

      return Right(stats);
    } on AuthException catch (e) {
      // Auth/permission errors — never serve cached admin data
      return Left(AuthFailure(e.message));
    } on NetworkException catch (e) {
      if (cached != null) return Right(_fromCacheRow(cached));
      return Left(NetworkFailure(e.message));
    } on ServerException catch (e) {
      if (cached != null) return Right(_fromCacheRow(cached));
      return Left(ServerFailure(e.message));
    } catch (e) {
      if (cached != null) return Right(_fromCacheRow(cached));
      return Left(GenericFailure(e.toString()));
    }
  }

  // ─────────────────────────────────────────────────────────
  // Helpers
  // ─────────────────────────────────────────────────────────

  bool _isFresh(int fetchedAtMs) {
    final age = DateTime.now().millisecondsSinceEpoch - fetchedAtMs;
    return age < AppConstants.dashboardCacheTtlMinutes * 60 * 1000;
  }

  String _encode(DashboardStats s) => jsonEncode({
    'total_users': s.totalUsers,
    'new_users_this_month': s.newUsersThisMonth,
    'active_subscriptions': s.activeSubscriptions,
    'revenue_this_month': s.revenueThisMonth,
    'pending_payments': s.pendingPayments,
    'total_revenue': s.totalRevenue,
  });

  DashboardStats _fromCacheRow(CachedDashboardStat row) =>
      DashboardStatsModel.fromJson(
        jsonDecode(row.statsJson) as Map<String, dynamic>,
      );
}
