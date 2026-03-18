import '../../domain/models/send_sms_request.dart';
import '../../domain/models/send_sms_response.dart';
import '../../domain/models/get_delivery_status_response.dart';
import 'sms_gateway_client.dart';

/// Mock implementation — returns realistic fake data.
/// Active in DI during development. No network calls made.
/// To go live: replace with SmsGatewayClientImpl in injection_container.dart.
class SmsGatewayMockClient implements SmsGatewayClient {
  @override
  Future<SendSmsResponse> sendSms(SendSmsRequest request) async {
    await Future.delayed(const Duration(milliseconds: 600));
    return SendSmsResponse(
      messageId: 'mock-sms-${DateTime.now().millisecondsSinceEpoch}',
      status: 'sent',
      to: request.to,
      sentAt: DateTime.now(),
    );
  }

  @override
  Future<GetDeliveryStatusResponse> getDeliveryStatus(String messageId) async {
    await Future.delayed(const Duration(milliseconds: 400));
    return GetDeliveryStatusResponse(
      messageId: messageId,
      status: 'delivered',
      deliveredAt: DateTime.now().subtract(const Duration(seconds: 30)),
      errorCode: null,
      errorMessage: null,
    );
  }
}