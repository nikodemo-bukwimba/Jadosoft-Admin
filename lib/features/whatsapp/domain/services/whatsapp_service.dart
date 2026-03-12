import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import '../../../../core/error/failures.dart';
import '../../data/client/whatsapp_client.dart';
import '../models/send_template_response.dart';
import '../models/send_template_request.dart';
import '../models/send_media_response.dart';
import '../models/send_media_request.dart';
import '../models/get_message_status_response.dart';

class WhatsappService {
  final WhatsappClient _client;

  WhatsappService({required WhatsappClient client}) : _client = client;

  Future<Either<Failure, SendTemplateResponse>> sendTemplate(
      String phoneNumberId, SendTemplateRequest request) async {
    try {
      final result = await _client.sendTemplate(phoneNumberId, request);
      return Right(result);
    } on DioException catch (e) {
      return Left(ServerFailure(e.response?.data?.toString() ?? e.message ?? 'Unknown error'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  Future<Either<Failure, SendMediaResponse>> sendMedia(
      String phoneNumberId, SendMediaRequest request) async {
    try {
      final result = await _client.sendMedia(phoneNumberId, request);
      return Right(result);
    } on DioException catch (e) {
      return Left(ServerFailure(e.response?.data?.toString() ?? e.message ?? 'Unknown error'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  Future<Either<Failure, GetMessageStatusResponse>> getMessageStatus(
      String messageId) async {
    try {
      final result = await _client.getMessageStatus(messageId);
      return Right(result);
    } on DioException catch (e) {
      return Left(ServerFailure(e.response?.data?.toString() ?? e.message ?? 'Unknown error'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}