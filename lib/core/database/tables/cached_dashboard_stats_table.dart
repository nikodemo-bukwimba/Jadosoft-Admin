// TODO Implement this library.
// cached_dashboard_stats_table.dart
// ─────────────────────────────────────────────────────────────
// Drift table: single-row cache for the admin dashboard snapshot.
// Uses a constant cache_key ('dashboard_stats') as PK so there is
// always at most one row — insert-or-replace acts as an upsert.
//
// Columns:
//   cache_key    — always 'dashboard_stats' (PK)
//   stats_json   — DashboardStatsModel fields as JSON string
//   fetched_at_ms — DateTime.millisecondsSinceEpoch (for TTL checks)
// ─────────────────────────────────────────────────────────────

import 'package:drift/drift.dart';

class CachedDashboardStats extends Table {
  TextColumn get cacheKey    => text()();
  TextColumn get statsJson   => text()();
  IntColumn  get fetchedAtMs => integer()();

  @override
  Set<Column> get primaryKey => {cacheKey};
}