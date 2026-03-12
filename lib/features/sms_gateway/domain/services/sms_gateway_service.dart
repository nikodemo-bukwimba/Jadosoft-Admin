import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import '../../../../core/error/failures.dart';
import '../../data/client/sms_gateway_client.dart';
import '../models/send_sms_response.dart';
import '../models/send_sms_request.dart';
import '../models/get_delivery_status_response.dart';

class SmsGatewayService {
  final SmsGatewayClient _client;

  SmsGatewayService({required SmsGatewayClient client}) : _client = client;

  Future<Either<Failure, SendSmsResponse>> sendSms(SendSmsRequest request) async {
    try {
      final result = await _client.sendSms(request);
      return Right(result);
    } on DioException catch (e) {
      return Left(ServerFailure(e.response?.data?.toString() ?? e.message ?? 'Unknown error'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
  Future<Either<Failure, GetDeliveryStatusResponse>> getDeliveryStatus(String messageId) async {
    try {
      final result = await _client.getDeliveryStatus(messageId);
      return Right(result);
    } on DioException catch (e) {
      return Left(ServerFailure(e.response?.data?.toString() ?? e.message ?? 'Unknown error'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
