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
      id: json['id'] as String? ?? '',
      recipientId: json['recipient_id'] as String? ?? '',
      recipientType: json['recipient_type'] as String? ?? 'officer',
      channel: json['channel'] as String? ?? 'in_app',
      content: json['content'] as String? ?? '',
      templateId: json['template_id'] as String?,
      status: json['status'] as String? ?? 'queued',
      sentAt: json['sent_at'] != null
          ? DateTime.tryParse(json['sent_at'] as String)
          : null,
      deliveredAt: json['delivered_at'] != null
          ? DateTime.tryParse(json['delivered_at'] as String)
          : null,
      failureReason: json['failure_reason'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String) ?? DateTime.now()
          : DateTime.now(),
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

  static NotificationModel fromEntity(NotificationEntity e) =>
      NotificationModel(
        id: e.id,
        recipientId: e.recipientId,
        recipientType: e.recipientType,
        channel: e.channel,
        content: e.content,
        templateId: e.templateId,
        status: e.status,
        sentAt: e.sentAt,
        deliveredAt: e.deliveredAt,
        failureReason: e.failureReason,
        createdAt: e.createdAt,
      );
}
