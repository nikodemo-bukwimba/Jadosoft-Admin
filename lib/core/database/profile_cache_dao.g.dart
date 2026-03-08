// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'profile_cache_dao.dart';

// ignore_for_file: type=lint
mixin _$ProfileCacheDaoMixin on DatabaseAccessor<AppDatabase> {
  $CachedProfilesTable get cachedProfiles => attachedDatabase.cachedProfiles;
  ProfileCacheDaoManager get managers => ProfileCacheDaoManager(this);
}

class ProfileCacheDaoManager {
  final _$ProfileCacheDaoMixin _db;
  ProfileCacheDaoManager(this._db);
  $$CachedProfilesTableTableManager get cachedProfiles =>
      $$CachedProfilesTableTableManager(
        _db.attachedDatabase,
        _db.cachedProfiles,
      );
}
