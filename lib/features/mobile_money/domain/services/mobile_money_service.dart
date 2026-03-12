import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import '../../../../core/error/failures.dart';
import '../../data/client/mobile_money_client.dart';
import '../models/initiate_payment_response.dart';
import '../models/initiate_payment_request.dart';
import '../models/query_payment_status_response.dart';

class MobileMoneyService {
  final MobileMoneyClient _client;

  MobileMoneyService({required MobileMoneyClient client}) : _client = client;

  Future<Either<Failure, InitiatePaymentResponse>> initiatePayment(InitiatePaymentRequest request) async {
    try {
      final result = await _client.initiatePayment(request);
      return Right(result);
    } on DioException catch (e) {
      return Left(ServerFailure(e.response?.data?.toString() ?? e.message ?? 'Unknown error'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
  Future<Either<Failure, QueryPaymentStatusResponse>> queryPaymentStatus(String transactionId) async {
    try {
      final result = await _client.queryPaymentStatus(transactionId);
      return Right(result);
    } on DioException catch (e) {
      return Left(ServerFailure(e.response?.data?.toString() ?? e.message ?? 'Unknown error'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
