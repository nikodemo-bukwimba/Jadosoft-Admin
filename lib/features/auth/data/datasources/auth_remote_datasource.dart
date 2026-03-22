// auth_remote_datasource.dart
// ─────────────────────────────────────────────────────────────
// All calls go through the shared Dio instance.
//
// ENDPOINTS:
//   POST /auth/login    → { user: {...}, token: "..." }
//   POST /auth/register → { user: {...}, token: "..." }
//   POST /auth/logout   → 204
//   GET  /auth/me       → { data: { user + roles + permissions } }
//
// REMOVED: GET /me/roles — this endpoint never existed in the
// HMSCP API. Roles and permissions are now returned inline by
// GET /auth/me as part of the user resource.
// ─────────────────────────────────────────────────────────────

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/error/exceptions.dart';
import '../models/user_model.dart';

/// Raw data returned from GET /auth/me — contains user, roles,
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

  // ── POST /auth/login ──────────────────────────────────────
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
          '[AUTH] Token extracted: ${token != null ? "YES (${token.length} chars)" : "NO — check response shape"}',
        );
      }

      return body;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // ── POST /auth/register ───────────────────────────────────
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
          '[AUTH] Token extracted: ${token != null ? "YES" : "NO — check response shape"}',
        );
      }

      return body;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // ── POST /auth/logout ─────────────────────────────────────
  @override
  Future<void> logout() async {
    try {
      await _dio.post('/auth/logout');
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) return; // already invalid
      throw _handleDioError(e);
    }
  }

  // ── GET /auth/me ──────────────────────────────────────────
  // Returns user + roles + permissions in one call.
  //
  // Expected response shape:
  //   { "data": { ...user fields, "roles": [...], "permissions": [...] } }
  // OR flat (no wrapper):
  //   { ...user fields, "roles": [...], "permissions": [...] }
  @override
  Future<AuthMeResponse> getAuthMe() async {
    try {
      final response = await _dio.get('/auth/me');
      final raw = response.data;

      if (raw == null) {
        throw const ServerException('Empty response from /auth/me');
      }

      // Unwrap: may be nested under 'data' or flat
      final Map<String, dynamic> body;
      if (raw is Map<String, dynamic>) {
        body = raw.containsKey('data') && raw['data'] is Map<String, dynamic>
            ? raw['data'] as Map<String, dynamic>
            : raw;
      } else {
        throw const ServerException('Unexpected response format from /auth/me');
      }

      // Parse user (roles embedded in user JSON too)
      final user = UserModel.fromJson(body);

      // Parse permissions — may be at top level of the response
      final rawPerms = body['permissions'] as List<dynamic>? ?? [];
      final permissions = rawPerms
          .map((p) => PermissionModel.fromJson(p as Map<String, dynamic>))
          .toList();

      // Roles are already parsed inside UserModel.fromJson,
      // but we also extract them here for the auth flow.
      final rawRoles = body['roles'] as List<dynamic>? ?? [];
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

  // ── Token extraction ──────────────────────────────────────
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

  // ── Helpers ───────────────────────────────────────────────

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
