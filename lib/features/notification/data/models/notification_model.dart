import '../../domain/entities/notification_entity.dart';

class NotificationModel extends NotificationEntity {
  const NotificationModel({
    required super.id,
    required super.recipientId,
    required super.recipientType,
    required super.channel,
    required super.content,
    super.templateId,
    required super.status,
    super.sentAt,
    super.deliveredAt,
    super.failureReason,
    required super.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as String,
      recipientId: json['recipient_id'] as String,
      recipientType: json['recipient_type'] as String,
      channel: json['channel'] as String,
      content: json['content'] as String,
      templateId: json['template_id'] as String?,
      status: json['status'] as String,
      sentAt: json['sent_at'] != null
          ? DateTime.parse(json['sent_at'] as String)
          : null,
      deliveredAt: json['delivered_at'] != null
          ? DateTime.parse(json['delivered_at'] as String)
          : null,
      failureReason: json['failure_reason'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'recipient_id': recipientId,
    'recipient_type': recipientType,
    'channel': channel,
    'content': content,
    'template_id': templateId,
    'status': status,
    'sent_at': sentAt?.toIso8601String(),
    'delivered_at': deliveredAt?.toIso8601String(),
    'failure_reason': failureReason,
    'created_at': createdAt.toIso8601String(),
  };

  factory NotificationModel.fromEntity(NotificationEntity entity) {
    return NotificationModel(
      id: entity.id,
      recipientId: entity.recipientId,
      recipientType: entity.recipientType,
      channel: entity.channel,
      content: entity.content,
      templateId: entity.templateId,
      status: entity.status,
      sentAt: entity.sentAt,
      deliveredAt: entity.deliveredAt,
      failureReason: entity.failureReason,
      createdAt: entity.createdAt,
    );
  }
}