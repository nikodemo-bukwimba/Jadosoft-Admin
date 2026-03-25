import 'package:dio/dio.dart';
import '../../../../core/context/org_context.dart';
import '../../domain/models/send_sms_request.dart';
import '../../domain/models/send_sms_response.dart';
import '../../domain/models/get_delivery_status_response.dart';
import 'sms_gateway_client.dart';

/// Real implementation — calls Laravel SMS Gateway (wraps Vodacom/Airtel/Africa's Talking).
/// Swap in DI when backend is ready:
///   sl.registerLazySingleton<SmsGatewayClient>(
///     () => SmsGatewayClientImpl(dio: sl(), orgContext: sl()));
class SmsGatewayClientImpl implements SmsGatewayClient {
  final Dio _dio;
  final OrgContext _orgContext;

  static const int _maxRetries = 3;
  static const int _backoffMs = 1000;

  SmsGatewayClientImpl({
    required Dio dio,
    required OrgContext orgContext,
  })  : _dio = dio,
        _orgContext = orgContext {
    _dio.options.connectTimeout = const Duration(seconds: 30);
    _dio.options.receiveTimeout = const Duration(seconds: 30);
  }

  String get _base => '/communications/${_orgContext.effectiveOrgId}/sms';

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
      () => _dio.post('$_base/send', data: request.toJson()),
    );
    final body = response.data['data'] ?? response.data;
    return SendSmsResponse.fromJson(body as Map<String, dynamic>);
  }

  @override
  Future<GetDeliveryStatusResponse> getDeliveryStatus(String messageId) async {
    final response = await _requestWithRetry(
      () => _dio.get('$_base/status/$messageId'),
    );
    final body = response.data['data'] ?? response.data;
    return GetDeliveryStatusResponse.fromJson(body as Map<String, dynamic>);
  }
}