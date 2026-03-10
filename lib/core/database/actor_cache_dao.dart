// actor_cache_dao.dart
// ─────────────────────────────────────────────────────────────
// Drift DAO for the cached_actors table.
// Provides typed read/write/delete operations used by
// ActorRepositoryImpl for offline-first caching.
//
// NOTE: This file requires the generated part file.
// Run: flutter pub run build_runner build --delete-conflicting-outputs
// ─────────────────────────────────────────────────────────────

import 'package:drift/drift.dart';

import 'app_database.dart';
import 'tables/cached_actors_table.dart';

part 'actor_cache_dao.g.dart';

@DriftAccessor(tables: [CachedActors])
class ActorCacheDao extends DatabaseAccessor<AppDatabase>
    with _$ActorCacheDaoMixin {
  ActorCacheDao(super.db);

  // ── Read ──────────────────────────────────────────────────

  /// Returns all cached actor rows, ordered by fetched_at descending.
  Future<List<CachedActor>> getAll() =>
      (select(cachedActors)
            ..orderBy([(t) => OrderingTerm.desc(t.fetchedAtMs)]))
          .get();

  /// Returns the cached row for [actorId], or null if not found.
  Future<CachedActor?> getById(String actorId) =>
      (select(cachedActors)
            ..where((t) => t.actorId.equals(actorId)))
          .getSingleOrNull();

  // ── Write ─────────────────────────────────────────────────

  /// Inserts or replaces a single cached actor row.
  Future<void> upsertOne(CachedActorsCompanion entry) =>
      into(cachedActors).insertOnConflictUpdate(entry);

  /// Replaces the entire local cache with a fresh list from API.
  /// Runs inside a transaction: clear all → insert all.
  Future<void> replaceAll(List<CachedActorsCompanion> entries) =>
      transaction(() async {
        await delete(cachedActors).go();
        for (final entry in entries) {
          await into(cachedActors).insert(entry);
        }
      });

  // ── Delete ────────────────────────────────────────────────

  /// Removes one cached actor by id.
  Future<void> deleteById(String actorId) =>
      (delete(cachedActors)..where((t) => t.actorId.equals(actorId))).go();

  /// Wipes all cached actors — use on logout or cache reset.
  Future<void> clearAll() => delete(cachedActors).go();
}