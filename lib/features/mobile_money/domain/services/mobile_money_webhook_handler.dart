import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../models/payment_completed_webhook_payload.dart';
import '../models/payment_failed_webhook_payload.dart';
import '../models/payment_cancelled_webhook_payload.dart';

class MobileMoneyWebhookHandler {
  MobileMoneyWebhookHandler();

  /// Routes incoming webhook to the appropriate handler by event type.
  Future<Either<Failure, void>> handle(Map<String, dynamic> data) async {
    try {
      final event = data['event'] as String?;
      if (event == null) {
        return Left(ValidationFailure('Missing event field in webhook payload'));
      }

      switch (event) {
      case 'payment.completed':
        final payload = PaymentCompletedWebhookPayload.fromJson(data);
        await _handlePaymentCompleted(payload);
        break;
      case 'payment.failed':
        final payload = PaymentFailedWebhookPayload.fromJson(data);
        await _handlePaymentFailed(payload);
        break;
      case 'payment.cancelled':
        final payload = PaymentCancelledWebhookPayload.fromJson(data);
        await _handlePaymentCancelled(payload);
        break;
        default:
          return Left(ValidationFailure('Unknown webhook event: ' + event));
      }

      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  Future<void> _handlePaymentCompleted(PaymentCompletedWebhookPayload payload) async {
    // TODO: implement handler for payment.completed
  }
  Future<void> _handlePaymentFailed(PaymentFailedWebhookPayload payload) async {
    // TODO: implement handler for payment.failed
  }
  Future<void> _handlePaymentCancelled(PaymentCancelledWebhookPayload payload) async {
    // TODO: implement handler for payment.cancelled
  }
}
