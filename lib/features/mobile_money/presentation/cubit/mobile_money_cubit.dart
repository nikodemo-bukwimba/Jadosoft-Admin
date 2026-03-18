import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/services/mobile_money_service.dart';
import 'mobile_money_state.dart';
import '../../domain/models/initiate_payment_request.dart';

class MobileMoneyCubit extends Cubit<MobileMoneyState> {
  final MobileMoneyService _service;

  MobileMoneyCubit({required MobileMoneyService service})
    : _service = service,
      super(const MobileMoneyState());

  Future<void> initiatePayment(InitiatePaymentRequest request) async {
    emit(
      state.copyWith(
        isInitiatePaymentLoading: true,
        initiatePaymentError: null,
        lastTransactionId: null,
      ),
    );
    final result = await _service.initiatePayment(request);
    result.fold(
      (failure) => emit(
        state.copyWith(
          isInitiatePaymentLoading: false,
          initiatePaymentError: failure.toString(),
        ),
      ),
      (response) => emit(
        state.copyWith(
          isInitiatePaymentLoading: false,
          lastTransactionId: response.transactionId,
          lastSyncAt: DateTime.now(),
        ),
      ),
    );
  }

  Future<void> queryPaymentStatus(String transactionId) async {
    emit(
      state.copyWith(
        isQueryPaymentStatusLoading: true,
        queryPaymentStatusError: null,
      ),
    );
    final result = await _service.queryPaymentStatus(transactionId);
    result.fold(
      (failure) => emit(
        state.copyWith(
          isQueryPaymentStatusLoading: false,
          queryPaymentStatusError: failure.toString(),
        ),
      ),
      (response) => emit(
        state.copyWith(
          isQueryPaymentStatusLoading: false,
          queryPaymentStatusResult: response,
          lastSyncAt: DateTime.now(),
        ),
      ),
    );
  }
}
