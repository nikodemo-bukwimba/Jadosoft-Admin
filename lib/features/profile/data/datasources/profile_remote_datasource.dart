// profile_remote_datasource.dart
// ─────────────────────────────────────────────────────────────
// Fetches own profile data from two endpoints:
//   GET /auth/me  → user object
//   GET /me/roles → { data: { roles, permissions } }
// Token is attached by AuthInterceptor — no manual headers needed.
//
// Uses relative paths (no AppConstants.baseUrl prefix) so Dio's
// configured baseUrl is the single source of truth, consistent
// with all other datasources in the app.
// ─────────────────────────────────────────────────────────────

import 'package:dio/dio.dart';
import 'package:fca/core/error/exceptions.dart';
import 'package:fca/features/auth/data/models/user_model.dart';
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
      final userResponse = await _dio.get('/auth/me');
      final rolesResponse = await _dio.get('/me/roles');

      final userData = userResponse.data;
      final rolesBody = rolesResponse.data as Map<String, dynamic>?;

      if (userData == null) {
        throw const ServerException('Empty response from /auth/me');
      }
      if (rolesBody == null) {
        throw const ServerException('Empty response from /me/roles');
      }

      final user = UserModel.fromJson(userData as Map<String, dynamic>);

      // Shape: { success: true, data: { roles: [], permissions: [] } }
      final rolesData = rolesBody['data'] as Map<String, dynamic>? ?? {};
      final rawRoles = rolesData['roles'] as List<dynamic>? ?? [];
      final rawPerms = rolesData['permissions'] as List<dynamic>? ?? [];

      final roles = rawRoles
          .map((r) => RoleModel.fromJson(r as Map<String, dynamic>))
          .toList();
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
