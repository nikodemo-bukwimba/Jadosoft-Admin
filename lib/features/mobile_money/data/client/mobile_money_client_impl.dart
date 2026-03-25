import 'package:dio/dio.dart';
import '../../../../core/context/org_context.dart';
import '../../domain/models/initiate_payment_request.dart';
import '../../domain/models/initiate_payment_response.dart';
import '../../domain/models/query_payment_status_response.dart';
import 'mobile_money_client.dart';

/// Real implementation — calls M-Pesa / Airtel Money via Laravel/Nexora API.
/// Swap in DI when backend is ready:
///   sl.registerLazySingleton<MobileMoneyClient>(
///     () => MobileMoneyClientImpl(dio: sl(), orgContext: sl()));
class MobileMoneyClientImpl implements MobileMoneyClient {
  final Dio _dio;
  final OrgContext _orgContext;

  static const int _maxRetries = 3;
  static const int _backoffMs = 1000;

  MobileMoneyClientImpl({
    required Dio dio,
    required OrgContext orgContext,
  })  : _dio = dio,
        _orgContext = orgContext {
    _dio.options.connectTimeout = const Duration(seconds: 60);
    _dio.options.receiveTimeout = const Duration(seconds: 60);
  }

  String get _base => '/commerce/${_orgContext.effectiveOrgId}/payments';

  Future<Response> _requestWithRetry(
    Future<Response> Function() request, {
    bool isPaymentInitiation = false,
  }) async {
    int attempt = 0;
    while (true) {
      try {
        attempt++;
        return await request();
      } on DioException catch (e) {
        final status = e.response?.statusCode;
        // CRITICAL: Never retry 429 on payment initiation — prevents double charges
        final isRetryable = e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.receiveTimeout ||
            e.type == DioExceptionType.connectionError ||
            (status != null &&
                status >= 500 &&
                !(isPaymentInitiation && status == 429));

        if (!isRetryable || attempt >= _maxRetries) rethrow;

        final delay = _backoffMs * (1 << (attempt - 1));
        await Future.delayed(Duration(milliseconds: delay));
      }
    }
  }

  @override
  Future<InitiatePaymentResponse> initiatePayment(
      InitiatePaymentRequest request) async {
    final response = await _requestWithRetry(
      () => _dio.post('$_base/initiate', data: request.toJson()),
      isPaymentInitiation: true,
    );
    final body = response.data['data'] ?? response.data;
    return InitiatePaymentResponse.fromJson(body as Map<String, dynamic>);
  }

  @override
  Future<QueryPaymentStatusResponse> queryPaymentStatus(
      String transactionId) async {
    final response = await _requestWithRetry(
      () => _dio.get('$_base/$transactionId'),
    );
    final body = response.data['data'] ?? response.data;
    return QueryPaymentStatusResponse.fromJson(body as Map<String, dynamic>);
  }
}