import '../entities/order_entity.dart';

/// Base class for all Order domain events.
abstract class OrderDomainEvent {
  final String entityId;
  final Map<String, dynamic>? payload;
  final DateTime occurredAt;

  OrderDomainEvent({
    required this.entityId,
    this.payload,
    DateTime? occurredAt,
  }) : occurredAt = occurredAt ?? DateTime.now();

  String get name;

  Map<String, dynamic> toMap() => {
    'event':      name,
    'entityId':   entityId,
    'occurredAt': occurredAt.toIso8601String(),
    if (payload != null) 'payload': payload,
  };
}

class OrderCreatedEvent extends OrderDomainEvent {
  OrderCreatedEvent({required super.entityId, super.payload, super.occurredAt});

  @override
  String get name => 'order.created';
}

class OrderUpdatedEvent extends OrderDomainEvent {
  OrderUpdatedEvent({required super.entityId, super.payload, super.occurredAt});

  @override
  String get name => 'order.updated';
}

class OrderStatusChangedEvent extends OrderDomainEvent {
  final String fromStatus;
  final String toStatus;

  OrderStatusChangedEvent({
    required super.entityId,
    required this.fromStatus,
    required this.toStatus,
    super.payload,
    super.occurredAt,
  });

  @override
  String get name => 'order.status_changed';

  @override
  Map<String, dynamic> toMap() => {
    ...super.toMap(),
    'fromStatus': fromStatus,
    'toStatus':   toStatus,
  };
}

class OrderDeletedEvent extends OrderDomainEvent {
  OrderDeletedEvent({required super.entityId, super.payload, super.occurredAt});

  @override
  String get name => 'order.deleted';
}

class OrderValidateinventoryEvent extends OrderDomainEvent {
  OrderValidateinventoryEvent({
    required super.entityId,
    super.payload,
    super.occurredAt,
  });

  @override
  String get name => 'validateInventory';
}

class OrderProcesspaymentEvent extends OrderDomainEvent {
  OrderProcesspaymentEvent({
    required super.entityId,
    super.payload,
    super.occurredAt,
  });

  @override
  String get name => 'processPayment';
}

class OrderSendconfirmationEvent extends OrderDomainEvent {
  OrderSendconfirmationEvent({
    required super.entityId,
    super.payload,
    super.occurredAt,
  });

  @override
  String get name => 'sendConfirmation';
}
