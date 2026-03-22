// paginated_response.dart
// ─────────────────────────────────────────────────────────────
// Handles Nexora API paginated responses.
//
// All list endpoints return:
// {
//   "current_page": 1,
//   "data": [ ... items ... ],
//   "from": 1,
//   "to": 25,
//   "total": 47,
//   "per_page": 25,
//   "last_page": 2,
//   "next_page_url": "...?page=2",
//   "prev_page_url": null
// }
//
// This helper:
//   1. Unwraps the 'data' array from the paginated envelope.
//   2. Exposes pagination metadata for the UI (total, lastPage, etc.).
//   3. Converts each item via a provided fromJson factory.
//
// Usage:
//   final response = await _dio.get(path, queryParameters: params);
//   final paginated = PaginatedResponse.fromJson(
//     response.data,
//     (json) => CustomerModel.fromJson(json),
//   );
//   return paginated; // .items, .total, .currentPage, etc.
// ─────────────────────────────────────────────────────────────

class PaginatedResponse<T> {
  final List<T> items;
  final int currentPage;
  final int lastPage;
  final int total;
  final int perPage;
  final int? from;
  final int? to;
  final String? nextPageUrl;
  final String? prevPageUrl;

  const PaginatedResponse({
    required this.items,
    required this.currentPage,
    required this.lastPage,
    required this.total,
    required this.perPage,
    this.from,
    this.to,
    this.nextPageUrl,
    this.prevPageUrl,
  });

  /// Whether there are more pages after the current one.
  bool get hasNextPage => currentPage < lastPage;

  /// Whether this is the first page.
  bool get isFirstPage => currentPage == 1;

  /// Parse from Nexora paginated JSON.
  ///
  /// [fromJson] converts each raw item Map into the model type [T].
  /// Handles both paginated wrapper and raw List fallback.
  factory PaginatedResponse.fromJson(
    dynamic raw,
    T Function(Map<String, dynamic> json) fromJson,
  ) {
    // ── Case 1: Standard paginated envelope ────────────────
    if (raw is Map<String, dynamic> && raw.containsKey('data')) {
      final dataList = raw['data'] as List<dynamic>? ?? [];
      final items = dataList
          .map((e) => fromJson(e as Map<String, dynamic>))
          .toList();

      return PaginatedResponse<T>(
        items: items,
        currentPage: _parseInt(raw['current_page']) ?? 1,
        lastPage: _parseInt(raw['last_page']) ?? 1,
        total: _parseInt(raw['total']) ?? items.length,
        perPage: _parseInt(raw['per_page']) ?? 25,
        from: _parseInt(raw['from']),
        to: _parseInt(raw['to']),
        nextPageUrl: raw['next_page_url'] as String?,
        prevPageUrl: raw['prev_page_url'] as String?,
      );
    }

    // ── Case 2: Raw list (no pagination envelope) ──────────
    if (raw is List) {
      final items = raw
          .map((e) => fromJson(e as Map<String, dynamic>))
          .toList();
      return PaginatedResponse<T>(
        items: items,
        currentPage: 1,
        lastPage: 1,
        total: items.length,
        perPage: items.length,
      );
    }

    // ── Case 3: Unexpected shape ───────────────────────────
    return PaginatedResponse<T>(
      items: const [],
      currentPage: 1,
      lastPage: 1,
      total: 0,
      perPage: 25,
    );
  }

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }
}

/// Helper to unwrap a single-resource Nexora API response.
///
/// Handles:
///   { "data": { ... } }     → returns the inner map
///   { "message": "...", "org": { ... } }  → returns the named key
///   { "id": "...", ... }     → returns as-is (flat response)
Map<String, dynamic> unwrapSingleResponse(
  dynamic raw, {
  String? dataKey,
  String endpoint = '',
}) {
  if (raw == null) {
    throw Exception('Empty response from $endpoint');
  }

  if (raw is Map<String, dynamic>) {
    // Try named key first (e.g., 'org', 'plan', 'report')
    if (dataKey != null && raw.containsKey(dataKey)) {
      final inner = raw[dataKey];
      if (inner is Map<String, dynamic>) return inner;
    }

    // Standard 'data' wrapper
    if (raw.containsKey('data') && raw['data'] is Map<String, dynamic>) {
      return raw['data'] as Map<String, dynamic>;
    }

    // Flat response (no wrapper)
    return raw;
  }

  throw Exception('Unexpected response format from $endpoint');
}