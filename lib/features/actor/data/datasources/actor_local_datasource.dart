// actor_local_datasource.dart
// ─────────────────────────────────────────────────────────────
// Local data source for offline actor caching.
// Backed by Drift (SQLite) via ActorCacheDao.
//
// Each actor is stored as a JSON string blob so that API schema
// changes only affect ActorModel.fromJson/toJson — no table
// migration needed.
//
// Phase 2: fully implemented, replaces the Phase 1 stub.
// ─────────────────────────────────────────────────────────────

import 'dart:convert';

import 'package:drift/drift.dart';
import '../../../../core/database/actor_cache_dao.dart';
import '../../../../core/database/app_database.dart';
import '../models/actor_model.dart';

abstract class ActorLocalDataSource {
  Future<List<ActorModel>> getAll();
  Future<ActorModel?> getById(String id);
  Future<void> cacheAll(List<ActorModel> actors);
  Future<void> cacheOne(ActorModel actor);
  Future<void> deleteById(String id);
  Future<void> clearAll();
}

class ActorLocalDataSourceImpl implements ActorLocalDataSource {
  final ActorCacheDao _dao;
  ActorLocalDataSourceImpl({required ActorCacheDao dao}) : _dao = dao;

  @override
  Future<List<ActorModel>> getAll() async {
    final rows = await _dao.getAll();
    return rows.map(_fromRow).toList();
  }

  @override
  Future<ActorModel?> getById(String id) async {
    final row = await _dao.getById(id);
    return row != null ? _fromRow(row) : null;
  }

  @override
  Future<void> cacheAll(List<ActorModel> actors) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final entries = actors
        .map(
          (a) => CachedActorsCompanion(
            actorId: Value(a.id),
            actorJson: Value(jsonEncode(a.toJson())),
            fetchedAtMs: Value(now),
          ),
        )
        .toList();
    await _dao.replaceAll(entries);
  }

  @override
  Future<void> cacheOne(ActorModel actor) async {
    await _dao.upsertOne(
      CachedActorsCompanion(
        actorId: Value(actor.id),
        actorJson: Value(jsonEncode(actor.toJson())),
        fetchedAtMs: Value(DateTime.now().millisecondsSinceEpoch),
      ),
    );
  }

  @override
  Future<void> deleteById(String id) => _dao.deleteById(id);

  @override
  Future<void> clearAll() => _dao.clearAll();

  // ── Helper ───────────────────────────────────────────────

  ActorModel _fromRow(CachedActor row) {
    final json = jsonDecode(row.actorJson) as Map<String, dynamic>;
    return ActorModel.fromJson(json);
  }
}
