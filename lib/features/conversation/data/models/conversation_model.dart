import '../../domain/entities/conversation_entity.dart';

class ConversationModel extends ConversationEntity {
  const ConversationModel({
    required super.id,
    required super.participantIds,
    required super.participantRoles,
    required super.lastMessage,
    required super.lastMessageAt,
    required super.unreadCount,
    required super.createdAt,
  });

  factory ConversationModel.fromJson(Map<String, dynamic> json) {
    return ConversationModel(
      id: json['id'] as String,
      participantIds: json['participant_ids'],
      participantRoles: json['participant_roles'],
      lastMessage: json['last_message'] as String?,
      lastMessageAt: json['last_message_at'] != null ? DateTime.parse(json['last_message_at'] as String) : null,
      unreadCount: json['unread_count'] as int,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
      'id': id,
      'participant_ids': participantIds,
      'participant_roles': participantRoles,
      'last_message': lastMessage,
      'last_message_at': lastMessageAt?.toIso8601String(),
      'unread_count': unreadCount,
      'created_at': createdAt.toIso8601String(),
  };

  factory ConversationModel.fromEntity(ConversationEntity entity) {
    return ConversationModel(
      id: entity.id,
      participantIds: entity.participantIds,
      participantRoles: entity.participantRoles,
      lastMessage: entity.lastMessage,
      lastMessageAt: entity.lastMessageAt,
      unreadCount: entity.unreadCount,
      createdAt: entity.createdAt,
    );
  }
}
