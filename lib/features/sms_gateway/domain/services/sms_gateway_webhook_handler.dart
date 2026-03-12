import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../models/message_delivered_webhook_payload.dart';
import '../models/message_failed_webhook_payload.dart';

class SmsGatewayWebhookHandler {
  SmsGatewayWebhookHandler();

  /// Routes incoming webhook to the appropriate handler by event type.
  Future<Either<Failure, void>> handle(Map<String, dynamic> data) async {
    try {
      final event = data['event'] as String?;
      if (event == null) {
        return Left(ValidationFailure('Missing event field in webhook payload'));
      }

      switch (event) {
      case 'message.delivered':
        final payload = MessageDeliveredWebhookPayload.fromJson(data);
        await _handleMessageDelivered(payload);
        break;
      case 'message.failed':
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

  Future<void> _handleMessageDelivered(MessageDeliveredWebhookPayload payload) async {
    // TODO: implement handler for message.delivered
  }
  Future<void> _handleMessageFailed(MessageFailedWebhookPayload payload) async {
    // TODO: implement handler for message.failed
  }
}
