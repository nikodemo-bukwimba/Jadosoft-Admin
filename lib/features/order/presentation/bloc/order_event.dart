import '../../domain/entities/order_entity.dart';
import '../../domain/usecases/create_order_usecase.dart';

abstract class OrderEvent {}

class OrderLoadAllRequested extends OrderEvent {}

class OrderLoadOneRequested extends OrderEvent {
  final String id;
  OrderLoadOneRequested(this.id);
}

class OrderCreateRequested extends OrderEvent {
  final CreateOrderParams params;
  OrderCreateRequested(this.params);
}

class OrderUpdateRequested extends OrderEvent {
  final OrderEntity entity;
  OrderUpdateRequested(this.entity);
}

class OrderDeleteRequested extends OrderEvent {
  final String id;
  OrderDeleteRequested(this.id);
}

class OrderFormReset extends OrderEvent {}

class OrderSubmitRequested extends OrderEvent {
  final String id;
  OrderSubmitRequested(this.id);
}
class OrderApproveRequested extends OrderEvent {
  final String id;
  OrderApproveRequested(this.id);
}
class OrderRejectRequested extends OrderEvent {
  final String id;
  OrderRejectRequested(this.id);
}
class OrderFulfillRequested extends OrderEvent {
  final String id;
  OrderFulfillRequested(this.id);
}
class OrderReviseRequested extends OrderEvent {
  final String id;
  OrderReviseRequested(this.id);
}
