// import 'package:dio/dio.dart';
// import '../../domain/models/send_sms_response.dart';
// import '../../domain/models/send_sms_request.dart';
// import '../../domain/models/get_delivery_status_response.dart';

// class SmsGatewayClient {
//   final Dio _dio;
//   static const int _maxRetries = 3;
//   static const int _backoffMs = 1000;

//   SmsGatewayClient({required Dio dio}) : _dio = dio {
//     _dio.options.baseUrl = '{{SMS_GATEWAY_BASE_URL}}';
//     _dio.options.connectTimeout = const Duration(seconds: 30000);
//     _dio.options.receiveTimeout = const Duration(seconds: 30000);
//   }

//   /// Executes [request] with exponential backoff retry on transient failures.
//   Future<Response> _requestWithRetry(
//     Future<Response> Function() request,
//   ) async {
//     int attempt = 0;
//     while (true) {
//       try {
//         attempt++;
//         return await request();
//       } on DioException catch (e) {
//         final isRetryable = e.type == DioExceptionType.connectionTimeout ||
//             e.type == DioExceptionType.receiveTimeout ||
//             e.type == DioExceptionType.connectionError ||
//             (e.response != null && e.response!.statusCode != null && e.response!.statusCode! >= 500);

//         if (!isRetryable || attempt >= _maxRetries) rethrow;

//         final delay = _backoffMs * (1 << (attempt - 1));
//         await Future.delayed(Duration(milliseconds: delay));
//       }
//     }
//   }

//   Future<SendSmsResponse> sendSms(SendSmsRequest request) async {
//     final response = await _requestWithRetry(
//       () => _dio.post('/messages', data: request.toJson()),
//     );
//     return SendSmsResponse.fromJson(response.data as Map<String, dynamic>);
//   }
//   Future<GetDeliveryStatusResponse> getDeliveryStatus(String messageId) async {
//     final response = await _requestWithRetry(
//       () => _dio.get('/messages/' + messageId),
//     );
//     return GetDeliveryStatusResponse.fromJson(response.data as Map<String, dynamic>);
//   }
// }
import '../../domain/models/send_sms_request.dart';
import '../../domain/models/send_sms_response.dart';
import '../../domain/models/get_delivery_status_response.dart';

abstract class SmsGatewayClient {
  Future<SendSmsResponse> sendSms(SendSmsRequest request);
  Future<GetDeliveryStatusResponse> getDeliveryStatus(String messageId);
}
