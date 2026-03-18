import 'package:dio/dio.dart';
import '../../domain/models/send_sms_request.dart';
import '../../domain/models/send_sms_response.dart';
import '../../domain/models/get_delivery_status_response.dart';
import 'sms_gateway_client.dart';

/// Real implementation — calls the Laravel SMS Gateway API.
/// Swap in DI when backend is ready:
///   sl.registerLazySingleton<SmsGatewayClient>(() => SmsGatewayClientImpl(dio: sl()));
class SmsGatewayClientImpl implements SmsGatewayClient {
  final Dio _dio;
  static const int _maxRetries = 3;
  static const int _backoffMs = 1000;

  SmsGatewayClientImpl({required Dio dio}) : _dio = dio {
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
  Future<SendSmsResponse> sendSms(SendSmsRequest request) async {
    final response = await _requestWithRetry(
      () => _dio.post('/api/sms/send', data: request.toJson()),
    );
    return SendSmsResponse.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<GetDeliveryStatusResponse> getDeliveryStatus(String messageId) async {
    final response = await _requestWithRetry(
      () => _dio.get('/api/sms/status/$messageId'),
    );
    return GetDeliveryStatusResponse.fromJson(
        response.data as Map<String, dynamic>);
  }
}