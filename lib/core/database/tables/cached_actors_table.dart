// cached_actors_table.dart
// ─────────────────────────────────────────────────────────────
// Drift table: one row per actor ULID.
// Stores the full actor as a serialised JSON string so that
// API schema changes only require updating the model parsers,
// not the table definition or a migration.
//
// Columns:
//   actor_id      — ULID primary key (matches actors.id from API)
//   actor_json    — ActorModel.toJson() encoded as String
//   fetched_at_ms — DateTime.millisecondsSinceEpoch (for TTL checks)
//
// After adding this table, update app_database.dart:
//   1. Import this file
//   2. Add CachedActors to the @DriftDatabase tables list
//   3. Add ActorCacheDao to the daos list
//   4. Bump schemaVersion
//   5. Run: flutter pub run build_runner build --delete-conflicting-outputs
// ─────────────────────────────────────────────────────────────

import 'package:drift/drift.dart';

class CachedActors extends Table {
  TextColumn get actorId => text()();
  TextColumn get actorJson => text()();
  IntColumn get fetchedAtMs => integer()();

  @override
  Set<Column> get primaryKey => {actorId};
}
