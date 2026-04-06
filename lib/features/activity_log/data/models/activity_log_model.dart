import '../../domain/entities/activity_log_entity.dart';

class ActivityLogModel extends ActivityLogEntity {
  const ActivityLogModel({
    required super.id,
    required super.actorId,
    required super.actorName,
    required super.actorRole,
    required super.action,
    required super.entityType,
    required super.entityId,
    super.entitySnapshot,
    super.ipAddress,
    super.userAgent,
    required super.occurredAt,
  });

  factory ActivityLogModel.fromJson(Map<String, dynamic> json) {
    return ActivityLogModel(
      id: (json['id'] ?? '').toString(),
      actorId: (json['actor_id'] ?? '').toString(),
      actorName: (json['actor_name'] ?? '').toString(),
      actorRole: (json['actor_role'] ?? '').toString(),
      action: (json['action'] ?? '').toString(),
      entityType: (json['entity_type'] ?? '').toString(),
      entityId: (json['entity_id'] ?? '').toString(),
      entitySnapshot: json['entity_snapshot'] as Map<String, dynamic>?,
      ipAddress: json['ip_address'] as String?,
      userAgent: json['user_agent'] as String?,
      occurredAt: json['occurred_at'] != null
          ? DateTime.tryParse(json['occurred_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'actor_id': actorId,
    'actor_name': actorName,
    'actor_role': actorRole,
    'action': action,
    'entity_type': entityType,
    'entity_id': entityId,
    'entity_snapshot': entitySnapshot,
    'ip_address': ipAddress,
    'user_agent': userAgent,
    'occurred_at': occurredAt.toIso8601String(),
  };

  factory ActivityLogModel.fromEntity(ActivityLogEntity entity) {
    return ActivityLogModel(
      id: entity.id,
      actorId: entity.actorId,
      actorName: entity.actorName,
      actorRole: entity.actorRole,
      action: entity.action,
      entityType: entity.entityType,
      entityId: entity.entityId,
      entitySnapshot: entity.entitySnapshot,
      ipAddress: entity.ipAddress,
      userAgent: entity.userAgent,
      occurredAt: entity.occurredAt,
    );
  }
}
