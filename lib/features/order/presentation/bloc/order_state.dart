import '../../domain/entities/order_entity.dart';

abstract class OrderState {}

class OrderInitial extends OrderState {}
class OrderLoading extends OrderState {}

class OrderListLoaded extends OrderState {
  final List<OrderEntity> items;
  OrderListLoaded(this.items);
}

class OrderDetailLoaded extends OrderState {
  final OrderEntity item;
  OrderDetailLoaded(this.item);
}

class OrderOperationSuccess extends OrderState {
  final String message;
  final OrderEntity? updatedItem;
  OrderOperationSuccess(this.message, {this.updatedItem});
}

class OrderEmpty extends OrderState {}

class OrderFailure extends OrderState {
  final String message;
  OrderFailure(this.message);
}
