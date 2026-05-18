// notification_remote_datasource.dart
// ─────────────────────────────────────────────────────────────
// REAL API — no mock data.
//
// Backend endpoint (NotificationController, platform module):
//   GET  /api/v1/orgs/{orgId}/notifications
//   GET  /api/v1/orgs/{orgId}/notifications/{id}
//   POST /api/v1/orgs/{orgId}/notifications/{id}/retry
//
// Supported query params for getAll():
//   status   — queued | sent | delivered | failed
//   channel  — sms | whatsapp | in_app
//   per_page — integer (default 50)
//   page     — integer
//
// NOTE: create / update / delete do NOT exist on the backend.
//       Those methods are removed from this implementation.
// ─────────────────────────────────────────────────────────────

import 'package:dio/dio.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/context/org_context.dart';
import '../models/notification_model.dart';

abstract class NotificationRemoteDataSource {
  Future<List<NotificationModel>> getAll({
    String? status,
    String? channel,
    int perPage,
    int page,
  });
  Future<NotificationModel> getById(String id);
  Future<NotificationModel> retry(String id);
}

class NotificationRemoteDataSourceImpl implements NotificationRemoteDataSource {
  final Dio _dio;
  final OrgContext _orgContext;

  NotificationRemoteDataSourceImpl({
    required Dio dio,
    required OrgContext orgContext,
  }) : _dio = dio,
       _orgContext = orgContext;

  /// Backend route: GET /api/v1/orgs/{orgId}/notifications
  // String get _base => '/orgs/${_orgContext.effectiveOrgId}/notifications';
  String get _base => '/notifications';

  @override
  Future<List<NotificationModel>> getAll({
    String? status,
    String? channel,
    int perPage = 50,
    int page = 1,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'per_page': perPage,
        'page': page,
        if (status != null && status.isNotEmpty) 'status': status,
        if (channel != null && channel.isNotEmpty) 'channel': channel,
      };

      final response = await _dio.get(_base, queryParameters: queryParams);
      print(response.data);

      // Backend returns paginated response: { data: [...], meta: {...} }
      // or flat list — handle both shapes.
      final raw = response.data;

      List<dynamic> items = [];

      if (raw is List) {
        items = raw;
      } else if (raw is Map<String, dynamic>) {
        // Laravel paginator inside notifications key
        if (raw['notifications'] is Map<String, dynamic>) {
          final notifications = raw['notifications'] as Map<String, dynamic>;

          if (notifications['data'] is List) {
            items = notifications['data'] as List<dynamic>;
          }
        }
        // Plain data array
        else if (raw['data'] is List) {
          items = raw['data'] as List<dynamic>;
        }
      }

      return items
          .map((e) => NotificationModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ServerException(
        _extractMessage(e),
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<NotificationModel> getById(String id) async {
    try {
      final response = await _dio.get('$_base/$id');
      final data = response.data is Map
          ? (response.data['data'] ?? response.data) as Map<String, dynamic>
          : response.data as Map<String, dynamic>;
      return NotificationModel.fromJson(data);
    } on DioException catch (e) {
      throw ServerException(
        _extractMessage(e),
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<NotificationModel> retry(String id) async {
    try {
      final response = await _dio.post('$_base/$id/retry');
      final data = response.data is Map
          ? (response.data['data'] ??
                    response.data['delivery'] ??
                    response.data)
                as Map<String, dynamic>
          : response.data as Map<String, dynamic>;
      return NotificationModel.fromJson(data);
    } on DioException catch (e) {
      throw ServerException(
        _extractMessage(e),
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  String _extractMessage(DioException e) {
    final data = e.response?.data;
    if (data is Map<String, dynamic> && data['message'] is String) {
      return data['message'] as String;
    }
    return 'An error occurred. Please try again.';
  }
}
