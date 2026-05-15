import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/usecase/usecase.dart';
import '../../domain/usecases/create_customer_usecase.dart';
import '../../domain/usecases/delete_customer_usecase.dart';
import '../../domain/usecases/get_customer_usecase.dart';
import '../../domain/usecases/get_all_customer_usecase.dart';
import '../../domain/usecases/update_customer_usecase.dart';
import 'customer_event.dart';
import 'customer_state.dart';

class CustomerBloc extends Bloc<CustomerEvent, CustomerState> {
  final GetAllCustomerUseCase getAllUseCase;
  final GetCustomerUseCase getUseCase;
  final CreateCustomerUseCase createUseCase;
  final UpdateCustomerUseCase updateUseCase;
  final DeleteCustomerUseCase deleteUseCase;

  CustomerBloc({
    required this.getAllUseCase,
    required this.getUseCase,
    required this.createUseCase,
    required this.updateUseCase,
    required this.deleteUseCase,
  }) : super(CustomerInitial()) {
    on<CustomerLoadAllRequested>(_onLoadAll);
    on<CustomerLoadOneRequested>(_onLoadOne);
    on<CustomerCreateRequested>(_onCreate);
    on<CustomerUpdateRequested>(_onUpdate);
    on<CustomerDeleteRequested>(_onDelete);
    on<CustomerFormReset>((_, emit) => emit(CustomerInitial()));
  }

  Future<void> _onLoadAll(
    CustomerLoadAllRequested event,
    Emitter<CustomerState> emit,
  ) async {
    emit(CustomerLoading());
    final result = await getAllUseCase(NoParams());
    result.fold(
      (f) => emit(CustomerFailure(f.message)),
      (paginated) => paginated.items.isEmpty
          ? emit(CustomerEmpty())
          : emit(CustomerListLoaded(paginated.items)),
    );
  }

  Future<void> _onLoadOne(
    CustomerLoadOneRequested event,
    Emitter<CustomerState> emit,
  ) async {
    emit(CustomerLoading());
    final result = await getUseCase(GetCustomerParams(id: event.id));
    result.fold(
      (f) => emit(CustomerFailure(f.message)),
      (item) => emit(CustomerDetailLoaded(item)),
    );
  }

  Future<void> _onCreate(
    CustomerCreateRequested event,
    Emitter<CustomerState> emit,
  ) async {
    emit(CustomerLoading());
    final result = await createUseCase(event.params);
    result.fold(
      (f) => emit(CustomerFailure(f.message)),
      (_) => emit(CustomerOperationSuccess('Customer created')),
    );
  }

  Future<void> _onUpdate(
    CustomerUpdateRequested event,
    Emitter<CustomerState> emit,
  ) async {
    emit(CustomerLoading());
    final result = await updateUseCase(
      UpdateCustomerParams(
        entity: event.entity,
        contactName: event.contactName,
        contactPhone: event.contactPhone,
        contactRole: event.contactRole,
      ),
    );
    result.fold(
      (f) => emit(CustomerFailure(f.message)),
      (_) => emit(CustomerOperationSuccess('Customer updated')),
    );
  }

  Future<void> _onDelete(
    CustomerDeleteRequested event,
    Emitter<CustomerState> emit,
  ) async {
    emit(CustomerLoading());
    final result = await deleteUseCase(DeleteCustomerParams(id: event.id));
    result.fold(
      (f) => emit(CustomerFailure(f.message)),
      (_) => emit(CustomerOperationSuccess('Customer deleted')),
    );
  }
}
