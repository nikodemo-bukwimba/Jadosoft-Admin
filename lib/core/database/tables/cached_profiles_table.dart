// TODO Implement this library.
// cached_profiles_table.dart
// ─────────────────────────────────────────────────────────────
// Drift table: one row per user email.
// Stores the full profile as serialised JSON strings so that
// API schema changes only require updating the model parsers,
// not the table definition or a migration.
//
// Columns:
//   email            — primary key, matches account_{email} in secure storage
//   user_json        — UserModel.toJson() encoded as String
//   roles_json       — List<RoleModel>.toJson() encoded as String
//   permissions_json — List<PermissionModel>.toJson() encoded as String
//   stats_json       — ProfileStats? encoded as String (nullable)
//   fetched_at_ms    — DateTime.millisecondsSinceEpoch (for TTL checks)
// ─────────────────────────────────────────────────────────────

import 'package:drift/drift.dart';

class CachedProfiles extends Table {
  TextColumn get email            => text()();
  TextColumn get userJson         => text()();
  TextColumn get rolesJson        => text()();
  TextColumn get permissionsJson  => text()();
  TextColumn get statsJson        => text().nullable()();
  IntColumn  get fetchedAtMs      => integer()();

  @override
  Set<Column> get primaryKey => {email};
}