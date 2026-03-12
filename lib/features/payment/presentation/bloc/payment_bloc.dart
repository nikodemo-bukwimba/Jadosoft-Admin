import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/usecase/usecase.dart';
import '../../domain/usecases/create_payment_usecase.dart';
import '../../domain/usecases/delete_payment_usecase.dart';
import '../../domain/usecases/get_payment_usecase.dart';
import '../../domain/usecases/get_all_payment_usecase.dart';
import '../../domain/usecases/update_payment_usecase.dart';
import 'payment_event.dart';
import 'payment_state.dart';

class PaymentBloc extends Bloc<PaymentEvent, PaymentState> {
  final GetAllPaymentUseCase  getAllUseCase;
  final GetPaymentUseCase     getUseCase;
  final CreatePaymentUseCase  createUseCase;
  final UpdatePaymentUseCase  updateUseCase;
  final DeletePaymentUseCase  deleteUseCase;

  PaymentBloc({
    required this.getAllUseCase,
    required this.getUseCase,
    required this.createUseCase,
    required this.updateUseCase,
    required this.deleteUseCase,
  }) : super(PaymentInitial()) {
    on<PaymentLoadAllRequested>(_onLoadAll);
    on<PaymentLoadOneRequested>(_onLoadOne);
    on<PaymentCreateRequested>(_onCreate);
    on<PaymentUpdateRequested>(_onUpdate);
    on<PaymentDeleteRequested>(_onDelete);
    on<PaymentFormReset>((_, emit) => emit(PaymentInitial()));
  }

  Future<void> _onLoadAll(
      PaymentLoadAllRequested event, Emitter<PaymentState> emit) async {
    emit(PaymentLoading());
    final result = await getAllUseCase(NoParams());
    result.fold(
      (f) => emit(PaymentFailure(f.message)),
      (items) => items.isEmpty
          ? emit(PaymentEmpty())
          : emit(PaymentListLoaded(items)),
    );
  }

  Future<void> _onLoadOne(
      PaymentLoadOneRequested event, Emitter<PaymentState> emit) async {
    emit(PaymentLoading());
    final result = await getUseCase(GetPaymentParams(id: event.id));
    result.fold(
      (f) => emit(PaymentFailure(f.message)),
      (item) => emit(PaymentDetailLoaded(item)),
    );
  }

  Future<void> _onCreate(
      PaymentCreateRequested event, Emitter<PaymentState> emit) async {
    emit(PaymentLoading());
    final result = await createUseCase(event.params);
    result.fold(
      (f) => emit(PaymentFailure(f.message)),
      (_) => emit(PaymentOperationSuccess('Payment created successfully')),
    );
  }

  Future<void> _onUpdate(
      PaymentUpdateRequested event, Emitter<PaymentState> emit) async {
    emit(PaymentLoading());
    final result = await updateUseCase(UpdatePaymentParams(entity: event.entity));
    result.fold(
      (f) => emit(PaymentFailure(f.message)),
      (_) => emit(PaymentOperationSuccess('Payment updated successfully')),
    );
  }

  Future<void> _onDelete(
      PaymentDeleteRequested event, Emitter<PaymentState> emit) async {
    emit(PaymentLoading());
    final result = await deleteUseCase(DeletePaymentParams(id: event.id));
    result.fold(
      (f) => emit(PaymentFailure(f.message)),
      (_) => emit(PaymentOperationSuccess('Payment deleted successfully')),
    );
  }
}
