import 'package:dio/dio.dart';
import '../../domain/models/send_template_request.dart';
import '../../domain/models/send_template_response.dart';
import '../../domain/models/send_media_request.dart';
import '../../domain/models/send_media_response.dart';
import '../../domain/models/get_message_status_response.dart';
import 'whatsapp_client.dart';

/// Real implementation — calls WhatsApp Business API via Laravel proxy.
/// Swap in DI when backend is ready:
///   sl.registerLazySingleton<WhatsappClient>(() => WhatsappClientImpl(dio: sl()));
class WhatsappClientImpl implements WhatsappClient {
  final Dio _dio;
  static const int _maxRetries = 3;
  static const int _backoffMs = 1000;

  WhatsappClientImpl({required Dio dio}) : _dio = dio {
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
        final status = e.response?.statusCode;
        final isRetryable = e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.receiveTimeout ||
            e.type == DioExceptionType.connectionError ||
            (status != null && status >= 500);

        if (!isRetryable || attempt >= _maxRetries) rethrow;

        final delay = _backoffMs * (1 << (attempt - 1));
        await Future.delayed(Duration(milliseconds: delay));
      }
    }
  }

  @override
  Future<SendTemplateResponse> sendTemplate(
      String phoneNumberId, SendTemplateRequest request) async {
    final response = await _requestWithRetry(
      () => _dio.post('/api/whatsapp/$phoneNumberId/messages',
          data: request.toJson()),
    );
    return SendTemplateResponse.fromJson(
        response.data as Map<String, dynamic>);
  }

  @override
  Future<SendMediaResponse> sendMedia(
      String phoneNumberId, SendMediaRequest request) async {
    final response = await _requestWithRetry(
      () => _dio.post('/api/whatsapp/$phoneNumberId/media',
          data: request.toJson()),
    );
    return SendMediaResponse.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<GetMessageStatusResponse> getMessageStatus(String messageId) async {
    final response = await _requestWithRetry(
      () => _dio.get('/api/whatsapp/messages/$messageId'),
    );
    return GetMessageStatusResponse.fromJson(
        response.data as Map<String, dynamic>);
  }
}