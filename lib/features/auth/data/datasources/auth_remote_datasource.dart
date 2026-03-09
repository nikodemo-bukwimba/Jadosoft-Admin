// auth_remote_datasource.dart  [R3 — Secure Network]
// ─────────────────────────────────────────────────────────────
// All calls go through the shared Dio instance.
// LOGIN RESPONSE NOTE:
//   Laravel Sanctum typically returns: { token: "...", user: {...} }
//   OR just: { access_token: "...", user: {...} }
//   OR: { data: { token: "...", user: {...} } }
//   _extractToken() handles all common shapes.
// ─────────────────────────────────────────────────────────────

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/error/exceptions.dart';
import '../models/user_model.dart';

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
  Future<UserModel> getUser();
  Future<Map<String, dynamic>> getRolesAndPermissions();
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final Dio _dio;
  AuthRemoteDataSourceImpl(this._dio);

  // ── POST /login ───────────────────────────────────────────
  @override
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await _dio.post(
        '/auth/login',
        data: {'email': email, 'password': password},
      );
      final body = _parseBody(response);

      // Debug: log the response shape in dev so we can verify token key
      if (kDebugMode) {
        debugPrint('[AUTH] Login response keys: ${body.keys.toList()}');
        // Log token presence without logging the actual value (R9)
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

  // ── POST /register ────────────────────────────────────────
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
          'name': name,
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

  // ── POST /logout ──────────────────────────────────────────
  @override
  Future<void> logout() async {
    try {
      await _dio.post('/auth/logout');
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) return; // already invalid
      throw _handleDioError(e);
    }
  }

  // ── GET /user ─────────────────────────────────────────────
  @override
  Future<UserModel> getUser() async {
    try {
      final response = await _dio.get('/auth/me');
      final data = response.data;
      if (data == null)
        throw const ServerException('Empty response from /auth/me');
      return UserModel.fromJson(data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // ── GET /me/roles ─────────────────────────────────────────
  @override
  Future<Map<String, dynamic>> getRolesAndPermissions() async {
    try {
      final response = await _dio.get('/me/roles');
      final body = response.data as Map<String, dynamic>?;
      if (body == null)
        throw const ServerException('Empty response from /me/roles');
      // Shape: { success: true, data: { roles: [], permissions: [] } }
      return body['data'] as Map<String, dynamic>? ?? {};
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // ── Token extraction ──────────────────────────────────────
  // Handles the most common Sanctum response shapes:
  //   { "token": "..." }
  //   { "access_token": "..." }
  //   { "data": { "token": "..." } }
  static String? extractToken(Map<String, dynamic> body) => _extractToken(body);

  static String? _extractToken(Map<String, dynamic> body) {
    // Direct key
    if (body['token'] is String) return body['token'] as String;
    if (body['access_token'] is String) return body['access_token'] as String;
    // Nested under 'data'
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
