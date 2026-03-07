// TODO Implement this library.
// cache_entries_table.dart
// ─────────────────────────────────────────────────────────────
// Drift table: generic key-value store for TTL metadata.
// Any feature can use this to track when a cached resource expires
// without needing its own dedicated table.
//
// Examples:
//   key: 'profile:user@example.com'   expires_at_ms: <epoch ms>
//   key: 'dashboard_stats'            expires_at_ms: <epoch ms>
//   key: 'users_list'                 expires_at_ms: <epoch ms>
//
// Columns:
//   cache_key     — namespaced string key (PK)
//   expires_at_ms — DateTime.millisecondsSinceEpoch
//   value         — optional small payload string (ETags, page tokens, etc.)
// ─────────────────────────────────────────────────────────────

import 'package:drift/drift.dart';

class CacheEntries extends Table {
  TextColumn get cacheKey    => text()();
  IntColumn  get expiresAtMs => integer()();
  TextColumn get value       => text().nullable()();

  @override
  Set<Column> get primaryKey => {cacheKey};
}