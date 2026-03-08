// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $CachedProfilesTable extends CachedProfiles
    with TableInfo<$CachedProfilesTable, CachedProfile> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedProfilesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _emailMeta = const VerificationMeta('email');
  @override
  late final GeneratedColumn<String> email = GeneratedColumn<String>(
    'email',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _userJsonMeta = const VerificationMeta(
    'userJson',
  );
  @override
  late final GeneratedColumn<String> userJson = GeneratedColumn<String>(
    'user_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _rolesJsonMeta = const VerificationMeta(
    'rolesJson',
  );
  @override
  late final GeneratedColumn<String> rolesJson = GeneratedColumn<String>(
    'roles_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _permissionsJsonMeta = const VerificationMeta(
    'permissionsJson',
  );
  @override
  late final GeneratedColumn<String> permissionsJson = GeneratedColumn<String>(
    'permissions_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statsJsonMeta = const VerificationMeta(
    'statsJson',
  );
  @override
  late final GeneratedColumn<String> statsJson = GeneratedColumn<String>(
    'stats_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _fetchedAtMsMeta = const VerificationMeta(
    'fetchedAtMs',
  );
  @override
  late final GeneratedColumn<int> fetchedAtMs = GeneratedColumn<int>(
    'fetched_at_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    email,
    userJson,
    rolesJson,
    permissionsJson,
    statsJson,
    fetchedAtMs,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_profiles';
  @override
  VerificationContext validateIntegrity(
    Insertable<CachedProfile> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('email')) {
      context.handle(
        _emailMeta,
        email.isAcceptableOrUnknown(data['email']!, _emailMeta),
      );
    } else if (isInserting) {
      context.missing(_emailMeta);
    }
    if (data.containsKey('user_json')) {
      context.handle(
        _userJsonMeta,
        userJson.isAcceptableOrUnknown(data['user_json']!, _userJsonMeta),
      );
    } else if (isInserting) {
      context.missing(_userJsonMeta);
    }
    if (data.containsKey('roles_json')) {
      context.handle(
        _rolesJsonMeta,
        rolesJson.isAcceptableOrUnknown(data['roles_json']!, _rolesJsonMeta),
      );
    } else if (isInserting) {
      context.missing(_rolesJsonMeta);
    }
    if (data.containsKey('permissions_json')) {
      context.handle(
        _permissionsJsonMeta,
        permissionsJson.isAcceptableOrUnknown(
          data['permissions_json']!,
          _permissionsJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_permissionsJsonMeta);
    }
    if (data.containsKey('stats_json')) {
      context.handle(
        _statsJsonMeta,
        statsJson.isAcceptableOrUnknown(data['stats_json']!, _statsJsonMeta),
      );
    }
    if (data.containsKey('fetched_at_ms')) {
      context.handle(
        _fetchedAtMsMeta,
        fetchedAtMs.isAcceptableOrUnknown(
          data['fetched_at_ms']!,
          _fetchedAtMsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_fetchedAtMsMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {email};
  @override
  CachedProfile map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedProfile(
      email: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}email'],
      )!,
      userJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_json'],
      )!,
      rolesJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}roles_json'],
      )!,
      permissionsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}permissions_json'],
      )!,
      statsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}stats_json'],
      ),
      fetchedAtMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}fetched_at_ms'],
      )!,
    );
  }

  @override
  $CachedProfilesTable createAlias(String alias) {
    return $CachedProfilesTable(attachedDatabase, alias);
  }
}

class CachedProfile extends DataClass implements Insertable<CachedProfile> {
  final String email;
  final String userJson;
  final String rolesJson;
  final String permissionsJson;
  final String? statsJson;
  final int fetchedAtMs;
  const CachedProfile({
    required this.email,
    required this.userJson,
    required this.rolesJson,
    required this.permissionsJson,
    this.statsJson,
    required this.fetchedAtMs,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['email'] = Variable<String>(email);
    map['user_json'] = Variable<String>(userJson);
    map['roles_json'] = Variable<String>(rolesJson);
    map['permissions_json'] = Variable<String>(permissionsJson);
    if (!nullToAbsent || statsJson != null) {
      map['stats_json'] = Variable<String>(statsJson);
    }
    map['fetched_at_ms'] = Variable<int>(fetchedAtMs);
    return map;
  }

  CachedProfilesCompanion toCompanion(bool nullToAbsent) {
    return CachedProfilesCompanion(
      email: Value(email),
      userJson: Value(userJson),
      rolesJson: Value(rolesJson),
      permissionsJson: Value(permissionsJson),
      statsJson: statsJson == null && nullToAbsent
          ? const Value.absent()
          : Value(statsJson),
      fetchedAtMs: Value(fetchedAtMs),
    );
  }

  factory CachedProfile.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedProfile(
      email: serializer.fromJson<String>(json['email']),
      userJson: serializer.fromJson<String>(json['userJson']),
      rolesJson: serializer.fromJson<String>(json['rolesJson']),
      permissionsJson: serializer.fromJson<String>(json['permissionsJson']),
      statsJson: serializer.fromJson<String?>(json['statsJson']),
      fetchedAtMs: serializer.fromJson<int>(json['fetchedAtMs']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'email': serializer.toJson<String>(email),
      'userJson': serializer.toJson<String>(userJson),
      'rolesJson': serializer.toJson<String>(rolesJson),
      'permissionsJson': serializer.toJson<String>(permissionsJson),
      'statsJson': serializer.toJson<String?>(statsJson),
      'fetchedAtMs': serializer.toJson<int>(fetchedAtMs),
    };
  }

  CachedProfile copyWith({
    String? email,
    String? userJson,
    String? rolesJson,
    String? permissionsJson,
    Value<String?> statsJson = const Value.absent(),
    int? fetchedAtMs,
  }) => CachedProfile(
    email: email ?? this.email,
    userJson: userJson ?? this.userJson,
    rolesJson: rolesJson ?? this.rolesJson,
    permissionsJson: permissionsJson ?? this.permissionsJson,
    statsJson: statsJson.present ? statsJson.value : this.statsJson,
    fetchedAtMs: fetchedAtMs ?? this.fetchedAtMs,
  );
  CachedProfile copyWithCompanion(CachedProfilesCompanion data) {
    return CachedProfile(
      email: data.email.present ? data.email.value : this.email,
      userJson: data.userJson.present ? data.userJson.value : this.userJson,
      rolesJson: data.rolesJson.present ? data.rolesJson.value : this.rolesJson,
      permissionsJson: data.permissionsJson.present
          ? data.permissionsJson.value
          : this.permissionsJson,
      statsJson: data.statsJson.present ? data.statsJson.value : this.statsJson,
      fetchedAtMs: data.fetchedAtMs.present
          ? data.fetchedAtMs.value
          : this.fetchedAtMs,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedProfile(')
          ..write('email: $email, ')
          ..write('userJson: $userJson, ')
          ..write('rolesJson: $rolesJson, ')
          ..write('permissionsJson: $permissionsJson, ')
          ..write('statsJson: $statsJson, ')
          ..write('fetchedAtMs: $fetchedAtMs')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    email,
    userJson,
    rolesJson,
    permissionsJson,
    statsJson,
    fetchedAtMs,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedProfile &&
          other.email == this.email &&
          other.userJson == this.userJson &&
          other.rolesJson == this.rolesJson &&
          other.permissionsJson == this.permissionsJson &&
          other.statsJson == this.statsJson &&
          other.fetchedAtMs == this.fetchedAtMs);
}

class CachedProfilesCompanion extends UpdateCompanion<CachedProfile> {
  final Value<String> email;
  final Value<String> userJson;
  final Value<String> rolesJson;
  final Value<String> permissionsJson;
  final Value<String?> statsJson;
  final Value<int> fetchedAtMs;
  final Value<int> rowid;
  const CachedProfilesCompanion({
    this.email = const Value.absent(),
    this.userJson = const Value.absent(),
    this.rolesJson = const Value.absent(),
    this.permissionsJson = const Value.absent(),
    this.statsJson = const Value.absent(),
    this.fetchedAtMs = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CachedProfilesCompanion.insert({
    required String email,
    required String userJson,
    required String rolesJson,
    required String permissionsJson,
    this.statsJson = const Value.absent(),
    required int fetchedAtMs,
    this.rowid = const Value.absent(),
  }) : email = Value(email),
       userJson = Value(userJson),
       rolesJson = Value(rolesJson),
       permissionsJson = Value(permissionsJson),
       fetchedAtMs = Value(fetchedAtMs);
  static Insertable<CachedProfile> custom({
    Expression<String>? email,
    Expression<String>? userJson,
    Expression<String>? rolesJson,
    Expression<String>? permissionsJson,
    Expression<String>? statsJson,
    Expression<int>? fetchedAtMs,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (email != null) 'email': email,
      if (userJson != null) 'user_json': userJson,
      if (rolesJson != null) 'roles_json': rolesJson,
      if (permissionsJson != null) 'permissions_json': permissionsJson,
      if (statsJson != null) 'stats_json': statsJson,
      if (fetchedAtMs != null) 'fetched_at_ms': fetchedAtMs,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CachedProfilesCompanion copyWith({
    Value<String>? email,
    Value<String>? userJson,
    Value<String>? rolesJson,
    Value<String>? permissionsJson,
    Value<String?>? statsJson,
    Value<int>? fetchedAtMs,
    Value<int>? rowid,
  }) {
    return CachedProfilesCompanion(
      email: email ?? this.email,
      userJson: userJson ?? this.userJson,
      rolesJson: rolesJson ?? this.rolesJson,
      permissionsJson: permissionsJson ?? this.permissionsJson,
      statsJson: statsJson ?? this.statsJson,
      fetchedAtMs: fetchedAtMs ?? this.fetchedAtMs,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (email.present) {
      map['email'] = Variable<String>(email.value);
    }
    if (userJson.present) {
      map['user_json'] = Variable<String>(userJson.value);
    }
    if (rolesJson.present) {
      map['roles_json'] = Variable<String>(rolesJson.value);
    }
    if (permissionsJson.present) {
      map['permissions_json'] = Variable<String>(permissionsJson.value);
    }
    if (statsJson.present) {
      map['stats_json'] = Variable<String>(statsJson.value);
    }
    if (fetchedAtMs.present) {
      map['fetched_at_ms'] = Variable<int>(fetchedAtMs.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedProfilesCompanion(')
          ..write('email: $email, ')
          ..write('userJson: $userJson, ')
          ..write('rolesJson: $rolesJson, ')
          ..write('permissionsJson: $permissionsJson, ')
          ..write('statsJson: $statsJson, ')
          ..write('fetchedAtMs: $fetchedAtMs, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CachedDashboardStatsTable extends CachedDashboardStats
    with TableInfo<$CachedDashboardStatsTable, CachedDashboardStat> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedDashboardStatsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _cacheKeyMeta = const VerificationMeta(
    'cacheKey',
  );
  @override
  late final GeneratedColumn<String> cacheKey = GeneratedColumn<String>(
    'cache_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statsJsonMeta = const VerificationMeta(
    'statsJson',
  );
  @override
  late final GeneratedColumn<String> statsJson = GeneratedColumn<String>(
    'stats_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fetchedAtMsMeta = const VerificationMeta(
    'fetchedAtMs',
  );
  @override
  late final GeneratedColumn<int> fetchedAtMs = GeneratedColumn<int>(
    'fetched_at_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [cacheKey, statsJson, fetchedAtMs];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_dashboard_stats';
  @override
  VerificationContext validateIntegrity(
    Insertable<CachedDashboardStat> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('cache_key')) {
      context.handle(
        _cacheKeyMeta,
        cacheKey.isAcceptableOrUnknown(data['cache_key']!, _cacheKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_cacheKeyMeta);
    }
    if (data.containsKey('stats_json')) {
      context.handle(
        _statsJsonMeta,
        statsJson.isAcceptableOrUnknown(data['stats_json']!, _statsJsonMeta),
      );
    } else if (isInserting) {
      context.missing(_statsJsonMeta);
    }
    if (data.containsKey('fetched_at_ms')) {
      context.handle(
        _fetchedAtMsMeta,
        fetchedAtMs.isAcceptableOrUnknown(
          data['fetched_at_ms']!,
          _fetchedAtMsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_fetchedAtMsMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {cacheKey};
  @override
  CachedDashboardStat map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedDashboardStat(
      cacheKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cache_key'],
      )!,
      statsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}stats_json'],
      )!,
      fetchedAtMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}fetched_at_ms'],
      )!,
    );
  }

  @override
  $CachedDashboardStatsTable createAlias(String alias) {
    return $CachedDashboardStatsTable(attachedDatabase, alias);
  }
}

class CachedDashboardStat extends DataClass
    implements Insertable<CachedDashboardStat> {
  final String cacheKey;
  final String statsJson;
  final int fetchedAtMs;
  const CachedDashboardStat({
    required this.cacheKey,
    required this.statsJson,
    required this.fetchedAtMs,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['cache_key'] = Variable<String>(cacheKey);
    map['stats_json'] = Variable<String>(statsJson);
    map['fetched_at_ms'] = Variable<int>(fetchedAtMs);
    return map;
  }

  CachedDashboardStatsCompanion toCompanion(bool nullToAbsent) {
    return CachedDashboardStatsCompanion(
      cacheKey: Value(cacheKey),
      statsJson: Value(statsJson),
      fetchedAtMs: Value(fetchedAtMs),
    );
  }

  factory CachedDashboardStat.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedDashboardStat(
      cacheKey: serializer.fromJson<String>(json['cacheKey']),
      statsJson: serializer.fromJson<String>(json['statsJson']),
      fetchedAtMs: serializer.fromJson<int>(json['fetchedAtMs']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'cacheKey': serializer.toJson<String>(cacheKey),
      'statsJson': serializer.toJson<String>(statsJson),
      'fetchedAtMs': serializer.toJson<int>(fetchedAtMs),
    };
  }

  CachedDashboardStat copyWith({
    String? cacheKey,
    String? statsJson,
    int? fetchedAtMs,
  }) => CachedDashboardStat(
    cacheKey: cacheKey ?? this.cacheKey,
    statsJson: statsJson ?? this.statsJson,
    fetchedAtMs: fetchedAtMs ?? this.fetchedAtMs,
  );
  CachedDashboardStat copyWithCompanion(CachedDashboardStatsCompanion data) {
    return CachedDashboardStat(
      cacheKey: data.cacheKey.present ? data.cacheKey.value : this.cacheKey,
      statsJson: data.statsJson.present ? data.statsJson.value : this.statsJson,
      fetchedAtMs: data.fetchedAtMs.present
          ? data.fetchedAtMs.value
          : this.fetchedAtMs,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedDashboardStat(')
          ..write('cacheKey: $cacheKey, ')
          ..write('statsJson: $statsJson, ')
          ..write('fetchedAtMs: $fetchedAtMs')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(cacheKey, statsJson, fetchedAtMs);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedDashboardStat &&
          other.cacheKey == this.cacheKey &&
          other.statsJson == this.statsJson &&
          other.fetchedAtMs == this.fetchedAtMs);
}

class CachedDashboardStatsCompanion
    extends UpdateCompanion<CachedDashboardStat> {
  final Value<String> cacheKey;
  final Value<String> statsJson;
  final Value<int> fetchedAtMs;
  final Value<int> rowid;
  const CachedDashboardStatsCompanion({
    this.cacheKey = const Value.absent(),
    this.statsJson = const Value.absent(),
    this.fetchedAtMs = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CachedDashboardStatsCompanion.insert({
    required String cacheKey,
    required String statsJson,
    required int fetchedAtMs,
    this.rowid = const Value.absent(),
  }) : cacheKey = Value(cacheKey),
       statsJson = Value(statsJson),
       fetchedAtMs = Value(fetchedAtMs);
  static Insertable<CachedDashboardStat> custom({
    Expression<String>? cacheKey,
    Expression<String>? statsJson,
    Expression<int>? fetchedAtMs,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (cacheKey != null) 'cache_key': cacheKey,
      if (statsJson != null) 'stats_json': statsJson,
      if (fetchedAtMs != null) 'fetched_at_ms': fetchedAtMs,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CachedDashboardStatsCompanion copyWith({
    Value<String>? cacheKey,
    Value<String>? statsJson,
    Value<int>? fetchedAtMs,
    Value<int>? rowid,
  }) {
    return CachedDashboardStatsCompanion(
      cacheKey: cacheKey ?? this.cacheKey,
      statsJson: statsJson ?? this.statsJson,
      fetchedAtMs: fetchedAtMs ?? this.fetchedAtMs,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (cacheKey.present) {
      map['cache_key'] = Variable<String>(cacheKey.value);
    }
    if (statsJson.present) {
      map['stats_json'] = Variable<String>(statsJson.value);
    }
    if (fetchedAtMs.present) {
      map['fetched_at_ms'] = Variable<int>(fetchedAtMs.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedDashboardStatsCompanion(')
          ..write('cacheKey: $cacheKey, ')
          ..write('statsJson: $statsJson, ')
          ..write('fetchedAtMs: $fetchedAtMs, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CacheEntriesTable extends CacheEntries
    with TableInfo<$CacheEntriesTable, CacheEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CacheEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _cacheKeyMeta = const VerificationMeta(
    'cacheKey',
  );
  @override
  late final GeneratedColumn<String> cacheKey = GeneratedColumn<String>(
    'cache_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _expiresAtMsMeta = const VerificationMeta(
    'expiresAtMs',
  );
  @override
  late final GeneratedColumn<int> expiresAtMs = GeneratedColumn<int>(
    'expires_at_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [cacheKey, expiresAtMs, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cache_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<CacheEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('cache_key')) {
      context.handle(
        _cacheKeyMeta,
        cacheKey.isAcceptableOrUnknown(data['cache_key']!, _cacheKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_cacheKeyMeta);
    }
    if (data.containsKey('expires_at_ms')) {
      context.handle(
        _expiresAtMsMeta,
        expiresAtMs.isAcceptableOrUnknown(
          data['expires_at_ms']!,
          _expiresAtMsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_expiresAtMsMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {cacheKey};
  @override
  CacheEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CacheEntry(
      cacheKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cache_key'],
      )!,
      expiresAtMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}expires_at_ms'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      ),
    );
  }

  @override
  $CacheEntriesTable createAlias(String alias) {
    return $CacheEntriesTable(attachedDatabase, alias);
  }
}

class CacheEntry extends DataClass implements Insertable<CacheEntry> {
  final String cacheKey;
  final int expiresAtMs;
  final String? value;
  const CacheEntry({
    required this.cacheKey,
    required this.expiresAtMs,
    this.value,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['cache_key'] = Variable<String>(cacheKey);
    map['expires_at_ms'] = Variable<int>(expiresAtMs);
    if (!nullToAbsent || value != null) {
      map['value'] = Variable<String>(value);
    }
    return map;
  }

  CacheEntriesCompanion toCompanion(bool nullToAbsent) {
    return CacheEntriesCompanion(
      cacheKey: Value(cacheKey),
      expiresAtMs: Value(expiresAtMs),
      value: value == null && nullToAbsent
          ? const Value.absent()
          : Value(value),
    );
  }

  factory CacheEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CacheEntry(
      cacheKey: serializer.fromJson<String>(json['cacheKey']),
      expiresAtMs: serializer.fromJson<int>(json['expiresAtMs']),
      value: serializer.fromJson<String?>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'cacheKey': serializer.toJson<String>(cacheKey),
      'expiresAtMs': serializer.toJson<int>(expiresAtMs),
      'value': serializer.toJson<String?>(value),
    };
  }

  CacheEntry copyWith({
    String? cacheKey,
    int? expiresAtMs,
    Value<String?> value = const Value.absent(),
  }) => CacheEntry(
    cacheKey: cacheKey ?? this.cacheKey,
    expiresAtMs: expiresAtMs ?? this.expiresAtMs,
    value: value.present ? value.value : this.value,
  );
  CacheEntry copyWithCompanion(CacheEntriesCompanion data) {
    return CacheEntry(
      cacheKey: data.cacheKey.present ? data.cacheKey.value : this.cacheKey,
      expiresAtMs: data.expiresAtMs.present
          ? data.expiresAtMs.value
          : this.expiresAtMs,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CacheEntry(')
          ..write('cacheKey: $cacheKey, ')
          ..write('expiresAtMs: $expiresAtMs, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(cacheKey, expiresAtMs, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CacheEntry &&
          other.cacheKey == this.cacheKey &&
          other.expiresAtMs == this.expiresAtMs &&
          other.value == this.value);
}

class CacheEntriesCompanion extends UpdateCompanion<CacheEntry> {
  final Value<String> cacheKey;
  final Value<int> expiresAtMs;
  final Value<String?> value;
  final Value<int> rowid;
  const CacheEntriesCompanion({
    this.cacheKey = const Value.absent(),
    this.expiresAtMs = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CacheEntriesCompanion.insert({
    required String cacheKey,
    required int expiresAtMs,
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : cacheKey = Value(cacheKey),
       expiresAtMs = Value(expiresAtMs);
  static Insertable<CacheEntry> custom({
    Expression<String>? cacheKey,
    Expression<int>? expiresAtMs,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (cacheKey != null) 'cache_key': cacheKey,
      if (expiresAtMs != null) 'expires_at_ms': expiresAtMs,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CacheEntriesCompanion copyWith({
    Value<String>? cacheKey,
    Value<int>? expiresAtMs,
    Value<String?>? value,
    Value<int>? rowid,
  }) {
    return CacheEntriesCompanion(
      cacheKey: cacheKey ?? this.cacheKey,
      expiresAtMs: expiresAtMs ?? this.expiresAtMs,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (cacheKey.present) {
      map['cache_key'] = Variable<String>(cacheKey.value);
    }
    if (expiresAtMs.present) {
      map['expires_at_ms'] = Variable<int>(expiresAtMs.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CacheEntriesCompanion(')
          ..write('cacheKey: $cacheKey, ')
          ..write('expiresAtMs: $expiresAtMs, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $CachedProfilesTable cachedProfiles = $CachedProfilesTable(this);
  late final $CachedDashboardStatsTable cachedDashboardStats =
      $CachedDashboardStatsTable(this);
  late final $CacheEntriesTable cacheEntries = $CacheEntriesTable(this);
  late final ProfileCacheDao profileCacheDao = ProfileCacheDao(
    this as AppDatabase,
  );
  late final DashboardCacheDao dashboardCacheDao = DashboardCacheDao(
    this as AppDatabase,
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    cachedProfiles,
    cachedDashboardStats,
    cacheEntries,
  ];
}

typedef $$CachedProfilesTableCreateCompanionBuilder =
    CachedProfilesCompanion Function({
      required String email,
      required String userJson,
      required String rolesJson,
      required String permissionsJson,
      Value<String?> statsJson,
      required int fetchedAtMs,
      Value<int> rowid,
    });
typedef $$CachedProfilesTableUpdateCompanionBuilder =
    CachedProfilesCompanion Function({
      Value<String> email,
      Value<String> userJson,
      Value<String> rolesJson,
      Value<String> permissionsJson,
      Value<String?> statsJson,
      Value<int> fetchedAtMs,
      Value<int> rowid,
    });

class $$CachedProfilesTableFilterComposer
    extends Composer<_$AppDatabase, $CachedProfilesTable> {
  $$CachedProfilesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userJson => $composableBuilder(
    column: $table.userJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rolesJson => $composableBuilder(
    column: $table.rolesJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get permissionsJson => $composableBuilder(
    column: $table.permissionsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get statsJson => $composableBuilder(
    column: $table.statsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get fetchedAtMs => $composableBuilder(
    column: $table.fetchedAtMs,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CachedProfilesTableOrderingComposer
    extends Composer<_$AppDatabase, $CachedProfilesTable> {
  $$CachedProfilesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userJson => $composableBuilder(
    column: $table.userJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rolesJson => $composableBuilder(
    column: $table.rolesJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get permissionsJson => $composableBuilder(
    column: $table.permissionsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get statsJson => $composableBuilder(
    column: $table.statsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get fetchedAtMs => $composableBuilder(
    column: $table.fetchedAtMs,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CachedProfilesTableAnnotationComposer
    extends Composer<_$AppDatabase, $CachedProfilesTable> {
  $$CachedProfilesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get email =>
      $composableBuilder(column: $table.email, builder: (column) => column);

  GeneratedColumn<String> get userJson =>
      $composableBuilder(column: $table.userJson, builder: (column) => column);

  GeneratedColumn<String> get rolesJson =>
      $composableBuilder(column: $table.rolesJson, builder: (column) => column);

  GeneratedColumn<String> get permissionsJson => $composableBuilder(
    column: $table.permissionsJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get statsJson =>
      $composableBuilder(column: $table.statsJson, builder: (column) => column);

  GeneratedColumn<int> get fetchedAtMs => $composableBuilder(
    column: $table.fetchedAtMs,
    builder: (column) => column,
  );
}

class $$CachedProfilesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CachedProfilesTable,
          CachedProfile,
          $$CachedProfilesTableFilterComposer,
          $$CachedProfilesTableOrderingComposer,
          $$CachedProfilesTableAnnotationComposer,
          $$CachedProfilesTableCreateCompanionBuilder,
          $$CachedProfilesTableUpdateCompanionBuilder,
          (
            CachedProfile,
            BaseReferences<_$AppDatabase, $CachedProfilesTable, CachedProfile>,
          ),
          CachedProfile,
          PrefetchHooks Function()
        > {
  $$CachedProfilesTableTableManager(
    _$AppDatabase db,
    $CachedProfilesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedProfilesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CachedProfilesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CachedProfilesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> email = const Value.absent(),
                Value<String> userJson = const Value.absent(),
                Value<String> rolesJson = const Value.absent(),
                Value<String> permissionsJson = const Value.absent(),
                Value<String?> statsJson = const Value.absent(),
                Value<int> fetchedAtMs = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CachedProfilesCompanion(
                email: email,
                userJson: userJson,
                rolesJson: rolesJson,
                permissionsJson: permissionsJson,
                statsJson: statsJson,
                fetchedAtMs: fetchedAtMs,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String email,
                required String userJson,
                required String rolesJson,
                required String permissionsJson,
                Value<String?> statsJson = const Value.absent(),
                required int fetchedAtMs,
                Value<int> rowid = const Value.absent(),
              }) => CachedProfilesCompanion.insert(
                email: email,
                userJson: userJson,
                rolesJson: rolesJson,
                permissionsJson: permissionsJson,
                statsJson: statsJson,
                fetchedAtMs: fetchedAtMs,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CachedProfilesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CachedProfilesTable,
      CachedProfile,
      $$CachedProfilesTableFilterComposer,
      $$CachedProfilesTableOrderingComposer,
      $$CachedProfilesTableAnnotationComposer,
      $$CachedProfilesTableCreateCompanionBuilder,
      $$CachedProfilesTableUpdateCompanionBuilder,
      (
        CachedProfile,
        BaseReferences<_$AppDatabase, $CachedProfilesTable, CachedProfile>,
      ),
      CachedProfile,
      PrefetchHooks Function()
    >;
typedef $$CachedDashboardStatsTableCreateCompanionBuilder =
    CachedDashboardStatsCompanion Function({
      required String cacheKey,
      required String statsJson,
      required int fetchedAtMs,
      Value<int> rowid,
    });
typedef $$CachedDashboardStatsTableUpdateCompanionBuilder =
    CachedDashboardStatsCompanion Function({
      Value<String> cacheKey,
      Value<String> statsJson,
      Value<int> fetchedAtMs,
      Value<int> rowid,
    });

class $$CachedDashboardStatsTableFilterComposer
    extends Composer<_$AppDatabase, $CachedDashboardStatsTable> {
  $$CachedDashboardStatsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get cacheKey => $composableBuilder(
    column: $table.cacheKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get statsJson => $composableBuilder(
    column: $table.statsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get fetchedAtMs => $composableBuilder(
    column: $table.fetchedAtMs,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CachedDashboardStatsTableOrderingComposer
    extends Composer<_$AppDatabase, $CachedDashboardStatsTable> {
  $$CachedDashboardStatsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get cacheKey => $composableBuilder(
    column: $table.cacheKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get statsJson => $composableBuilder(
    column: $table.statsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get fetchedAtMs => $composableBuilder(
    column: $table.fetchedAtMs,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CachedDashboardStatsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CachedDashboardStatsTable> {
  $$CachedDashboardStatsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get cacheKey =>
      $composableBuilder(column: $table.cacheKey, builder: (column) => column);

  GeneratedColumn<String> get statsJson =>
      $composableBuilder(column: $table.statsJson, builder: (column) => column);

  GeneratedColumn<int> get fetchedAtMs => $composableBuilder(
    column: $table.fetchedAtMs,
    builder: (column) => column,
  );
}

class $$CachedDashboardStatsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CachedDashboardStatsTable,
          CachedDashboardStat,
          $$CachedDashboardStatsTableFilterComposer,
          $$CachedDashboardStatsTableOrderingComposer,
          $$CachedDashboardStatsTableAnnotationComposer,
          $$CachedDashboardStatsTableCreateCompanionBuilder,
          $$CachedDashboardStatsTableUpdateCompanionBuilder,
          (
            CachedDashboardStat,
            BaseReferences<
              _$AppDatabase,
              $CachedDashboardStatsTable,
              CachedDashboardStat
            >,
          ),
          CachedDashboardStat,
          PrefetchHooks Function()
        > {
  $$CachedDashboardStatsTableTableManager(
    _$AppDatabase db,
    $CachedDashboardStatsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedDashboardStatsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CachedDashboardStatsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$CachedDashboardStatsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> cacheKey = const Value.absent(),
                Value<String> statsJson = const Value.absent(),
                Value<int> fetchedAtMs = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CachedDashboardStatsCompanion(
                cacheKey: cacheKey,
                statsJson: statsJson,
                fetchedAtMs: fetchedAtMs,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String cacheKey,
                required String statsJson,
                required int fetchedAtMs,
                Value<int> rowid = const Value.absent(),
              }) => CachedDashboardStatsCompanion.insert(
                cacheKey: cacheKey,
                statsJson: statsJson,
                fetchedAtMs: fetchedAtMs,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CachedDashboardStatsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CachedDashboardStatsTable,
      CachedDashboardStat,
      $$CachedDashboardStatsTableFilterComposer,
      $$CachedDashboardStatsTableOrderingComposer,
      $$CachedDashboardStatsTableAnnotationComposer,
      $$CachedDashboardStatsTableCreateCompanionBuilder,
      $$CachedDashboardStatsTableUpdateCompanionBuilder,
      (
        CachedDashboardStat,
        BaseReferences<
          _$AppDatabase,
          $CachedDashboardStatsTable,
          CachedDashboardStat
        >,
      ),
      CachedDashboardStat,
      PrefetchHooks Function()
    >;
typedef $$CacheEntriesTableCreateCompanionBuilder =
    CacheEntriesCompanion Function({
      required String cacheKey,
      required int expiresAtMs,
      Value<String?> value,
      Value<int> rowid,
    });
typedef $$CacheEntriesTableUpdateCompanionBuilder =
    CacheEntriesCompanion Function({
      Value<String> cacheKey,
      Value<int> expiresAtMs,
      Value<String?> value,
      Value<int> rowid,
    });

class $$CacheEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $CacheEntriesTable> {
  $$CacheEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get cacheKey => $composableBuilder(
    column: $table.cacheKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get expiresAtMs => $composableBuilder(
    column: $table.expiresAtMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CacheEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $CacheEntriesTable> {
  $$CacheEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get cacheKey => $composableBuilder(
    column: $table.cacheKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get expiresAtMs => $composableBuilder(
    column: $table.expiresAtMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CacheEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $CacheEntriesTable> {
  $$CacheEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get cacheKey =>
      $composableBuilder(column: $table.cacheKey, builder: (column) => column);

  GeneratedColumn<int> get expiresAtMs => $composableBuilder(
    column: $table.expiresAtMs,
    builder: (column) => column,
  );

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$CacheEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CacheEntriesTable,
          CacheEntry,
          $$CacheEntriesTableFilterComposer,
          $$CacheEntriesTableOrderingComposer,
          $$CacheEntriesTableAnnotationComposer,
          $$CacheEntriesTableCreateCompanionBuilder,
          $$CacheEntriesTableUpdateCompanionBuilder,
          (
            CacheEntry,
            BaseReferences<_$AppDatabase, $CacheEntriesTable, CacheEntry>,
          ),
          CacheEntry,
          PrefetchHooks Function()
        > {
  $$CacheEntriesTableTableManager(_$AppDatabase db, $CacheEntriesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CacheEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CacheEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CacheEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> cacheKey = const Value.absent(),
                Value<int> expiresAtMs = const Value.absent(),
                Value<String?> value = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CacheEntriesCompanion(
                cacheKey: cacheKey,
                expiresAtMs: expiresAtMs,
                value: value,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String cacheKey,
                required int expiresAtMs,
                Value<String?> value = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CacheEntriesCompanion.insert(
                cacheKey: cacheKey,
                expiresAtMs: expiresAtMs,
                value: value,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CacheEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CacheEntriesTable,
      CacheEntry,
      $$CacheEntriesTableFilterComposer,
      $$CacheEntriesTableOrderingComposer,
      $$CacheEntriesTableAnnotationComposer,
      $$CacheEntriesTableCreateCompanionBuilder,
      $$CacheEntriesTableUpdateCompanionBuilder,
      (
        CacheEntry,
        BaseReferences<_$AppDatabase, $CacheEntriesTable, CacheEntry>,
      ),
      CacheEntry,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$CachedProfilesTableTableManager get cachedProfiles =>
      $$CachedProfilesTableTableManager(_db, _db.cachedProfiles);
  $$CachedDashboardStatsTableTableManager get cachedDashboardStats =>
      $$CachedDashboardStatsTableTableManager(_db, _db.cachedDashboardStats);
  $$CacheEntriesTableTableManager get cacheEntries =>
      $$CacheEntriesTableTableManager(_db, _db.cacheEntries);
}
