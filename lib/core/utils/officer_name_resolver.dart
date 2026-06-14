// lib/core/utils/officer_name_resolver.dart

import 'package:dio/dio.dart';

class OfficerNameResolver {
  final Dio _dio;
  final String Function() _orgId;

  final Map<String, String> _byActorId = {};
  final Map<String, String> _byUserId = {};

  DateTime? _lastFetch;
  final Duration staleDuration;

  OfficerNameResolver({
    required Dio dio,
    required String Function() orgId,
    this.staleDuration = const Duration(minutes: 5),
  }) : _dio = dio,
       _orgId = orgId;

  Future<String> resolve(String actorId, {bool force = false}) async {
    await _ensureWarm(force: force);
    return _byActorId[actorId] ?? _byUserId[actorId] ?? actorId;
  }

  Future<Map<String, dynamic>> inject(
    Map<String, dynamic> json, {
    bool force = false,
  }) async {
    final existing = json['officer_name'];
    if (existing is String && existing.trim().isNotEmpty) return json;

    await _ensureWarm(force: force);

    final name = _resolveFromJson(json);
    if (name == null) return json;

    return {...json, 'officer_name': name};
  }

  Future<void> warmUp({bool force = false}) => _ensureWarm(force: force);

  bool get _isStale =>
      _lastFetch == null ||
      DateTime.now().difference(_lastFetch!) > staleDuration;

  Future<void> _ensureWarm({bool force = false}) async {
    if (!force && !_isStale && _byActorId.isNotEmpty) return;
    await _fetch();
  }

  Future<void> _fetch() async {
    try {
      final response = await _dio.get(
        '/orgs/${_orgId()}/members',
        queryParameters: {'per_page': 200},
      );

      final raw = response.data;
      // Handle both paginated {data: [...]} and bare [...] shapes
      final list = (raw is Map ? (raw['data'] ?? []) : raw) as List? ?? [];

      _byActorId.clear();
      _byUserId.clear();

      for (final item in list.whereType<Map<String, dynamic>>()) {
        // The members endpoint returns FLAT items — actor_id, user_id, name
        // are directly on the item, NOT nested inside a 'user' or 'actor' key.
        //
        // Actual shape (confirmed from logs):
        // {
        //   user_id:  "01KSQ9D3XX0Q...",
        //   actor_id: "01KSQ9D3MWXP...",
        //   name:     "admin",           ← display name
        //   username: "admin",
        //   email:    "admin@...",
        //   ...
        // }
        //
        // Also support nested user/actor shapes as fallback for other
        // API versions that might wrap the data differently.
        final user = item['user'] as Map<String, dynamic>? ?? {};
        final actor =
            user['actor'] as Map<String, dynamic>? ??
            item['actor'] as Map<String, dynamic>? ??
            {};

        // actor_id: try flat first, then nested
        final actorId =
            (item['actor_id'] ?? user['actor_id'] ?? actor['id'] ?? '')
                .toString();

        // user_id: try flat first, then nested
        final userId = (item['user_id'] ?? user['id'] ?? '').toString();

        // Name resolution priority:
        //   1. item['name']              — flat display name (confirmed present)
        //   2. actor['display_name']     — nested actor (future-proof)
        //   3. user['name']              — nested user name
        //   4. item['username']          — technical handle fallback
        //   5. user['username']          — nested username
        //   6. email prefix              — absolute fallback
        final name = _firstNonEmpty([
          item['name'] as String?,
          actor['display_name'] as String?,
          user['name'] as String?,
          item['username'] as String?,
          user['username'] as String?,
          (item['email'] as String?)?.split('@').first,
          (user['email'] as String?)?.split('@').first,
        ]);

        if (name.isEmpty) continue;

        if (actorId.isNotEmpty) _byActorId[actorId] = name;
        if (userId.isNotEmpty) _byUserId[userId] = name;
      }

      _lastFetch = DateTime.now();
    } catch (_) {
      // Non-fatal — features still load, officer column falls back to actor ID.
    }
  }

  String? _resolveFromJson(Map<String, dynamic> j) {
    final candidates = [
      j['officer_actor_id']?.toString(),
      j['officer_id']?.toString(),
      j['actor_id']?.toString(),
    ];

    for (final id in candidates) {
      if (id == null || id.isEmpty) continue;
      final name = _byActorId[id] ?? _byUserId[id];
      if (name != null) return name;
    }
    return null;
  }

  static String _firstNonEmpty(List<String?> candidates) {
    for (final s in candidates) {
      if (s != null && s.trim().isNotEmpty) return s.trim();
    }
    return '';
  }
}
