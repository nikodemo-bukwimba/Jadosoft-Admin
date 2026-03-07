// profile_cache_dao.dart
// ─────────────────────────────────────────────────────────────
// Drift DAO for the cached_profiles table.
// Provides typed read/write/delete operations used by
// ProfileRepositoryImpl.
//
// NOTE: This file requires the generated part file.
// Run: flutter pub run build_runner build --delete-conflicting-outputs
// ─────────────────────────────────────────────────────────────

import 'package:drift/drift.dart';

import 'app_database.dart';
import 'tables/cached_profiles_table.dart';

part 'profile_cache_dao.g.dart';

@DriftAccessor(tables: [CachedProfiles])
class ProfileCacheDao extends DatabaseAccessor<AppDatabase>
    with _$ProfileCacheDaoMixin {
  ProfileCacheDao(super.db);

  // ── Read ──────────────────────────────────────────────────

  /// Returns the cached row for [email], or null if not found.
  Future<CachedProfile?> getByEmail(String email) =>
      (select(cachedProfiles)
            ..where((t) => t.email.equals(email)))
          .getSingleOrNull();

  // ── Write ─────────────────────────────────────────────────

  /// Inserts or replaces the cache row for the given profile.
  Future<void> upsert(CachedProfilesCompanion entry) =>
      into(cachedProfiles).insertOnConflictUpdate(entry);

  // ── Delete ────────────────────────────────────────────────

  /// Removes the cached profile for [email] (e.g. on logout).
  Future<void> deleteByEmail(String email) =>
      (delete(cachedProfiles)..where((t) => t.email.equals(email))).go();

  /// Wipes all cached profiles — use on full sign-out or cache reset.
  Future<void> clearAll() => delete(cachedProfiles).go();
}