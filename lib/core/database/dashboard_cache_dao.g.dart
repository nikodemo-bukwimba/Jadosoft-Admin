// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dashboard_cache_dao.dart';

// ignore_for_file: type=lint
mixin _$DashboardCacheDaoMixin on DatabaseAccessor<AppDatabase> {
  $CachedDashboardStatsTable get cachedDashboardStats =>
      attachedDatabase.cachedDashboardStats;
  DashboardCacheDaoManager get managers => DashboardCacheDaoManager(this);
}

class DashboardCacheDaoManager {
  final _$DashboardCacheDaoMixin _db;
  DashboardCacheDaoManager(this._db);
  $$CachedDashboardStatsTableTableManager get cachedDashboardStats =>
      $$CachedDashboardStatsTableTableManager(
        _db.attachedDatabase,
        _db.cachedDashboardStats,
      );
}
