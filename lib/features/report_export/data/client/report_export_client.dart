import 'package:dio/dio.dart';
import '../../domain/models/request_export_response.dart';
import '../../domain/models/request_export_request.dart';
import '../../domain/models/get_export_status_response.dart';
import '../../domain/models/download_export_response.dart';

class ReportExportClient {
  final Dio _dio;
  static const int _maxRetries = 3;
  static const int _backoffMs = 2000;

  ReportExportClient({required Dio dio}) : _dio = dio {
    _dio.options.baseUrl = 'http://localhost:8000/api/v1';
    _dio.options.connectTimeout = const Duration(seconds: 120000);
    _dio.options.receiveTimeout = const Duration(seconds: 120000);
  }



  /// Executes [request] with exponential backoff retry on transient failures.
  Future<Response> _requestWithRetry(
    Future<Response> Function() request,
  ) async {
    int attempt = 0;
    while (true) {
      try {
        attempt++;
        return await request();
      } on DioException catch (e) {
        final isRetryable = e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.receiveTimeout ||
            e.type == DioExceptionType.connectionError ||
            (e.response != null && e.response!.statusCode != null && e.response!.statusCode! >= 500);

        if (!isRetryable || attempt >= _maxRetries) rethrow;

        final delay = _backoffMs * (1 << (attempt - 1));
        await Future.delayed(Duration(milliseconds: delay));
      }
    }
  }

  Future<RequestExportResponse> requestExport(RequestExportRequest request) async {
    final response = await _requestWithRetry(
      () => _dio.post('/exports', data: request.toJson()),
    );
    return RequestExportResponse.fromJson(response.data as Map<String, dynamic>);
  }
  Future<GetExportStatusResponse> getExportStatus(String exportId) async {
    final response = await _requestWithRetry(
      () => _dio.get('/exports/' + exportId),
    );
    return GetExportStatusResponse.fromJson(response.data as Map<String, dynamic>);
  }
  Future<DownloadExportResponse> downloadExport(String exportId) async {
    final response = await _requestWithRetry(
      () => _dio.get('/exports/' + exportId + '/download'),
    );
    return DownloadExportResponse.fromJson(response.data as Map<String, dynamic>);
  }
}
