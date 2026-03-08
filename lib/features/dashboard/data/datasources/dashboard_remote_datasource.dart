// dashboard_remote_datasource.dart
// ─────────────────────────────────────────────────────────────
// Fetches aggregated admin dashboard stats from the API.
//
// Endpoint: GET /admin/dashboard
// Auth:     Bearer token attached automatically by AuthInterceptor.
// Access:   Admin / super-admin only (enforced server-side).
//
// Changing the endpoint:
//   Update AppConstants or pass the path as a constructor arg.
//   The datasource itself should own no URL strings — use constants.
// ─────────────────────────────────────────────────────────────

import 'package:dio/dio.dart';
import 'package:fca/core/constants/app_constants.dart';
import 'package:fca/core/error/exceptions.dart';

import '../models/dashboard_stats_model.dart';

abstract class DashboardRemoteDataSource {
  /// Calls GET /admin/dashboard and returns parsed [DashboardStatsModel].
  Future<DashboardStatsModel> getDashboardStats();
}

class DashboardRemoteDataSourceImpl implements DashboardRemoteDataSource {
  final Dio _dio;

  DashboardRemoteDataSourceImpl(this._dio);

  @override
  Future<DashboardStatsModel> getDashboardStats() async {
    try {
      final response = await _dio.get(
        '${AppConstants.baseUrl}/admin/dashboard',
      );

      final body = response.data;

      if (body == null) {
        throw const ServerException('Empty response from /admin/dashboard');
      }

      if (body is! Map<String, dynamic>) {
        throw const ServerException(
          'Unexpected response format from /admin/dashboard',
        );
      }

      return DashboardStatsModel.fromJson(body);
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode;
      final msg = _extractMessage(e) ?? 'Failed to load dashboard';

      if (statusCode == 401) throw AuthException(msg);
      if (statusCode == 403) throw AuthException('Access denied to dashboard');

      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw const NetworkException(
          'Connection timed out. Check your internet.',
        );
      }
      if (e.type == DioExceptionType.connectionError) {
        throw const NetworkException(
          'Cannot reach the server. Check your connection.',
        );
      }

      throw ServerException(msg, statusCode: statusCode);
    }
  }

  // ── Helpers ───────────────────────────────────────────────

  String? _extractMessage(DioException e) {
    final data = e.response?.data;
    if (data is Map<String, dynamic>) {
      return data['message'] as String?;
    }
    return null;
  }
}
