import 'package:equatable/equatable.dart';

class ConversationEntity extends Equatable {
  final String id;
  final List<String> participantIds;
  final List<String> participantRoles;
  final String? lastMessage;
  final DateTime? lastMessageAt;
  final int unreadCount;
  final DateTime createdAt;

  const ConversationEntity({
    required this.id,
    required this.participantIds,
    required this.participantRoles,
    this.lastMessage,
    this.lastMessageAt,
    required this.unreadCount,
    required this.createdAt,
  });

  ConversationEntity copyWith({
    String? id,
    List<String>? participantIds,
    List<String>? participantRoles,
    String? lastMessage,
    DateTime? lastMessageAt,
    int? unreadCount,
    DateTime? createdAt,
  }) {
    return ConversationEntity(
      id: id ?? this.id,
      participantIds: participantIds ?? this.participantIds,
      participantRoles: participantRoles ?? this.participantRoles,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      unreadCount: unreadCount ?? this.unreadCount,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [];
}
