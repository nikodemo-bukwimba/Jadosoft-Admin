import 'package:equatable/equatable.dart';
import '../value_objects/notification_status.dart';

class NotificationEntity extends Equatable {
  final String id;
  final String recipientId;
  final String recipientType;
  final String channel;
  final String content;
  final String? templateId;
  final String status;
  final DateTime? sentAt;
  final DateTime? deliveredAt;
  final String? failureReason;
  final DateTime createdAt;

  const NotificationEntity({
    required this.id,
    required this.recipientId,
    required this.recipientType,
    required this.channel,
    required this.content,
    this.templateId,
    required this.status,
    this.sentAt,
    this.deliveredAt,
    this.failureReason,
    required this.createdAt,
  });

  NotificationEntity copyWith({
    String? id,
    String? recipientId,
    String? recipientType,
    String? channel,
    String? content,
    String? templateId,
    String? status,
    DateTime? sentAt,
    DateTime? deliveredAt,
    String? failureReason,
    DateTime? createdAt,
  }) {
    return NotificationEntity(
      id: id ?? this.id,
      recipientId: recipientId ?? this.recipientId,
      recipientType: recipientType ?? this.recipientType,
      channel: channel ?? this.channel,
      content: content ?? this.content,
      templateId: templateId ?? this.templateId,
      status: status ?? this.status,
      sentAt: sentAt ?? this.sentAt,
      deliveredAt: deliveredAt ?? this.deliveredAt,
      failureReason: failureReason ?? this.failureReason,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [id, recipientId, recipientType, channel, content, templateId, status, sentAt, deliveredAt, failureReason, createdAt];
}
