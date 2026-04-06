// actor_remote_datasource.dart
// ─────────────────────────────────────────────────────────────
// Fetches actor data from the HMSCP Platform API.
//
// Endpoints consumed:
//   GET    /actors            → { "data": [...], "links": {}, "meta": {} }
//   GET    /actors/{id}       → { "data": { ... } }
//   POST   /actors            → { "data": { ... } }
//   PUT    /actors/{id}       → { "data": { ... } }
//   DELETE /actors/{id}       → 204 No Content
//   POST   /actors/{id}/restore → { "data": { ... } }
//
// HMSCP wraps all responses in a "data" key. List endpoints
// are paginated with "links" and "meta" keys.
//
// Token is attached by AuthInterceptor — no manual headers.
// Uses relative paths so Dio's baseUrl is the single source of truth.
// ─────────────────────────────────────────────────────────────

import 'package:dio/dio.dart';
import '../../../../core/error/exceptions.dart';
import '../models/actor_model.dart';
import '../../../../core/context/org_context.dart';

abstract class ActorRemoteDataSource {
  Future<List<ActorModel>> getAll({
    String? status,
    String? search,
    int? typeId,
    int? perPage,
    int? page,
  });
  Future<ActorModel> getById(String id);
  Future<ActorModel> create(Map<String, dynamic> data);
  Future<ActorModel> update(String id, Map<String, dynamic> data);
  Future<void> delete(String id);
  Future<ActorModel> restore(String id);
}

class ActorRemoteDataSourceImpl implements ActorRemoteDataSource {
  final Dio _dio;
  final OrgContext _orgContext;

  ActorRemoteDataSourceImpl({required Dio dio, required OrgContext orgContext})
    : _dio = dio,
      _orgContext = orgContext;

  // ── LIST ─────────────────────────────────────────────────

  @override
  Future<List<ActorModel>> getAll({
    String? status,
    String? search,
    int? typeId,
    int? perPage,
    int? page,
  }) async {
    try {
      final orgId = _orgContext.effectiveOrgId;
      final queryParams = <String, dynamic>{};
      if (status != null) queryParams['status'] = status;
      if (search != null) queryParams['search'] = search;
      if (perPage != null) queryParams['per_page'] = perPage;
      if (page != null) queryParams['page'] = page;

      final response = await _dio.get(
        'orgs/$orgId/members',
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      final raw = response.data;
      if (raw == null)
        throw const ServerException('Empty response from orgs/members');

      final List<dynamic> items;
      if (raw is Map<String, dynamic> && raw.containsKey('data')) {
        items = raw['data'] as List<dynamic>;
      } else if (raw is List) {
        items = raw;
      } else {
        throw const ServerException(
          'Unexpected response format from orgs/members',
        );
      }

      final now = DateTime.now().toIso8601String();

      return items
          .where(
            (e) =>
                e is Map<String, dynamic> &&
                e['user'] is Map &&
                e['user']['actor'] is Map,
          )
          .map((e) {
            final membership = e as Map<String, dynamic>;
            final actor = Map<String, dynamic>.from(
              membership['user']['actor'] as Map<String, dynamic>,
            );
            final orgRole = membership['org_role'] as Map<String, dynamic>?;

            // Ensure required date fields exist
            actor.putIfAbsent('created_at', () => now);
            actor.putIfAbsent('updated_at', () => now);

            // Inject orgRole as synthetic actor_type if actor_types is empty
            // ActorTypeModel expects int id — use 0 as synthetic fallback
            final existingTypes = actor['actor_types'] as List?;
            if ((existingTypes == null || existingTypes.isEmpty) &&
                orgRole != null) {
              final roleName = orgRole['name'] as String? ?? 'member';
              actor['actor_types'] = [
                {
                  'id': 0,
                  'code': roleName.toLowerCase().replaceAll(' ', '_'),
                  'label': roleName,
                },
              ];
            }

            return ActorModel.fromJson(actor);
          })
          .toList();
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  // ── GET BY ID ────────────────────────────────────────────

  @override
  Future<ActorModel> getById(String id) async {
    try {
      final response = await _dio.get('actors/$id');
      final body = _unwrapSingle(response.data, 'actors/$id');
      return ActorModel.fromJson(body);
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  // ── CREATE ───────────────────────────────────────────────

  @override
  Future<ActorModel> create(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post('actors', data: data);
      final body = _unwrapSingle(response.data, 'actors');
      return ActorModel.fromJson(body);
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  // ── UPDATE ───────────────────────────────────────────────

  @override
  Future<ActorModel> update(String id, Map<String, dynamic> data) async {
    try {
      final response = await _dio.put('actors/$id', data: data);
      final body = _unwrapSingle(response.data, 'actors/$id');
      return ActorModel.fromJson(body);
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  // ── DELETE ───────────────────────────────────────────────

  @override
  Future<void> delete(String id) async {
    try {
      await _dio.delete('actors/$id');
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  // ── RESTORE ──────────────────────────────────────────────

  @override
  Future<ActorModel> restore(String id) async {
    try {
      final response = await _dio.post('actors/$id/restore');
      final body = _unwrapSingle(response.data, 'actors/$id/restore');
      return ActorModel.fromJson(body);
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  // ── Helpers ──────────────────────────────────────────────

  /// Unwraps HMSCP single-resource response:
  /// may be nested under 'data' or flat.
  Map<String, dynamic> _unwrapSingle(dynamic raw, String endpoint) {
    if (raw == null) {
      throw ServerException('Empty response from $endpoint');
    }

    if (raw is Map<String, dynamic>) {
      return raw.containsKey('data') && raw['data'] is Map<String, dynamic>
          ? raw['data'] as Map<String, dynamic>
          : raw;
    }

    throw ServerException('Unexpected response format from $endpoint');
  }

  /// Maps DioException to typed app exceptions following the
  /// profile datasource pattern.
  Exception _mapDioException(DioException e) {
    final statusCode = e.response?.statusCode;
    final message =
        _extractMessage(e) ?? 'An error occurred. Please try again.';

    if (statusCode == 401) return AuthException(message);
    if (e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout) {
      return NetworkException('Cannot reach the server.');
    }

    return ServerException(message, statusCode: statusCode);
  }

  String? _extractMessage(DioException e) {
    final data = e.response?.data;
    if (data is Map<String, dynamic>) return data['message'] as String?;
    return null;
  }
}
