import '../../domain/models/send_template_request.dart';
import '../../domain/models/send_template_response.dart';
import '../../domain/models/send_media_request.dart';
import '../../domain/models/send_media_response.dart';
import '../../domain/models/get_message_status_response.dart';
import 'whatsapp_client.dart';

/// Mock implementation — returns realistic fake data.
/// Active in DI during development. No network calls made.
/// To go live: replace with WhatsappClientImpl in injection_container.dart.
class WhatsappMockClient implements WhatsappClient {
  @override
  Future<SendTemplateResponse> sendTemplate(
      String phoneNumberId, SendTemplateRequest request) async {
    await Future.delayed(const Duration(milliseconds: 700));
    return SendTemplateResponse(
      messageId: 'mock-wa-tpl-${DateTime.now().millisecondsSinceEpoch}',
      status: 'sent',
    );
  }

  @override
  Future<SendMediaResponse> sendMedia(
      String phoneNumberId, SendMediaRequest request) async {
    await Future.delayed(const Duration(milliseconds: 800));
    return SendMediaResponse(
      messageId: 'mock-wa-media-${DateTime.now().millisecondsSinceEpoch}',
      status: 'sent',
    );
  }

  @override
  Future<GetMessageStatusResponse> getMessageStatus(String messageId) async {
    await Future.delayed(const Duration(milliseconds: 400));
    return GetMessageStatusResponse(
      messageId: messageId,
      status: 'delivered',
      timestamp: DateTime.now().subtract(const Duration(seconds: 20)),
    );
  }
}