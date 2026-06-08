// === FILE: lib/core/utils/customer_name_resolver.dart ===
//
// Mirrors OfficerNameResolver but for customers.
// Fetches GET /pharma/orgs/{orgId}/customers and builds a
// customerId → customerName cache used to decorate order JSON
// before model parsing.

import 'package:dio/dio.dart';

class CustomerNameResolver {
  final Dio _dio;
  final String Function() _orgId;

  final Map<String, String> _byId = {};

  DateTime? _lastFetch;
  final Duration staleDuration;

  CustomerNameResolver({
    required Dio dio,
    required String Function() orgId,
    this.staleDuration = const Duration(minutes: 5),
  })  : _dio = dio,
        _orgId = orgId;

  /// Resolve a customer name from their ID.
  /// Returns the raw ID if the name cannot be found.
  Future<String> resolve(String customerId, {bool force = false}) async {
    await _ensureWarm(force: force);
    return _byId[customerId] ?? customerId;
  }

  /// Inject 'customer_name' into [json] when not already present.
  Future<Map<String, dynamic>> inject(
    Map<String, dynamic> json, {
    bool force = false,
  }) async {
    final existing = json['customer_name'];
    if (existing is String && existing.trim().isNotEmpty) return json;

    await _ensureWarm(force: force);

    final name = _resolveFromJson(json);
    if (name == null) return json;

    return {...json, 'customer_name': name};
  }

  Future<void> warmUp({bool force = false}) => _ensureWarm(force: force);

  bool get _isStale =>
      _lastFetch == null ||
      DateTime.now().difference(_lastFetch!) > staleDuration;

  Future<void> _ensureWarm({bool force = false}) async {
    if (!force && !_isStale && _byId.isNotEmpty) return;
    await _fetch();
  }

  Future<void> _fetch() async {
    try {
      final response = await _dio.get(
        '/pharma/orgs/${_orgId()}/customers',
        queryParameters: {'per_page': 500},
      );

      final raw = response.data;
      // Handle both paginated {data: [...]} and bare [...] shapes
      final list = (raw is Map ? (raw['data'] ?? []) : raw) as List? ?? [];

      _byId.clear();

      for (final item in list.whereType<Map<String, dynamic>>()) {
        final id = (item['id'] ?? '').toString();
        if (id.isEmpty) continue;

        // Name resolution priority:
        //   1. item['name']              — customer display name
        //   2. item['business_name']     — B2B alias
        //   3. item['code']              — customer code fallback
        final name = _firstNonEmpty([
          item['name'] as String?,
          item['business_name'] as String?,
          item['code'] as String?,
        ]);

        if (name.isNotEmpty) _byId[id] = name;
      }

      _lastFetch = DateTime.now();
    } catch (_) {
      // Non-fatal — orders still load; customer column falls back to ID.
    }
  }

  String? _resolveFromJson(Map<String, dynamic> j) {
    final candidates = [
      j['customer_id']?.toString(),
      j['buyer_org_id']?.toString(),
      j['metadata']?['customer_id']?.toString(),
    ];
    for (final id in candidates) {
      if (id == null || id.isEmpty) continue;
      final name = _byId[id];
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