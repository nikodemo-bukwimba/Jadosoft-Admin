// app_database.dart
// ─────────────────────────────────────────────────────────────
// Central Drift database for local caching.
//
// Scope:
//   This database caches API responses for offline/fast-startup
//   use. It is NOT used for auth credentials (those stay in
//   flutter_secure_storage) and is NOT a source of truth — the
//   remote API always wins when fresh data is available.
//
// Tables:
//   cached_profiles         — profile snapshots per user email
//   cached_dashboard_stats  — single admin dashboard snapshot
//   cache_entries           — generic TTL metadata (any feature)
//
// DAOs:
//   ProfileCacheDao        — profile read/write/delete
//   DashboardCacheDao      — dashboard stats read/write/delete
//
// Schema version:
//   Bump [schemaVersion] and add a migration step in [migration]
//   whenever a table definition changes.
//
// Required pubspec.yaml dependencies:
//   dependencies:
//     drift: ^2.x.x
//     path_provider: ^2.x.x
//     path: ^1.x.x
//   dev_dependencies:
//     drift_dev: ^2.x.x
//     build_runner: ^2.x.x
//
// After adding/changing tables, regenerate:
//   flutter pub run build_runner build --delete-conflicting-outputs
// ─────────────────────────────────────────────────────────────

import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'tables/cached_dashboard_stats_table.dart';
import 'tables/cached_profiles_table.dart';
import 'tables/cache_entries_table.dart';
import 'dashboard_cache_dao.dart';
import 'profile_cache_dao.dart';
import 'tables/cached_actors_table.dart';
import 'actor_cache_dao.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [CachedProfiles, CachedDashboardStats, CacheEntries, CachedActors],
  daos: [ProfileCacheDao, DashboardCacheDao, ActorCacheDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  /// Bump this when any table definition changes and add a migration
  /// step in the [migration] getter below.
  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.createTable(cachedActors);
      }
    },
  );
}

// ── Connection factory ────────────────────────────────────────
// Uses NativeDatabase.createInBackground so SQLite operations
// don't block the UI thread.

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'fca_cache.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
