import '../../domain/entities/conversation_entity.dart';

class ConversationModel extends ConversationEntity {
  const ConversationModel({
    required super.id,
    required super.type,
    required super.status,
    super.title,
    required super.participants,
    super.lastMessage,
    super.lastMessageAt,
    super.lastMessageSenderName,
    required super.unreadCount,
    super.closedBy,
    super.closedAt,
    required super.createdAt,
  });

  factory ConversationModel.fromJson(Map<String, dynamic> j) {
    final rawP = j['participants'] as List<dynamic>? ?? [];
    final participants = rawP.map((p) {
      final m = p as Map<String, dynamic>;
      return ConversationParticipant(
        id: m['id'] as String? ?? '',
        name: m['name'] as String? ?? '',
        role: m['role'] as String? ?? 'unknown',
        joinedAt: m['joined_at'] != null
            ? DateTime.parse(m['joined_at'] as String)
            : DateTime.now(),
        onlineStatus: _parseOnline(m['online_status'] as String?),
        lastSeenAt: m['last_seen_at'] != null
            ? DateTime.parse(m['last_seen_at'] as String)
            : null,
      );
    }).toList();

    return ConversationModel(
      id: j['id'] as String? ?? '',
      type: (j['type'] as String? ?? 'direct') == 'group'
          ? ConversationType.group
          : ConversationType.direct,
      status: (j['status'] as String? ?? 'open') == 'closed'
          ? ConversationStatus.closed
          : ConversationStatus.open,
      title: j['title'] as String?,
      participants: participants,
      lastMessage: j['last_message'] as String?,
      lastMessageAt: j['last_message_at'] != null
          ? DateTime.parse(j['last_message_at'] as String)
          : null,
      lastMessageSenderName: j['last_message_sender_name'] as String?,
      unreadCount: (j['unread_count'] as num?)?.toInt() ?? 0,
      closedBy: j['closed_by'] as String?,
      closedAt: j['closed_at'] != null
          ? DateTime.parse(j['closed_at'] as String)
          : null,
      createdAt: j['created_at'] != null
          ? DateTime.parse(j['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type == ConversationType.group ? 'group' : 'direct',
    'status': status == ConversationStatus.closed ? 'closed' : 'open',
    'title': title,
    'participants': participants
        .map(
          (p) => {
            'id': p.id,
            'name': p.name,
            'role': p.role,
            'joined_at': p.joinedAt.toIso8601String(),
            'online_status': p.onlineStatus.name,
            'last_seen_at': p.lastSeenAt?.toIso8601String(),
          },
        )
        .toList(),
    'last_message': lastMessage,
    'last_message_at': lastMessageAt?.toIso8601String(),
    'last_message_sender_name': lastMessageSenderName,
    'unread_count': unreadCount,
    'closed_by': closedBy,
    'closed_at': closedAt?.toIso8601String(),
    'created_at': createdAt.toIso8601String(),
  };

  factory ConversationModel.fromEntity(ConversationEntity e) =>
      ConversationModel(
        id: e.id,
        type: e.type,
        status: e.status,
        title: e.title,
        participants: e.participants,
        lastMessage: e.lastMessage,
        lastMessageAt: e.lastMessageAt,
        lastMessageSenderName: e.lastMessageSenderName,
        unreadCount: e.unreadCount,
        closedBy: e.closedBy,
        closedAt: e.closedAt,
        createdAt: e.createdAt,
      );

  static OnlineStatus _parseOnline(String? v) => switch (v) {
    'online' => OnlineStatus.online,
    'away' => OnlineStatus.away,
    _ => OnlineStatus.offline,
  };
}
