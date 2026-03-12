import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/services/whatsapp_service.dart';
import 'whatsapp_state.dart';
import '../../domain/models/send_template_request.dart';
import '../../domain/models/send_media_request.dart';

class WhatsappCubit extends Cubit<WhatsappState> {
  final WhatsappService _service;

  WhatsappCubit({required WhatsappService service})
      : _service = service,
        super(const WhatsappState());

  Future<void> sendTemplate(String phoneNumberId, SendTemplateRequest request) async {
    emit(state.copyWith(isSendTemplateLoading: true, sendTemplateError: null));
    final result = await _service.sendTemplate(phoneNumberId, request);
    result.fold(
      (failure) => emit(state.copyWith(isSendTemplateLoading: false, sendTemplateError: failure.toString())),
      (result) {
        emit(state.copyWith(isSendTemplateLoading: false, lastSyncAt: DateTime.now()));
      },
    );
  }
  Future<void> sendMedia(String phoneNumberId, SendMediaRequest request) async {
    emit(state.copyWith(isSendMediaLoading: true, sendMediaError: null));
    final result = await _service.sendMedia(phoneNumberId, request);
    result.fold(
      (failure) => emit(state.copyWith(isSendMediaLoading: false, sendMediaError: failure.toString())),
      (result) {
        emit(state.copyWith(isSendMediaLoading: false, lastSyncAt: DateTime.now()));
      },
    );
  }
  Future<void> getMessageStatus(String messageId) async {
    emit(state.copyWith(isGetMessageStatusLoading: true, getMessageStatusError: null));
    final result = await _service.getMessageStatus(messageId);
    result.fold(
      (failure) => emit(state.copyWith(isGetMessageStatusLoading: false, getMessageStatusError: failure.toString())),
      (result) {
        emit(state.copyWith(isGetMessageStatusLoading: false, getMessageStatusResult: result, lastSyncAt: DateTime.now()));
      },
    );
  }
}
