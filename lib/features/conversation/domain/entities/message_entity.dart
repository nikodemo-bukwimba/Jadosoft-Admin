import 'package:equatable/equatable.dart';

enum MessageType { text, image, document, system, voice }

enum DeliveryStatus { sending, sent, delivered, read }

class MessageReaction extends Equatable {
  final String emoji;
  final String userId;
  final String userName;
  const MessageReaction({
    required this.emoji,
    required this.userId,
    required this.userName,
  });
  @override
  List<Object?> get props => [emoji, userId, userName];
}

class ReadReceipt extends Equatable {
  final String userId;
  final String userName;
  final DateTime readAt;
  const ReadReceipt({
    required this.userId,
    required this.userName,
    required this.readAt,
  });
  @override
  List<Object?> get props => [userId, userName, readAt];
}

class MessageEntity extends Equatable {
  final String id;
  final String conversationId;
  final String senderId;
  final String senderName;
  final String senderRole;
  final MessageType type;
  final String content;
  final String? imageUrl;
  final String? attachmentUrl;
  final String? attachmentName;
  final String? attachmentMime;
  final DeliveryStatus deliveryStatus;
  final DateTime sentAt;

  // Reply
  final String? replyToId;
  final String? replyToSenderName;
  final String? replyToContent;

  // Reactions
  final List<MessageReaction> reactions;

  // Pins & Stars
  final bool isPinned;
  final bool isStarred;

  // Edit
  final bool isEdited;
  final DateTime? editedAt;

  // Mentions
  final List<String> mentionedUserIds; // empty = none, ['all'] = @all

  // Read receipts (group)
  final List<ReadReceipt> readReceipts;

  // Voice note
  final int? voiceDurationSeconds;

  // Forward
  final String? forwardedFromConversationId;
  final String? forwardedFromSenderName;

  const MessageEntity({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.senderName,
    required this.senderRole,
    required this.type,
    required this.content,
    this.imageUrl,
    this.attachmentUrl,
    this.attachmentName,
    this.attachmentMime,
    required this.deliveryStatus,
    required this.sentAt,
    this.replyToId,
    this.replyToSenderName,
    this.replyToContent,
    this.reactions = const [],
    this.isPinned = false,
    this.isStarred = false,
    this.isEdited = false,
    this.editedAt,
    this.mentionedUserIds = const [],
    this.readReceipts = const [],
    this.voiceDurationSeconds,
    this.forwardedFromConversationId,
    this.forwardedFromSenderName,
  });

  bool get isSystem => type == MessageType.system;
  bool get isImage => type == MessageType.image;
  bool get isVoice => type == MessageType.voice;
  bool get isReply => replyToId != null;
  bool get isForwarded => forwardedFromConversationId != null;
  bool get hasMentions => mentionedUserIds.isNotEmpty;
  bool get mentionsAll => mentionedUserIds.contains('all');
  bool get isDocument => type == MessageType.document;

  MessageEntity copyWith({
    String? id,
    String? conversationId,
    String? senderId,
    String? senderName,
    String? senderRole,
    MessageType? type,
    String? content,
    String? imageUrl,
    String? attachmentUrl,
    String? attachmentName,
    String? attachmentMime,
    DeliveryStatus? deliveryStatus,
    DateTime? sentAt,
    String? replyToId,
    String? replyToSenderName,
    String? replyToContent,
    List<MessageReaction>? reactions,
    bool? isPinned,
    bool? isStarred,
    bool? isEdited,
    DateTime? editedAt,
    List<String>? mentionedUserIds,
    List<ReadReceipt>? readReceipts,
    int? voiceDurationSeconds,
    String? forwardedFromConversationId,
    String? forwardedFromSenderName,
  }) {
    return MessageEntity(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      senderRole: senderRole ?? this.senderRole,
      type: type ?? this.type,
      content: content ?? this.content,
      imageUrl: imageUrl ?? this.imageUrl,
      attachmentUrl: attachmentUrl ?? this.attachmentUrl,
      attachmentName: attachmentName ?? this.attachmentName,
      attachmentMime: attachmentMime ?? this.attachmentMime,
      deliveryStatus: deliveryStatus ?? this.deliveryStatus,
      sentAt: sentAt ?? this.sentAt,
      replyToId: replyToId ?? this.replyToId,
      replyToSenderName: replyToSenderName ?? this.replyToSenderName,
      replyToContent: replyToContent ?? this.replyToContent,
      reactions: reactions ?? this.reactions,
      isPinned: isPinned ?? this.isPinned,
      isStarred: isStarred ?? this.isStarred,
      isEdited: isEdited ?? this.isEdited,
      editedAt: editedAt ?? this.editedAt,
      mentionedUserIds: mentionedUserIds ?? this.mentionedUserIds,
      readReceipts: readReceipts ?? this.readReceipts,
      voiceDurationSeconds: voiceDurationSeconds ?? this.voiceDurationSeconds,
      forwardedFromConversationId:
          forwardedFromConversationId ?? this.forwardedFromConversationId,
      forwardedFromSenderName:
          forwardedFromSenderName ?? this.forwardedFromSenderName,
    );
  }

  @override
  List<Object?> get props => [
    id,
    conversationId,
    senderId,
    senderName,
    senderRole,
    type,
    content,
    imageUrl,
    attachmentUrl,
    attachmentName,
    attachmentMime,
    deliveryStatus,
    sentAt,
    replyToId,
    replyToSenderName,
    replyToContent,
    reactions,
    isPinned,
    isStarred,
    isEdited,
    editedAt,
    mentionedUserIds,
    readReceipts,
    voiceDurationSeconds,
    forwardedFromConversationId,
    forwardedFromSenderName,
  ];
}
