// profile_remote_datasource.dart
// ─────────────────────────────────────────────────────────────
// Fetches own profile data from a single endpoint:
//   GET /auth/me → { data: { user + roles + permissions } }
//
// REMOVED: GET /me/roles — this endpoint never existed in the
// HMSCP API. The /auth/me response now includes roles and
// permissions inline.
//
// Token is attached by AuthInterceptor — no manual headers needed.
// Uses relative paths so Dio's baseUrl is the single source of truth.
// ─────────────────────────────────────────────────────────────

import 'package:dio/dio.dart';
import 'package:jadosoft_admin/core/error/exceptions.dart';
import 'package:jadosoft_admin/features/auth/data/models/user_model.dart';
import '../models/profile_model.dart';

abstract class ProfileRemoteDataSource {
  Future<ProfileModel> getOwnProfile();
}

class ProfileRemoteDataSourceImpl implements ProfileRemoteDataSource {
  final Dio _dio;
  ProfileRemoteDataSourceImpl(this._dio);

  @override
  Future<ProfileModel> getOwnProfile() async {
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

      // Parse user (includes roles inline)
      final user = UserModel.fromJson(body);

      // Parse roles from the same response
      final rawRoles = body['roles'] as List<dynamic>? ?? [];
      final roles = rawRoles
          .map((r) => RoleModel.fromJson(r as Map<String, dynamic>))
          .toList();

      // Parse permissions from the same response
      final rawPerms = body['permissions'] as List<dynamic>? ?? [];
      final permissions = rawPerms
          .map((p) => PermissionModel.fromJson(p as Map<String, dynamic>))
          .toList();

      return ProfileModel(
        user: user,
        roles: roles,
        permissions: permissions,
        fetchedAt: DateTime.now(),
      );
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode;
      final msg = _extractMessage(e) ?? 'Failed to load profile';
      if (statusCode == 401) throw AuthException(msg);
      if (e.type == DioExceptionType.connectionError) {
        throw const NetworkException('Cannot reach the server.');
      }
      throw ServerException(msg, statusCode: statusCode);
    }
  }

  String? _extractMessage(DioException e) {
    final data = e.response?.data;
    if (data is Map<String, dynamic>) return data['message'] as String?;
    return null;
  }
}
