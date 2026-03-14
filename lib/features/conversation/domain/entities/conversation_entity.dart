import 'package:equatable/equatable.dart';

enum ConversationType { direct, group }

enum ConversationStatus { open, closed }

enum OnlineStatus { online, away, offline }

class ConversationParticipant extends Equatable {
  final String id;
  final String name;
  final String role;
  final DateTime joinedAt;
  final OnlineStatus onlineStatus;
  final DateTime? lastSeenAt;

  const ConversationParticipant({
    required this.id,
    required this.name,
    required this.role,
    required this.joinedAt,
    this.onlineStatus = OnlineStatus.offline,
    this.lastSeenAt,
  });

  String get lastSeenLabel {
    if (onlineStatus == OnlineStatus.online) return 'Online';
    if (lastSeenAt == null) return 'Offline';
    final diff = DateTime.now().difference(lastSeenAt!);
    if (diff.inMinutes < 5) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  @override
  List<Object?> get props => [
    id,
    name,
    role,
    joinedAt,
    onlineStatus,
    lastSeenAt,
  ];
}

class ConversationEntity extends Equatable {
  final String id;
  final ConversationType type;
  final ConversationStatus status;
  final String? title;
  final List<ConversationParticipant> participants;
  final String? lastMessage;
  final DateTime? lastMessageAt;
  final String? lastMessageSenderName;
  final int unreadCount;
  final String? closedBy;
  final DateTime? closedAt;
  final DateTime createdAt;

  const ConversationEntity({
    required this.id,
    required this.type,
    required this.status,
    this.title,
    required this.participants,
    this.lastMessage,
    this.lastMessageAt,
    this.lastMessageSenderName,
    required this.unreadCount,
    this.closedBy,
    this.closedAt,
    required this.createdAt,
  });

  bool hasParticipant(String userId) => participants.any((p) => p.id == userId);

  String displayName(String currentUserId) {
    if (type == ConversationType.group) return title ?? 'Group Chat';
    final other = participants.where((p) => p.id != currentUserId);
    return other.isNotEmpty ? other.first.name : 'Conversation';
  }

  String subtitle(String currentUserId) {
    if (type == ConversationType.group)
      return participants.map((p) => p.name).join(', ');
    final other = participants.where((p) => p.id != currentUserId);
    if (other.isEmpty) return '';
    return other.first.lastSeenLabel;
  }

  ConversationParticipant? otherParticipant(String currentUserId) {
    if (type == ConversationType.group) return null;
    final other = participants.where((p) => p.id != currentUserId);
    return other.isNotEmpty ? other.first : null;
  }

  int get onlineCount =>
      participants.where((p) => p.onlineStatus == OnlineStatus.online).length;

  ConversationEntity copyWith({
    String? id,
    ConversationType? type,
    ConversationStatus? status,
    String? title,
    List<ConversationParticipant>? participants,
    String? lastMessage,
    DateTime? lastMessageAt,
    String? lastMessageSenderName,
    int? unreadCount,
    String? closedBy,
    DateTime? closedAt,
    DateTime? createdAt,
  }) {
    return ConversationEntity(
      id: id ?? this.id,
      type: type ?? this.type,
      status: status ?? this.status,
      title: title ?? this.title,
      participants: participants ?? this.participants,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      lastMessageSenderName:
          lastMessageSenderName ?? this.lastMessageSenderName,
      unreadCount: unreadCount ?? this.unreadCount,
      closedBy: closedBy ?? this.closedBy,
      closedAt: closedAt ?? this.closedAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    type,
    status,
    title,
    participants,
    lastMessage,
    lastMessageAt,
    lastMessageSenderName,
    unreadCount,
    closedBy,
    closedAt,
    createdAt,
  ];
}
