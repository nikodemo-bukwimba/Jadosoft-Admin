import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/services/sms_gateway_service.dart';
import 'sms_gateway_state.dart';
import '../../domain/models/send_sms_request.dart';

class SmsGatewayCubit extends Cubit<SmsGatewayState> {
  final SmsGatewayService _service;

  SmsGatewayCubit({required SmsGatewayService service})
      : _service = service,
        super(const SmsGatewayState());

  Future<void> sendSms(SendSmsRequest request) async {
    emit(state.copyWith(
        isSendSmsLoading: true, sendSmsError: null, lastSentMessageId: null));
    final result = await _service.sendSms(request);
    result.fold(
      (failure) => emit(state.copyWith(
          isSendSmsLoading: false, sendSmsError: failure.toString())),
      (response) => emit(state.copyWith(
        isSendSmsLoading: false,
        lastSentMessageId: response.messageId,
        lastSyncAt: DateTime.now(),
      )),
    );
  }

  Future<void> getDeliveryStatus(String messageId) async {
    emit(state.copyWith(
        isGetDeliveryStatusLoading: true, getDeliveryStatusError: null));
    final result = await _service.getDeliveryStatus(messageId);
    result.fold(
      (failure) => emit(state.copyWith(
          isGetDeliveryStatusLoading: false,
          getDeliveryStatusError: failure.toString())),
      (response) => emit(state.copyWith(
        isGetDeliveryStatusLoading: false,
        getDeliveryStatusResult: response,
        lastSyncAt: DateTime.now(),
      )),
    );
  }
}