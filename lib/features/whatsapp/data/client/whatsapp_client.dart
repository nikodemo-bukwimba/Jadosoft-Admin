import '../../domain/models/send_template_request.dart';
import '../../domain/models/send_template_response.dart';
import '../../domain/models/send_media_request.dart';
import '../../domain/models/send_media_response.dart';
import '../../domain/models/get_message_status_response.dart';

abstract class WhatsappClient {
  Future<SendTemplateResponse> sendTemplate(
      String phoneNumberId, SendTemplateRequest request);
  Future<SendMediaResponse> sendMedia(
      String phoneNumberId, SendMediaRequest request);
  Future<GetMessageStatusResponse> getMessageStatus(String messageId);
}