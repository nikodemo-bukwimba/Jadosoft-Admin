// auth_remote_datasource.dart
// ─────────────────────────────────────────────────────────────
// FIX 1: getAuthMe() — org_id is now dynamic, not hardcoded.
//   On first login: no org_id sent → server picks highest-level
//   membership → returns user.org_id in response → we store it.
//   On refresh: stored org_id is passed → correct permissions.
//
// FIX 2: register() — sends 'name' (→ actor.display_name) and
//   a generated 'username' (→ users.username).
// ─────────────────────────────────────────────────────────────

import 'dart:math';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/error/exceptions.dart';
import '../models/user_model.dart';

class AuthMeResponse {
  final UserModel user;
  final List<RoleModel> roles;
  final List<PermissionModel> permissions;

  /// org_id echoed back by the server (membership org). null = no membership.
  final String? resolvedOrgId;

  /// org_status returned from backend:
  /// null | 'pending_approval' | 'active' | 'suspended' | 'rejected'
  final String? orgStatus;

  const AuthMeResponse({
    required this.user,
    required this.roles,
    required this.permissions,
    this.resolvedOrgId,
    this.orgStatus,
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
  Future<AuthMeResponse> getAuthMe({String? orgId});
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final Dio _dio;
  AuthRemoteDataSourceImpl(this._dio);

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

  @override
  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
    String? phone,
  }) async {
    try {
      final username = _generateUsername(name);
      final response = await _dio.post(
        '/auth/register',
        data: {
          'name': name, // → actor.display_name (real full name)
          'username': username, // → users.username (auto-generated)
          'email': email,
          'password': password,
          'password_confirmation': passwordConfirmation,
          if (phone != null && phone.isNotEmpty) 'phone': phone,
        },
      );
      final body = _parseBody(response);
      if (kDebugMode) {
        debugPrint('[AUTH] Register response keys: ${body.keys.toList()}');
        debugPrint('[AUTH] Registered: name=$name, username=$username');
      }
      return body;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<void> logout() async {
    try {
      await _dio.post('/auth/logout');
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) return;
      throw _handleDioError(e);
    }
  }

  // ── GET /auth/me ──────────────────────────────────────────
  // orgId = null on first login → server picks highest-level membership.
  // orgId = stored value on refresh → correct branch permissions.
  // The backend echoes back user.org_id so we know which org was used.
  @override
  Future<AuthMeResponse> getAuthMe({String? orgId}) async {
    try {
      final response = await _dio.get(
        '/auth/me',
        queryParameters: orgId != null ? {'org_id': orgId} : null,
      );
      final raw = response.data;

      if (raw == null)
        throw const ServerException('Empty response from /auth/me');
      if (raw is! Map<String, dynamic>)
        throw const ServerException('Unexpected response format from /auth/me');

      final userJson = raw['user'] as Map<String, dynamic>? ?? raw;
      final user = UserModel.fromJson(userJson);

      final rawPerms = raw['permissions'] as List<dynamic>? ?? [];
      final permissions = rawPerms
          .map((p) => PermissionModel.fromJson(p as Map<String, dynamic>))
          .toList();

      final rawRoles = userJson['roles'] as List<dynamic>? ?? [];
      final roles = rawRoles
          .map((r) => RoleModel.fromJson(r as Map<String, dynamic>))
          .toList();

      // The backend now echoes user.org_id — the membership org for this call.
      final resolvedOrgId =
          userJson['org_id']?.toString() ?? raw['org_id']?.toString() ?? orgId;

      // ── NEW: extract org status ────────────────────────────────
      final orgStatus = userJson['org_status'] as String?;

      if (kDebugMode) {
        debugPrint(
          '[AUTH] /auth/me: user=${user.email}, '
          'roles=${roles.length}, permissions=${permissions.length}, '
          'resolved_org_id=$resolvedOrgId',
        );
      }

      return AuthMeResponse(
        user: user,
        roles: roles,
        permissions: permissions,
        resolvedOrgId: resolvedOrgId,
        orgStatus: orgStatus,
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

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

  // "John Mwangi" → "john_mwangi_4j2k"
  String _generateUsername(String fullName) {
    final base = fullName
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\s]'), '')
        .trim()
        .replaceAll(RegExp(r'\s+'), '_');
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final rand = Random();
    final suffix = List.generate(
      4,
      (_) => chars[rand.nextInt(chars.length)],
    ).join();
    return '${base}_$suffix';
  }

  Map<String, dynamic> _parseBody(Response response) {
    final data = response.data;
    if (data == null) throw const ServerException('Empty response body');
    if (data is! Map<String, dynamic>)
      throw const ServerException('Unexpected response format');
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
