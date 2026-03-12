import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../models/message_sent_webhook_payload.dart';
import '../models/message_delivered_webhook_payload.dart';
import '../models/message_read_webhook_payload.dart';
import '../models/message_failed_webhook_payload.dart';

class WhatsappWebhookHandler {
  WhatsappWebhookHandler();

  /// Routes incoming webhook to the appropriate handler by event type.
  Future<Either<Failure, void>> handle(Map<String, dynamic> data) async {
    try {
      final event = data['event'] as String?;
      if (event == null) {
        return Left(ValidationFailure('Missing event field in webhook payload'));
      }

      switch (event) {
      case 'messages.sent':
        final payload = MessageSentWebhookPayload.fromJson(data);
        await _handleMessageSent(payload);
        break;
      case 'messages.delivered':
        final payload = MessageDeliveredWebhookPayload.fromJson(data);
        await _handleMessageDelivered(payload);
        break;
      case 'messages.read':
        final payload = MessageReadWebhookPayload.fromJson(data);
        await _handleMessageRead(payload);
        break;
      case 'messages.failed':
        final payload = MessageFailedWebhookPayload.fromJson(data);
        await _handleMessageFailed(payload);
        break;
        default:
          return Left(ValidationFailure('Unknown webhook event: ' + event));
      }

      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  Future<void> _handleMessageSent(MessageSentWebhookPayload payload) async {
    // TODO: implement handler for messages.sent
  }
  Future<void> _handleMessageDelivered(MessageDeliveredWebhookPayload payload) async {
    // TODO: implement handler for messages.delivered
  }
  Future<void> _handleMessageRead(MessageReadWebhookPayload payload) async {
    // TODO: implement handler for messages.read
  }
  Future<void> _handleMessageFailed(MessageFailedWebhookPayload payload) async {
    // TODO: implement handler for messages.failed
  }
}
