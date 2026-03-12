import '../entities/promotion_entity.dart';

/// Base class for all Promotion domain events.
abstract class PromotionDomainEvent {
  final String entityId;
  final Map<String, dynamic>? payload;
  final DateTime occurredAt;

  PromotionDomainEvent({
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

class PromotionCreatedEvent extends PromotionDomainEvent {
  PromotionCreatedEvent({required super.entityId, super.payload, super.occurredAt});

  @override
  String get name => 'promotion.created';
}

class PromotionUpdatedEvent extends PromotionDomainEvent {
  PromotionUpdatedEvent({required super.entityId, super.payload, super.occurredAt});

  @override
  String get name => 'promotion.updated';
}

class PromotionStatusChangedEvent extends PromotionDomainEvent {
  final String fromStatus;
  final String toStatus;

  PromotionStatusChangedEvent({
    required super.entityId,
    required this.fromStatus,
    required this.toStatus,
    super.payload,
    super.occurredAt,
  });

  @override
  String get name => 'promotion.status_changed';

  @override
  Map<String, dynamic> toMap() => {
    ...super.toMap(),
    'fromStatus': fromStatus,
    'toStatus':   toStatus,
  };
}

class PromotionDeletedEvent extends PromotionDomainEvent {
  PromotionDeletedEvent({required super.entityId, super.payload, super.occurredAt});

  @override
  String get name => 'promotion.deleted';
}

class PromotionBroadcastsmsEvent extends PromotionDomainEvent {
  PromotionBroadcastsmsEvent({
    required super.entityId,
    super.payload,
    super.occurredAt,
  });

  @override
  String get name => 'broadcastSms';
}

class PromotionBroadcastwhatsappEvent extends PromotionDomainEvent {
  PromotionBroadcastwhatsappEvent({
    required super.entityId,
    super.payload,
    super.occurredAt,
  });

  @override
  String get name => 'broadcastWhatsApp';
}
