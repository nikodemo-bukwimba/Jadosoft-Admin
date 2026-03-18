import '../../domain/models/initiate_payment_request.dart';
import '../../domain/models/initiate_payment_response.dart';
import '../../domain/models/query_payment_status_response.dart';
import 'mobile_money_client.dart';

/// Mock implementation — returns realistic fake data.
/// Active in DI during development. No network calls made.
/// To go live: replace with MobileMoneyClientImpl in injection_container.dart.
class MobileMoneyMockClient implements MobileMoneyClient {
  @override
  Future<InitiatePaymentResponse> initiatePayment(
      InitiatePaymentRequest request) async {
    await Future.delayed(const Duration(milliseconds: 900));
    return InitiatePaymentResponse(
      transactionId: 'mock-txn-${DateTime.now().millisecondsSinceEpoch}',
      status: 'pending',
      provider: request.provider,
      initiatedAt: DateTime.now(),
    );
  }

  @override
  Future<QueryPaymentStatusResponse> queryPaymentStatus(
      String transactionId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return QueryPaymentStatusResponse(
      transactionId: transactionId,
      status: 'completed',
      amount: 25000.0,
      currency: 'TZS',
      provider: 'M-Pesa',
      completedAt: DateTime.now().subtract(const Duration(seconds: 45)),
      failureReason: null,
    );
  }
}