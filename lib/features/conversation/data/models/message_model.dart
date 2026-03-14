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
        emoji: m['emoji'] ?? '',
        userId: m['user_id'] ?? '',
        userName: m['user_name'] ?? '',
      );
    }).toList();

    final rawReceipts = j['read_receipts'] as List<dynamic>? ?? [];
    final receipts = rawReceipts.map((r) {
      final m = r as Map<String, dynamic>;
      return ReadReceipt(
        userId: m['user_id'] ?? '',
        userName: m['user_name'] ?? '',
        readAt: m['read_at'] != null
            ? DateTime.parse(m['read_at'])
            : DateTime.now(),
      );
    }).toList();

    return MessageModel(
      id: j['id'] as String? ?? '',
      conversationId: j['conversation_id'] as String? ?? '',
      senderId: j['sender_id'] as String? ?? '',
      senderName: j['sender_name'] as String? ?? '',
      senderRole: j['sender_role'] as String? ?? 'unknown',
      type: _parseType(j['type'] as String?),
      content: j['content'] as String? ?? '',
      imageUrl: j['image_url'] as String?,
      deliveryStatus: _parseDelivery(j['delivery_status'] as String?),
      sentAt: j['sent_at'] != null
          ? DateTime.parse(j['sent_at'] as String)
          : DateTime.now(),
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
            'user_id': r.userId,
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
            'user_id': r.userId,
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
    'voice' => MessageType.voice,
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
