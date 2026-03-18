import '../../domain/models/initiate_payment_request.dart';
import '../../domain/models/initiate_payment_response.dart';
import '../../domain/models/query_payment_status_response.dart';

abstract class MobileMoneyClient {
  Future<InitiatePaymentResponse> initiatePayment(
      InitiatePaymentRequest request);
  Future<QueryPaymentStatusResponse> queryPaymentStatus(String transactionId);
}