import 'package:equatable/equatable.dart';
import '../../domain/models/get_message_status_response.dart';

class WhatsappState extends Equatable {
  final bool isLoading;
  final String? errorMessage;
  final DateTime? lastSyncAt;
  final bool isSendTemplateLoading;
  final String? sendTemplateError;
  final bool isSendMediaLoading;
  final String? sendMediaError;
  final bool isGetMessageStatusLoading;
  final String? getMessageStatusError;
  final GetMessageStatusResponse? getMessageStatusResult;

  const WhatsappState({
    this.isLoading = false,
    this.errorMessage,
    this.lastSyncAt,
    this.isSendTemplateLoading = false,
    this.sendTemplateError,
    this.isSendMediaLoading = false,
    this.sendMediaError,
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
    bool? isSendMediaLoading,
    String? sendMediaError,
    bool? isGetMessageStatusLoading,
    String? getMessageStatusError,
    GetMessageStatusResponse? getMessageStatusResult,
  }) {
    return WhatsappState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
      lastSyncAt: lastSyncAt ?? this.lastSyncAt,
      isSendTemplateLoading: isSendTemplateLoading ?? this.isSendTemplateLoading,
      sendTemplateError: sendTemplateError ?? this.sendTemplateError,
      isSendMediaLoading: isSendMediaLoading ?? this.isSendMediaLoading,
      sendMediaError: sendMediaError ?? this.sendMediaError,
      isGetMessageStatusLoading: isGetMessageStatusLoading ?? this.isGetMessageStatusLoading,
      getMessageStatusError: getMessageStatusError ?? this.getMessageStatusError,
      getMessageStatusResult: getMessageStatusResult ?? this.getMessageStatusResult,
    );
  }

  @override
  List<Object?> get props => [isLoading, errorMessage, lastSyncAt, isSendTemplateLoading, sendTemplateError, isSendMediaLoading, sendMediaError, isGetMessageStatusLoading, getMessageStatusError, getMessageStatusResult];
}
