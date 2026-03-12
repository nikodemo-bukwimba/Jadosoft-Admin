import 'package:dio/dio.dart';
import '../../domain/models/initiate_payment_response.dart';
import '../../domain/models/initiate_payment_request.dart';
import '../../domain/models/query_payment_status_response.dart';

class MobileMoneyClient {
  final Dio _dio;
  static const int _maxRetries = 3;
  static const int _backoffMs = 1000;

  MobileMoneyClient({required Dio dio}) : _dio = dio {
    _dio.options.baseUrl = '{{MOBILE_MONEY_BASE_URL}}';
    _dio.options.connectTimeout = const Duration(seconds: 60000);
    _dio.options.receiveTimeout = const Duration(seconds: 60000);
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

  Future<InitiatePaymentResponse> initiatePayment(InitiatePaymentRequest request) async {
    final response = await _requestWithRetry(
      () => _dio.post('/payments', data: request.toJson()),
    );
    return InitiatePaymentResponse.fromJson(response.data as Map<String, dynamic>);
  }
  Future<QueryPaymentStatusResponse> queryPaymentStatus(String transactionId) async {
    final response = await _requestWithRetry(
      () => _dio.get('/payments/' + transactionId),
    );
    return QueryPaymentStatusResponse.fromJson(response.data as Map<String, dynamic>);
  }
}
