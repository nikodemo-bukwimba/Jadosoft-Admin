import 'package:equatable/equatable.dart';
import '../../domain/models/get_delivery_status_response.dart';

class SmsGatewayState extends Equatable {
  final bool isLoading;
  final String? errorMessage;
  final DateTime? lastSyncAt;
  final bool isSendSmsLoading;
  final String? sendSmsError;
  final String? lastSentMessageId;
  final bool isGetDeliveryStatusLoading;
  final String? getDeliveryStatusError;
  final GetDeliveryStatusResponse? getDeliveryStatusResult;

  const SmsGatewayState({
    this.isLoading = false,
    this.errorMessage,
    this.lastSyncAt,
    this.isSendSmsLoading = false,
    this.sendSmsError,
    this.lastSentMessageId,
    this.isGetDeliveryStatusLoading = false,
    this.getDeliveryStatusError,
    this.getDeliveryStatusResult,
  });

  SmsGatewayState copyWith({
    bool? isLoading,
    String? errorMessage,
    DateTime? lastSyncAt,
    bool? isSendSmsLoading,
    String? sendSmsError,
    String? lastSentMessageId,
    bool? isGetDeliveryStatusLoading,
    String? getDeliveryStatusError,
    GetDeliveryStatusResponse? getDeliveryStatusResult,
  }) {
    return SmsGatewayState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
      lastSyncAt: lastSyncAt ?? this.lastSyncAt,
      isSendSmsLoading: isSendSmsLoading ?? this.isSendSmsLoading,
      sendSmsError: sendSmsError ?? this.sendSmsError,
      lastSentMessageId: lastSentMessageId ?? this.lastSentMessageId,
      isGetDeliveryStatusLoading:
          isGetDeliveryStatusLoading ?? this.isGetDeliveryStatusLoading,
      getDeliveryStatusError:
          getDeliveryStatusError ?? this.getDeliveryStatusError,
      getDeliveryStatusResult:
          getDeliveryStatusResult ?? this.getDeliveryStatusResult,
    );
  }

  @override
  List<Object?> get props => [
        isLoading,
        errorMessage,
        lastSyncAt,
        isSendSmsLoading,
        sendSmsError,
        lastSentMessageId,
        isGetDeliveryStatusLoading,
        getDeliveryStatusError,
        getDeliveryStatusResult,
      ];
}