// TODO Implement this library.
// dashboard_cache_dao.dart
// ─────────────────────────────────────────────────────────────
// Drift DAO for the cached_dashboard_stats table.
// The table is a single-row cache — the constant [_key] is always
// used as the primary key.
//
// NOTE: This file requires the generated part file.
// Run: flutter pub run build_runner build --delete-conflicting-outputs
// ─────────────────────────────────────────────────────────────

import 'package:drift/drift.dart';

import 'app_database.dart';
import 'tables/cached_dashboard_stats_table.dart';

part 'dashboard_cache_dao.g.dart';

@DriftAccessor(tables: [CachedDashboardStats])
class DashboardCacheDao extends DatabaseAccessor<AppDatabase>
    with _$DashboardCacheDaoMixin {
  DashboardCacheDao(super.db);

  // ── Constant key — always one row ─────────────────────────
  // Public so DashboardRepositoryImpl can reference it without
  // duplicating the string literal.
  static const String cacheKey = 'dashboard_stats';

  // ── Read ──────────────────────────────────────────────────

  /// Returns the cached stats row, or null if never fetched.
  Future<CachedDashboardStat?> get() =>
      (select(cachedDashboardStats)
            ..where((t) => t.cacheKey.equals(cacheKey)))
          .getSingleOrNull();

  // ── Write ─────────────────────────────────────────────────

  /// Inserts or replaces the cached stats snapshot.
  Future<void> upsert(CachedDashboardStatsCompanion entry) =>
      into(cachedDashboardStats).insertOnConflictUpdate(entry);

  // ── Delete ────────────────────────────────────────────────

  /// Clears the cached stats (e.g. after admin logout).
  Future<void> clear() =>
      (delete(cachedDashboardStats)..where((t) => t.cacheKey.equals(cacheKey))).go();
}