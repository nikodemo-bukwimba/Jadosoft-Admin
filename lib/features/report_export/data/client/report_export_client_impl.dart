// report_export_client_impl.dart
// ─────────────────────────────────────────────────────────────────────────────
// Production Dio HTTP client for the Report Export feature.
// Connects to the Laravel backend /api/v1/exports endpoints.
//
// Activate by updating injection_container.dart:
//   sl.registerLazySingleton<ReportExportClient>(
//     () => ReportExportClientImpl(dio: sl()))
// ─────────────────────────────────────────────────────────────────────────────

import 'package:dio/dio.dart';
import 'report_export_client.dart';
import '../../domain/models/request_export_request.dart';
import '../../domain/models/request_export_response.dart';
import '../../domain/models/get_export_status_response.dart';
import '../../domain/models/download_export_response.dart';

class ReportExportClientImpl implements ReportExportClient {
  final Dio _dio;
  static const int _maxRetries = 3;
  static const int _backoffMs = 2000;

  ReportExportClientImpl({required Dio dio}) : _dio = dio;

  Future<Response> _withRetry(Future<Response> Function() fn) async {
    int attempt = 0;
    while (true) {
      try {
        attempt++;
        return await fn();
      } on DioException catch (e) {
        final code = e.response?.statusCode;
        final retryable = e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.receiveTimeout ||
            e.type == DioExceptionType.connectionError ||
            (code != null && code >= 500 && code != 501);
        if (!retryable || attempt >= _maxRetries) rethrow;
        await Future.delayed(Duration(milliseconds: _backoffMs * (1 << (attempt - 1))));
      }
    }
  }

  @override
  Future<RequestExportResponse> requestExport(RequestExportRequest request) async {
    final res = await _withRetry(() => _dio.post('/exports', data: request.toJson()));
    return RequestExportResponse.fromJson(res.data as Map<String, dynamic>);
  }

  @override
  Future<GetExportStatusResponse> getExportStatus(String exportId) async {
    final res = await _withRetry(() => _dio.get('/exports/$exportId'));
    return GetExportStatusResponse.fromJson(res.data as Map<String, dynamic>);
  }

  @override
  Future<DownloadExportResponse> downloadExport(String exportId) async {
    final res = await _withRetry(() => _dio.get('/exports/$exportId/download'));
    return DownloadExportResponse.fromJson(res.data as Map<String, dynamic>);
  }
}