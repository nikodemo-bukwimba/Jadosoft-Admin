import 'package:equatable/equatable.dart';
import '../../domain/models/query_payment_status_response.dart';

class MobileMoneyState extends Equatable {
  final bool isLoading;
  final String? errorMessage;
  final DateTime? lastSyncAt;
  final bool isInitiatePaymentLoading;
  final String? initiatePaymentError;
  final String? lastTransactionId;
  final bool isQueryPaymentStatusLoading;
  final String? queryPaymentStatusError;
  final QueryPaymentStatusResponse? queryPaymentStatusResult;

  const MobileMoneyState({
    this.isLoading = false,
    this.errorMessage,
    this.lastSyncAt,
    this.isInitiatePaymentLoading = false,
    this.initiatePaymentError,
    this.lastTransactionId,
    this.isQueryPaymentStatusLoading = false,
    this.queryPaymentStatusError,
    this.queryPaymentStatusResult,
  });

  MobileMoneyState copyWith({
    bool? isLoading,
    String? errorMessage,
    DateTime? lastSyncAt,
    bool? isInitiatePaymentLoading,
    String? initiatePaymentError,
    String? lastTransactionId,
    bool? isQueryPaymentStatusLoading,
    String? queryPaymentStatusError,
    QueryPaymentStatusResponse? queryPaymentStatusResult,
  }) {
    return MobileMoneyState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
      lastSyncAt: lastSyncAt ?? this.lastSyncAt,
      isInitiatePaymentLoading:
          isInitiatePaymentLoading ?? this.isInitiatePaymentLoading,
      initiatePaymentError: initiatePaymentError ?? this.initiatePaymentError,
      lastTransactionId: lastTransactionId ?? this.lastTransactionId,
      isQueryPaymentStatusLoading:
          isQueryPaymentStatusLoading ?? this.isQueryPaymentStatusLoading,
      queryPaymentStatusError:
          queryPaymentStatusError ?? this.queryPaymentStatusError,
      queryPaymentStatusResult:
          queryPaymentStatusResult ?? this.queryPaymentStatusResult,
    );
  }

  @override
  List<Object?> get props => [
        isLoading,
        errorMessage,
        lastSyncAt,
        isInitiatePaymentLoading,
        initiatePaymentError,
        lastTransactionId,
        isQueryPaymentStatusLoading,
        queryPaymentStatusError,
        queryPaymentStatusResult,
      ];
}