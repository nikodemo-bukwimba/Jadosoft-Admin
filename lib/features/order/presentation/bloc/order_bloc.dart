// order_bloc.dart — Admin App
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/create_order_usecase.dart';
import '../../domain/usecases/delete_order_usecase.dart';
import '../../domain/usecases/get_order_usecase.dart';
import '../../domain/usecases/mark_order_paid_usecase.dart';
import '../../domain/usecases/update_order_usecase.dart';
import '../../domain/services/order_domain_service.dart';
import '../../domain/usecases/get_all_order_usecase.dart';
import 'order_event.dart';
import 'order_state.dart';

class OrderBloc extends Bloc<OrderEvent, OrderState> {
  final GetAllOrderUseCase getAllUseCase;
  final GetOrderUseCase getUseCase;
  final CreateOrderUseCase createUseCase;
  final UpdateOrderUseCase updateUseCase;
  final DeleteOrderUseCase deleteUseCase;
  final OrderDomainService domainService;
  final MarkOrderPaidUseCase markPaidUseCase;

  OrderBloc({
    required this.getAllUseCase,
    required this.getUseCase,
    required this.createUseCase,
    required this.updateUseCase,
    required this.deleteUseCase,
    required this.domainService,
    required this.markPaidUseCase,
  }) : super(OrderInitial()) {
    on<OrderLoadAllRequested>(_onLoadAll);
    on<OrderLoadOneRequested>(_onLoadOne);
    on<OrderCreateRequested>(_onCreate);
    on<OrderUpdateRequested>(_onUpdate);
    on<OrderDeleteRequested>(_onDelete);
    on<OrderFormReset>((_, emit) => emit(OrderInitial()));
    on<OrderConfirmRequested>(_onConfirm);
    on<OrderShipRequested>(_onShip);
    on<OrderDeliverRequested>(_onDeliver);
    on<OrderCancelRequested>(_onCancel);
    on<OrderMarkPaidRequested>(_onMarkPaid);
  }

  Future<void> _onLoadAll(
    OrderLoadAllRequested event,
    Emitter<OrderState> emit,
  ) async {
    emit(OrderLoading());
    final result = await getAllUseCase(
      GetAllOrderParams(createdById: event.createdById),
    );
    result.fold(
      (f) => emit(OrderFailure(f.message)),
      (items) =>
          items.isEmpty ? emit(OrderEmpty()) : emit(OrderListLoaded(items)),
    );
  }

  Future<void> _onLoadOne(
    OrderLoadOneRequested event,
    Emitter<OrderState> emit,
  ) async {
    emit(OrderLoading());
    final result = await getUseCase(GetOrderParams(id: event.id));
    result.fold(
      (f) => emit(OrderFailure(f.message)),
      (item) => emit(OrderDetailLoaded(item)),
    );
  }

  Future<void> _onCreate(
    OrderCreateRequested event,
    Emitter<OrderState> emit,
  ) async {
    emit(OrderLoading());
    final result = await createUseCase(event.params);
    result.fold(
      (f) => emit(OrderFailure(f.message)),
      (_) => emit(OrderOperationSuccess('Order created successfully')),
    );
  }

  Future<void> _onUpdate(
    OrderUpdateRequested event,
    Emitter<OrderState> emit,
  ) async {
    emit(OrderLoading());
    final result = await updateUseCase(UpdateOrderParams(entity: event.entity));
    result.fold(
      (f) => emit(OrderFailure(f.message)),
      (_) => emit(OrderOperationSuccess('Order updated successfully')),
    );
  }

  Future<void> _onDelete(
    OrderDeleteRequested event,
    Emitter<OrderState> emit,
  ) async {
    emit(OrderLoading());
    final result = await deleteUseCase(DeleteOrderParams(id: event.id));
    result.fold(
      (f) => emit(OrderFailure(f.message)),
      (_) => emit(OrderOperationSuccess('Order deleted')),
    );
  }

  Future<void> _onConfirm(
    OrderConfirmRequested event,
    Emitter<OrderState> emit,
  ) async {
    emit(OrderLoading());
    final result = await domainService.confirmOrder(event.id);
    result.fold(
      (f) => emit(OrderFailure(f.message)),
      (order) =>
          emit(OrderOperationSuccess('Order confirmed', updatedItem: order)),
    );
  }

  Future<void> _onShip(
    OrderShipRequested event,
    Emitter<OrderState> emit,
  ) async {
    emit(OrderLoading());
    final result = await domainService.shipOrder(event.id);
    result.fold(
      (f) => emit(OrderFailure(f.message)),
      (order) =>
          emit(OrderOperationSuccess('Order shipped', updatedItem: order)),
    );
  }

  Future<void> _onDeliver(
    OrderDeliverRequested event,
    Emitter<OrderState> emit,
  ) async {
    emit(OrderLoading());
    final result = await domainService.deliverOrder(event.id);
    result.fold(
      (f) => emit(OrderFailure(f.message)),
      (order) =>
          emit(OrderOperationSuccess('Order delivered', updatedItem: order)),
    );
  }

  Future<void> _onCancel(
    OrderCancelRequested event,
    Emitter<OrderState> emit,
  ) async {
    emit(OrderLoading());
    final result = await domainService.cancelOrder(event.id);
    result.fold(
      (f) => emit(OrderFailure(f.message)),
      (order) =>
          emit(OrderOperationSuccess('Order cancelled', updatedItem: order)),
    );
  }

  Future<void> _onMarkPaid(
    OrderMarkPaidRequested event,
    Emitter<OrderState> emit,
  ) async {
    emit(OrderLoading());
    final result = await markPaidUseCase(event.params);
    result.fold(
      (f) => emit(OrderFailure(f.message)),
      (order) =>
          emit(OrderOperationSuccess('Payment recorded', updatedItem: order)),
    );
  }
}
