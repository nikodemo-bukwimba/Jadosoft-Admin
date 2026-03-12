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
    required super.entitySnapshot,
    required super.ipAddress,
    required super.userAgent,
    required super.occurredAt,
  });

  factory ActivityLogModel.fromJson(Map<String, dynamic> json) {
    return ActivityLogModel(
      id: json['id'] as String,
      actorId: json['actor_id'] as String,
      actorName: json['actor_name'] as String,
      actorRole: json['actor_role'] as String,
      action: json['action'] as String,
      entityType: json['entity_type'] as String,
      entityId: json['entity_id'] as String,
      entitySnapshot: json['entity_snapshot'],
      ipAddress: json['ip_address'] as String?,
      userAgent: json['user_agent'] as String?,
      occurredAt: DateTime.parse(json['occurred_at'] as String),
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
