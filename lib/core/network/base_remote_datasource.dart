// base_remote_datasource.dart
// ─────────────────────────────────────────────────────────────
// Base class for all remote datasources.
//
// Provides:
//   - Consistent error handling (DioException → typed app exceptions)
//   - Response unwrapping (pagination envelope, 'data' wrapper)
//   - Shared Dio reference
//
// Subclasses only need to define their endpoint paths and
// model-specific fromJson factories.  Error handling is inherited.
//
// Usage:
//   class CustomerRemoteDataSourceImpl extends BaseRemoteDataSource {
//     CustomerRemoteDataSourceImpl({required super.dio});
//     ...
//   }
// ─────────────────────────────────────────────────────────────

import 'package:dio/dio.dart';
import '../error/exceptions.dart';
import 'paginated_response.dart';

abstract class BaseRemoteDataSource {
  final Dio dio;

  BaseRemoteDataSource({required this.dio});

  // ── Paginated list fetch ─────────────────────────────────

  /// Fetches a paginated list from [path] with optional [queryParams].
  /// Returns a [PaginatedResponse] using the provided [fromJson] factory.
  Future<PaginatedResponse<T>> fetchPaginatedList<T>(
    String path,
    T Function(Map<String, dynamic>) fromJson, {
    Map<String, dynamic>? queryParams,
  }) async {
    try {
      final response = await dio.get(
        path,
        queryParameters: queryParams,
      );
      return PaginatedResponse.fromJson(response.data, fromJson);
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  // ── Single resource fetch ────────────────────────────────

  /// Fetches a single resource from [path].
  /// Unwraps the response from optional 'data' wrapper.
  Future<T> fetchSingle<T>(
    String path,
    T Function(Map<String, dynamic>) fromJson, {
    String? dataKey,
  }) async {
    try {
      final response = await dio.get(path);
      final body = unwrapSingleResponse(
        response.data,
        dataKey: dataKey,
        endpoint: path,
      );
      return fromJson(body);
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  // ── POST (create) ────────────────────────────────────────

  /// Posts [data] to [path] and parses the response.
  Future<T> postAndParse<T>(
    String path,
    Map<String, dynamic> data,
    T Function(Map<String, dynamic>) fromJson, {
    String? dataKey,
  }) async {
    try {
      final response = await dio.post(path, data: data);
      final body = unwrapSingleResponse(
        response.data,
        dataKey: dataKey,
        endpoint: path,
      );
      return fromJson(body);
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  // ── PATCH (update) ───────────────────────────────────────

  /// Patches [data] to [path] and parses the response.
  Future<T> patchAndParse<T>(
    String path,
    Map<String, dynamic> data,
    T Function(Map<String, dynamic>) fromJson, {
    String? dataKey,
  }) async {
    try {
      final response = await dio.patch(path, data: data);
      final body = unwrapSingleResponse(
        response.data,
        dataKey: dataKey,
        endpoint: path,
      );
      return fromJson(body);
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  // ── POST (action — no body expected in request) ──────────

  /// Posts to [path] with optional [data], returns parsed response.
  /// Used for transition actions: approve, reject, ship, etc.
  Future<T> postAction<T>(
    String path,
    T Function(Map<String, dynamic>) fromJson, {
    Map<String, dynamic>? data,
    String? dataKey,
  }) async {
    try {
      final response = await dio.post(path, data: data);
      final body = unwrapSingleResponse(
        response.data,
        dataKey: dataKey,
        endpoint: path,
      );
      return fromJson(body);
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  // ── DELETE ────────────────────────────────────────────────

  Future<void> deleteResource(String path) async {
    try {
      await dio.delete(path);
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  // ── Error mapping ────────────────────────────────────────

  /// Maps DioException to typed app exceptions.
  Exception mapDioException(DioException e) {
    final statusCode = e.response?.statusCode;
    final message = _extractMessage(e) ?? 'An error occurred. Please try again.';

    if (statusCode == 401) return AuthException(message);
    if (statusCode == 403) return AuthException('Access denied: $message');
    if (statusCode == 404) return ServerException('Not found', statusCode: 404);
    if (statusCode == 422) return ServerException(message, statusCode: 422);

    if (e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout) {
      return const NetworkException('Cannot reach the server. Check your connection.');
    }

    return ServerException(message, statusCode: statusCode);
  }

  String? _extractMessage(DioException e) {
    final data = e.response?.data;
    if (data is Map<String, dynamic>) {
      // Standard Nexora error shape: { "message": "...", "errors": { ... } }
      if (data['message'] is String) return data['message'] as String;

      // Validation errors: first field's first error
      if (data['errors'] is Map) {
        final errors = data['errors'] as Map<String, dynamic>;
        final firstField = errors.values.first;
        if (firstField is List && firstField.isNotEmpty) {
          return firstField.first.toString();
        }
      }
    }
    return null;
  }
}