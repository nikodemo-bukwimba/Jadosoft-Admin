// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'actor_cache_dao.dart';

// ignore_for_file: type=lint
mixin _$ActorCacheDaoMixin on DatabaseAccessor<AppDatabase> {
  $CachedActorsTable get cachedActors => attachedDatabase.cachedActors;
  ActorCacheDaoManager get managers => ActorCacheDaoManager(this);
}

class ActorCacheDaoManager {
  final _$ActorCacheDaoMixin _db;
  ActorCacheDaoManager(this._db);
  $$CachedActorsTableTableManager get cachedActors =>
      $$CachedActorsTableTableManager(_db.attachedDatabase, _db.cachedActors);
}
