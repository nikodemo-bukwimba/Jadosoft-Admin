import '../../domain/entities/order_entity.dart';
import '../../domain/usecases/create_order_usecase.dart';
import '../../domain/usecases/mark_order_paid_usecase.dart';

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

class OrderConfirmRequested extends OrderEvent {
  final String id;
  OrderConfirmRequested(this.id);
}

class OrderShipRequested extends OrderEvent {
  final String id;
  OrderShipRequested(this.id);
}

class OrderDeliverRequested extends OrderEvent {
  final String id;
  OrderDeliverRequested(this.id);
}

class OrderCancelRequested extends OrderEvent {
  final String id;
  OrderCancelRequested(this.id);
}

class OrderMarkPaidRequested extends OrderEvent {
  final MarkOrderPaidParams params;
  OrderMarkPaidRequested(this.params);
}
