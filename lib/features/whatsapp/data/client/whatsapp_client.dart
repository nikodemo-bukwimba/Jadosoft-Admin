import 'package:dio/dio.dart';
import '../../domain/models/send_template_response.dart';
import '../../domain/models/send_template_request.dart';
import '../../domain/models/send_media_response.dart';
import '../../domain/models/send_media_request.dart';
import '../../domain/models/get_message_status_response.dart';

class WhatsappClient {
  final Dio _dio;
  static const int _maxRetries = 3;
  static const int _backoffMs = 1000;

  WhatsappClient({required Dio dio}) : _dio = dio {
    _dio.options.baseUrl = 'https://graph.facebook.com/v18.0';
    _dio.options.connectTimeout = const Duration(seconds: 30);
    _dio.options.receiveTimeout = const Duration(seconds: 30);
  }

  Future<Response> _requestWithRetry(
    Future<Response> Function() request,
  ) async {
    int attempt = 0;
    while (true) {
      try {
        attempt++;
        return await request();
      } on DioException catch (e) {
        final isRetryable =
            e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.receiveTimeout ||
            e.type == DioExceptionType.connectionError ||
            (e.response != null &&
                e.response!.statusCode != null &&
                e.response!.statusCode! >= 500);

        if (!isRetryable || attempt >= _maxRetries) rethrow;

        final delay = _backoffMs * (1 << (attempt - 1));
        await Future.delayed(Duration(milliseconds: delay));
      }
    }
  }

  Future<SendTemplateResponse> sendTemplate(
    String phoneNumberId,
    SendTemplateRequest request,
  ) async {
    final response = await _requestWithRetry(
      () => _dio.post('/$phoneNumberId/messages', data: request.toJson()),
    );
    return SendTemplateResponse.fromJson(response.data as Map<String, dynamic>);
  }

  Future<SendMediaResponse> sendMedia(
    String phoneNumberId,
    SendMediaRequest request,
  ) async {
    final response = await _requestWithRetry(
      () => _dio.post('/$phoneNumberId/messages', data: request.toJson()),
    );
    return SendMediaResponse.fromJson(response.data as Map<String, dynamic>);
  }

  Future<GetMessageStatusResponse> getMessageStatus(String messageId) async {
    final response = await _requestWithRetry(() => _dio.get('/$messageId'));
    return GetMessageStatusResponse.fromJson(
      response.data as Map<String, dynamic>,
    );
  }
}
