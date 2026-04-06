import '../../domain/entities/message_entity.dart';

class MessageModel extends MessageEntity {
  const MessageModel({
    required super.id,
    required super.conversationId,
    required super.senderId,
    required super.senderName,
    required super.senderRole,
    required super.type,
    required super.content,
    super.imageUrl,
    required super.deliveryStatus,
    required super.sentAt,
    super.replyToId,
    super.replyToSenderName,
    super.replyToContent,
    super.reactions,
    super.isPinned,
    super.isStarred,
    super.isEdited,
    super.editedAt,
    super.mentionedUserIds,
    super.readReceipts,
    super.voiceDurationSeconds,
    super.forwardedFromConversationId,
    super.forwardedFromSenderName,
  });

  factory MessageModel.fromJson(Map<String, dynamic> j) {
    final rawReactions = j['reactions'] as List<dynamic>? ?? [];
    final reactions = rawReactions.map((r) {
      final m = r as Map<String, dynamic>;
      return MessageReaction(
        emoji: m['emoji'] as String? ?? '',
        // API uses actor_id not user_id
        userId: m['actor_id'] as String? ?? m['user_id'] as String? ?? '',
        userName: m['user_name'] as String? ?? '',
      );
    }).toList();

    final rawReceipts = j['read_receipts'] as List<dynamic>? ?? [];
    final receipts = rawReceipts.map((r) {
      final m = r as Map<String, dynamic>;
      return ReadReceipt(
        userId: m['actor_id'] as String? ?? m['user_id'] as String? ?? '',
        userName: m['user_name'] as String? ?? '',
        readAt: m['read_at'] != null
            ? DateTime.parse(m['read_at'] as String)
            : DateTime.now(),
      );
    }).toList();

    // API uses sender_actor_id, fallback to sender_id
    final senderId =
        j['sender_actor_id'] as String? ?? j['sender_id'] as String? ?? '';

    // API uses conversation_id for DMs, group_id for groups
    final conversationId =
        j['conversation_id'] as String? ?? j['group_id'] as String? ?? '';

    // API uses created_at (DirectMessage has $timestamps = false),
    // fallback to sent_at for forward compatibility
    DateTime sentAt;
    if (j['sent_at'] != null) {
      sentAt = DateTime.parse(j['sent_at'] as String);
    } else if (j['created_at'] != null) {
      sentAt = DateTime.parse(j['created_at'] as String);
    } else {
      sentAt = DateTime.now();
    }

    // API uses content_type, fallback to type
    final contentType = j['content_type'] as String? ?? j['type'] as String?;

    // API uses status field for delivery, fallback to delivery_status
    final deliveryStr =
        j['status'] as String? ?? j['delivery_status'] as String?;

    // sender_name may not be in the API response — use actor_id as fallback
    final senderName =
        j['sender_name'] as String? ?? j['sender_actor_id'] as String? ?? '';

    return MessageModel(
      id: j['id'] as String? ?? '',
      conversationId: conversationId,
      senderId: senderId,
      senderName: senderName,
      senderRole: j['sender_role'] as String? ?? 'unknown',
      type: _parseType(contentType),
      content: j['content'] as String? ?? '',
      imageUrl: j['image_url'] as String?,
      deliveryStatus: _parseDelivery(deliveryStr),
      sentAt: sentAt,
      replyToId: j['reply_to_id'] as String?,
      replyToSenderName: j['reply_to_sender_name'] as String?,
      replyToContent: j['reply_to_content'] as String?,
      reactions: reactions,
      isPinned: j['is_pinned'] as bool? ?? false,
      isStarred: j['is_starred'] as bool? ?? false,
      isEdited: j['is_edited'] as bool? ?? false,
      editedAt: j['edited_at'] != null
          ? DateTime.parse(j['edited_at'] as String)
          : null,
      mentionedUserIds:
          (j['mentioned_user_ids'] as List<dynamic>?)?.cast<String>() ?? [],
      readReceipts: receipts,
      voiceDurationSeconds: (j['voice_duration_seconds'] as num?)?.toInt(),
      forwardedFromConversationId:
          j['forwarded_from_conversation_id'] as String?,
      forwardedFromSenderName: j['forwarded_from_sender_name'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'conversation_id': conversationId,
    'sender_id': senderId,
    'sender_name': senderName,
    'sender_role': senderRole,
    'type': type.name,
    'content': content,
    'image_url': imageUrl,
    'delivery_status': deliveryStatus.name,
    'sent_at': sentAt.toIso8601String(),
    'reply_to_id': replyToId,
    'reply_to_sender_name': replyToSenderName,
    'reply_to_content': replyToContent,
    'reactions': reactions
        .map(
          (r) => {
            'emoji': r.emoji,
            'actor_id': r.userId,
            'user_name': r.userName,
          },
        )
        .toList(),
    'is_pinned': isPinned,
    'is_starred': isStarred,
    'is_edited': isEdited,
    'edited_at': editedAt?.toIso8601String(),
    'mentioned_user_ids': mentionedUserIds,
    'read_receipts': readReceipts
        .map(
          (r) => {
            'actor_id': r.userId,
            'user_name': r.userName,
            'read_at': r.readAt.toIso8601String(),
          },
        )
        .toList(),
    'voice_duration_seconds': voiceDurationSeconds,
    'forwarded_from_conversation_id': forwardedFromConversationId,
    'forwarded_from_sender_name': forwardedFromSenderName,
  };

  static MessageType _parseType(String? v) => switch (v) {
    'image' => MessageType.image,
    'system' => MessageType.system,
    'audio' || 'voice' => MessageType.voice,
    _ => MessageType.text,
  };

  static DeliveryStatus _parseDelivery(String? v) => switch (v) {
    'sending' => DeliveryStatus.sending,
    'sent' => DeliveryStatus.sent,
    'delivered' => DeliveryStatus.delivered,
    'read' => DeliveryStatus.read,
    _ => DeliveryStatus.sent,
  };
}
