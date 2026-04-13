// auth_remote_datasource.dart
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// All calls go through the shared Dio instance.
//
// ENDPOINTS:
//   POST /auth/login    â†’ { user: {...}, token: "..." }
//   POST /auth/register â†’ { user: {...}, token: "..." }
//   POST /auth/logout   â†’ 204
//   GET  /auth/me       â†’ { data: { user + roles + permissions } }
//
// REMOVED: GET /me/roles â€” this endpoint never existed in the
// HMSCP API. Roles and permissions are now returned inline by
// GET /auth/me as part of the user resource.
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/error/exceptions.dart';
import '../models/user_model.dart';

/// Raw data returned from GET /auth/me â€” contains user, roles,
/// and permissions all in one response.
class AuthMeResponse {
  final UserModel user;
  final List<RoleModel> roles;
  final List<PermissionModel> permissions;

  const AuthMeResponse({
    required this.user,
    required this.roles,
    required this.permissions,
  });
}

abstract class AuthRemoteDataSource {
  Future<Map<String, dynamic>> login(String email, String password);
  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
    String? phone,
  });
  Future<void> logout();

  /// Fetches the full authenticated user profile including roles
  /// and permissions from GET /auth/me.
  Future<AuthMeResponse> getAuthMe();
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final Dio _dio;
  AuthRemoteDataSourceImpl(this._dio);

  // â”€â”€ POST /auth/login â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  @override
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await _dio.post(
        '/auth/login',
        data: {'email': email, 'password': password},
      );
      final body = _parseBody(response);

      if (kDebugMode) {
        debugPrint('[AUTH] Login response keys: ${body.keys.toList()}');
        final token = _extractToken(body);
        debugPrint(
          '[AUTH] Token extracted: ${token != null ? "YES (${token.length} chars)" : "NO â€” check response shape"}',
        );
      }

      return body;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // â”€â”€ POST /auth/register â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  @override
  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
    String? phone,
  }) async {
    try {
      final response = await _dio.post(
        '/auth/register',
        data: {
          'username': name,
          'email': email,
          'password': password,
          'password_confirmation': passwordConfirmation,
          if (phone != null && phone.isNotEmpty) 'phone': phone,
        },
      );
      final body = _parseBody(response);

      if (kDebugMode) {
        debugPrint('[AUTH] Register response keys: ${body.keys.toList()}');
        final token = _extractToken(body);
        debugPrint(
          '[AUTH] Token extracted: ${token != null ? "YES" : "NO â€” check response shape"}',
        );
      }

      return body;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // â”€â”€ POST /auth/logout â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  @override
  Future<void> logout() async {
    try {
      await _dio.post('/auth/logout');
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) return; // already invalid
      throw _handleDioError(e);
    }
  }

  // â”€â”€ GET /auth/me â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  // Returns user + roles + permissions in one call.
  //
  // Expected response shape:
  //   { "data": { ...user fields, "roles": [...], "permissions": [...] } }
  // OR flat (no wrapper):
  //   { ...user fields, "roles": [...], "permissions": [...] }
  @override
  Future<AuthMeResponse> getAuthMe() async {
    try {
      final response = await _dio.get(
        '/auth/me',
        queryParameters: {'org_id': '01KM3J1485S5T17RXQ6JRWF8JR'},
      );
      final raw = response.data;

      if (raw == null)
        throw const ServerException('Empty response from /auth/me');

      if (raw is! Map<String, dynamic>) {
        throw const ServerException('Unexpected response format from /auth/me');
      }

      // NEW: response is { user: {...}, permissions: [...] }
      // Extract user object and permissions separately
      final userJson =
          raw['user'] as Map<String, dynamic>? ??
          raw; // fallback to flat if no 'user' key
      final user = UserModel.fromJson(userJson);

      // Permissions are at TOP LEVEL, not inside user
      final rawPerms = raw['permissions'] as List<dynamic>? ?? [];
      final permissions = rawPerms
          .map((p) => PermissionModel.fromJson(p as Map<String, dynamic>))
          .toList();

      final rawRoles = userJson['roles'] as List<dynamic>? ?? [];
      final roles = rawRoles
          .map((r) => RoleModel.fromJson(r as Map<String, dynamic>))
          .toList();

      if (kDebugMode) {
        debugPrint(
          '[AUTH] /auth/me: user=${user.email}, '
          'roles=${roles.length}, permissions=${permissions.length}',
        );
      }

      return AuthMeResponse(user: user, roles: roles, permissions: permissions);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // â”€â”€ Token extraction â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  static String? extractToken(Map<String, dynamic> body) => _extractToken(body);

  static String? _extractToken(Map<String, dynamic> body) {
    if (body['token'] is String) return body['token'] as String;
    if (body['access_token'] is String) return body['access_token'] as String;
    final data = body['data'];
    if (data is Map<String, dynamic>) {
      if (data['token'] is String) return data['token'] as String;
      if (data['access_token'] is String) return data['access_token'] as String;
    }
    return null;
  }

  // â”€â”€ Helpers â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Map<String, dynamic> _parseBody(Response response) {
    final data = response.data;
    if (data == null) throw const ServerException('Empty response body');
    if (data is! Map<String, dynamic>) {
      throw const ServerException('Unexpected response format');
    }
    return data;
  }

  Exception _handleDioError(DioException e) {
    final statusCode = e.response?.statusCode;
    final responseData = e.response?.data;

    String message = 'An error occurred. Please try again.';
    if (responseData is Map<String, dynamic>) {
      if (responseData['message'] is String) {
        message = responseData['message'] as String;
      } else if (responseData['errors'] is Map) {
        final errors = responseData['errors'] as Map<String, dynamic>;
        final firstField = errors.values.first;
        if (firstField is List && firstField.isNotEmpty) {
          message = firstField.first.toString();
        }
      }
    }

    if (statusCode == 401) return AuthException(message);
    if (statusCode == 422) return ServerException(message, statusCode: 422);
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return const NetworkException(
        'Connection timed out. Check your internet.',
      );
    }
    if (e.type == DioExceptionType.connectionError) {
      return const NetworkException(
        'Cannot reach the server. Check your connection.',
      );
    }
    return ServerException(message, statusCode: statusCode);
  }
}
