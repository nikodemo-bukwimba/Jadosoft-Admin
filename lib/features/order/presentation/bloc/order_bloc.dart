import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/usecase/usecase.dart';
import '../../domain/services/order_domain_service.dart';
import '../../domain/usecases/create_order_usecase.dart';
import '../../domain/usecases/delete_order_usecase.dart';
import '../../domain/usecases/get_order_usecase.dart';
import '../../domain/usecases/get_all_order_usecase.dart';
import '../../domain/usecases/update_order_usecase.dart';
import '../../domain/value_objects/order_status.dart';
import 'order_event.dart';
import 'order_state.dart';

class OrderBloc extends Bloc<OrderEvent, OrderState> {
  final GetAllOrderUseCase  getAllUseCase;
  final GetOrderUseCase     getUseCase;
  final CreateOrderUseCase  createUseCase;
  final UpdateOrderUseCase  updateUseCase;
  final DeleteOrderUseCase  deleteUseCase;
  final OrderDomainService  domainService;

  OrderBloc({
    required this.getAllUseCase,
    required this.getUseCase,
    required this.createUseCase,
    required this.updateUseCase,
    required this.deleteUseCase,
    required this.domainService,
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
  }

  Future<void> _onLoadAll(
      OrderLoadAllRequested event, Emitter<OrderState> emit) async {
    emit(OrderLoading());
    final result = await getAllUseCase(NoParams());
    result.fold(
      (f) => emit(OrderFailure(f.message)),
      (items) => items.isEmpty
          ? emit(OrderEmpty())
          : emit(OrderListLoaded(items)),
    );
  }

  Future<void> _onLoadOne(
      OrderLoadOneRequested event, Emitter<OrderState> emit) async {
    emit(OrderLoading());
    final result = await getUseCase(GetOrderParams(id: event.id));
    result.fold(
      (f) => emit(OrderFailure(f.message)),
      (item) => emit(OrderDetailLoaded(item)),
    );
  }

  Future<void> _onCreate(
      OrderCreateRequested event, Emitter<OrderState> emit) async {
    emit(OrderLoading());
    final result = await createUseCase(event.params);
    result.fold(
      (f) => emit(OrderFailure(f.message)),
      (_) => emit(OrderOperationSuccess('Order created successfully')),
    );
  }

  Future<void> _onUpdate(
      OrderUpdateRequested event, Emitter<OrderState> emit) async {
    emit(OrderLoading());
    final result = await updateUseCase(UpdateOrderParams(entity: event.entity));
    result.fold(
      (f) => emit(OrderFailure(f.message)),
      (_) => emit(OrderOperationSuccess('Order updated successfully')),
    );
  }

  Future<void> _onDelete(
      OrderDeleteRequested event, Emitter<OrderState> emit) async {
    emit(OrderLoading());
    final result = await deleteUseCase(DeleteOrderParams(id: event.id));
    result.fold(
      (f) => emit(OrderFailure(f.message)),
      (_) => emit(OrderOperationSuccess('Order deleted successfully')),
    );
  }

  Future<void> _onConfirm(
      OrderConfirmRequested event, Emitter<OrderState> emit) async {
    emit(OrderLoading());
    final result = await domainService.transition(
      id: event.id,
      targetStatus: OrderStatus.confirmed,
    );
    result.fold(
      (f) => emit(OrderFailure(f.message)),
      (entity) => emit(OrderOperationSuccess(
        'Confirm Order successful',
        updatedItem: entity,
      )),
    );
  }
  Future<void> _onShip(
      OrderShipRequested event, Emitter<OrderState> emit) async {
    emit(OrderLoading());
    final result = await domainService.transition(
      id: event.id,
      targetStatus: OrderStatus.shipped,
    );
    result.fold(
      (f) => emit(OrderFailure(f.message)),
      (entity) => emit(OrderOperationSuccess(
        'Ship Order successful',
        updatedItem: entity,
      )),
    );
  }
  Future<void> _onDeliver(
      OrderDeliverRequested event, Emitter<OrderState> emit) async {
    emit(OrderLoading());
    final result = await domainService.transition(
      id: event.id,
      targetStatus: OrderStatus.delivered,
    );
    result.fold(
      (f) => emit(OrderFailure(f.message)),
      (entity) => emit(OrderOperationSuccess(
        'Mark Delivered successful',
        updatedItem: entity,
      )),
    );
  }
  Future<void> _onCancel(
      OrderCancelRequested event, Emitter<OrderState> emit) async {
    emit(OrderLoading());
    final result = await domainService.transition(
      id: event.id,
      targetStatus: OrderStatus.cancelled,
    );
    result.fold(
      (f) => emit(OrderFailure(f.message)),
      (entity) => emit(OrderOperationSuccess(
        'Cancel Order successful',
        updatedItem: entity,
      )),
    );
  }
}
