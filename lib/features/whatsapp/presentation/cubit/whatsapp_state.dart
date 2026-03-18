import 'package:equatable/equatable.dart';
import '../../domain/models/get_message_status_response.dart';

class WhatsappState extends Equatable {
  final bool isLoading;
  final String? errorMessage;
  final DateTime? lastSyncAt;
  final bool isSendTemplateLoading;
  final String? sendTemplateError;
  final String? lastSentMessageId;
  final bool isSendMediaLoading;
  final String? sendMediaError;
  final String? lastSentMediaId;
  final bool isGetMessageStatusLoading;
  final String? getMessageStatusError;
  final GetMessageStatusResponse? getMessageStatusResult;

  const WhatsappState({
    this.isLoading = false,
    this.errorMessage,
    this.lastSyncAt,
    this.isSendTemplateLoading = false,
    this.sendTemplateError,
    this.lastSentMessageId,
    this.isSendMediaLoading = false,
    this.sendMediaError,
    this.lastSentMediaId,
    this.isGetMessageStatusLoading = false,
    this.getMessageStatusError,
    this.getMessageStatusResult,
  });

  WhatsappState copyWith({
    bool? isLoading,
    String? errorMessage,
    DateTime? lastSyncAt,
    bool? isSendTemplateLoading,
    String? sendTemplateError,
    String? lastSentMessageId,
    bool? isSendMediaLoading,
    String? sendMediaError,
    String? lastSentMediaId,
    bool? isGetMessageStatusLoading,
    String? getMessageStatusError,
    GetMessageStatusResponse? getMessageStatusResult,
  }) {
    return WhatsappState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
      lastSyncAt: lastSyncAt ?? this.lastSyncAt,
      isSendTemplateLoading:
          isSendTemplateLoading ?? this.isSendTemplateLoading,
      sendTemplateError: sendTemplateError ?? this.sendTemplateError,
      lastSentMessageId: lastSentMessageId ?? this.lastSentMessageId,
      isSendMediaLoading: isSendMediaLoading ?? this.isSendMediaLoading,
      sendMediaError: sendMediaError ?? this.sendMediaError,
      lastSentMediaId: lastSentMediaId ?? this.lastSentMediaId,
      isGetMessageStatusLoading:
          isGetMessageStatusLoading ?? this.isGetMessageStatusLoading,
      getMessageStatusError:
          getMessageStatusError ?? this.getMessageStatusError,
      getMessageStatusResult:
          getMessageStatusResult ?? this.getMessageStatusResult,
    );
  }

  @override
  List<Object?> get props => [
        isLoading,
        errorMessage,
        lastSyncAt,
        isSendTemplateLoading,
        sendTemplateError,
        lastSentMessageId,
        isSendMediaLoading,
        sendMediaError,
        lastSentMediaId,
        isGetMessageStatusLoading,
        getMessageStatusError,
        getMessageStatusResult,
      ];
}