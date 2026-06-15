import '../../domain/entities/conversation_entity.dart';
import '../../domain/usecases/create_conversation_usecase.dart';

abstract class ConversationEvent {}

// ─── List ───
class ConversationLoadAllRequested extends ConversationEvent {}

class ConversationLoadOneRequested extends ConversationEvent {
  final String id;
  ConversationLoadOneRequested(this.id);
}

class ConversationCreateRequested extends ConversationEvent {
  final CreateConversationParams params;
  ConversationCreateRequested(this.params);
}

class ConversationUpdateRequested extends ConversationEvent {
  final ConversationEntity entity;
  ConversationUpdateRequested(this.entity);
}

class ConversationDeleteRequested extends ConversationEvent {
  final String id;
  ConversationDeleteRequested(this.id);
}

class ConversationFormReset extends ConversationEvent {}

// ─── Chat ───
class ConversationLoadMessagesRequested extends ConversationEvent {
  final String conversationId;
  ConversationLoadMessagesRequested(this.conversationId);
}

class ConversationSendMessageRequested extends ConversationEvent {
  final String conversationId;
  final String content;
  final String? imageUrl;
  final String? attachmentId; // ← ADD
  final String? attachmentType;
  final String? replyToId;
  final String? replyToSenderName;
  final String? replyToContent;
  final List<String>? mentionedUserIds;
  final String? forwardedFromConvId;
  final String? forwardedFromSenderName;
  final int? voiceDurationSeconds;
  ConversationSendMessageRequested({
    required this.conversationId,
    required this.content,
    this.imageUrl,
    this.attachmentId,
    this.attachmentType,
    this.replyToId,
    this.replyToSenderName,
    this.replyToContent,
    this.mentionedUserIds,
    this.forwardedFromConvId,
    this.forwardedFromSenderName,
    this.voiceDurationSeconds,
  });
}

class ConversationAutoReplyReceived extends ConversationEvent {
  final String conversationId;
  ConversationAutoReplyReceived(this.conversationId);
}

class ConversationTypingStarted extends ConversationEvent {
  final String conversationId;
  final String senderName;
  ConversationTypingStarted(this.conversationId, this.senderName);
}

class ConversationTypingStopped extends ConversationEvent {
  final String conversationId;
  ConversationTypingStopped(this.conversationId);
}

// ─── Message operations ───
class ConversationDeleteMessageRequested extends ConversationEvent {
  final String conversationId;
  final String messageId;
  ConversationDeleteMessageRequested({
    required this.conversationId,
    required this.messageId,
  });
}

class ConversationTogglePinRequested extends ConversationEvent {
  final String conversationId;
  final String messageId;
  ConversationTogglePinRequested({
    required this.conversationId,
    required this.messageId,
  });
}

class ConversationToggleStarRequested extends ConversationEvent {
  final String conversationId;
  final String messageId;
  ConversationToggleStarRequested({
    required this.conversationId,
    required this.messageId,
  });
}

class ConversationAddReactionRequested extends ConversationEvent {
  final String conversationId;
  final String messageId;
  final String emoji;
  ConversationAddReactionRequested({
    required this.conversationId,
    required this.messageId,
    required this.emoji,
  });
}

class ConversationEditMessageRequested extends ConversationEvent {
  final String conversationId;
  final String messageId;
  final String newContent;
  ConversationEditMessageRequested({
    required this.conversationId,
    required this.messageId,
    required this.newContent,
  });
}

class ConversationViewReadReceipts extends ConversationEvent {
  final String conversationId;
  final String messageId;
  ConversationViewReadReceipts({
    required this.conversationId,
    required this.messageId,
  });
}

class ConversationSearchMessages extends ConversationEvent {
  final String conversationId;
  final String query;
  ConversationSearchMessages({
    required this.conversationId,
    required this.query,
  });
}

class ConversationClearSearch extends ConversationEvent {}

// ─── Forward ───
class ConversationForwardMessageRequested extends ConversationEvent {
  final String targetConversationId;
  final String content;
  final String originalConvId;
  final String originalSenderName;
  ConversationForwardMessageRequested({
    required this.targetConversationId,
    required this.content,
    required this.originalConvId,
    required this.originalSenderName,
  });
}

// ─── Broadcast ───
class ConversationBroadcastRequested extends ConversationEvent {
  final List<String> conversationIds;
  final String content;
  ConversationBroadcastRequested({
    required this.conversationIds,
    required this.content,
  });
}

// ─── Group management ───
class ConversationCloseRequested extends ConversationEvent {
  final String conversationId;
  ConversationCloseRequested(this.conversationId);
}

class ConversationReopenRequested extends ConversationEvent {
  final String conversationId;
  ConversationReopenRequested(this.conversationId);
}

class ConversationAddParticipantRequested extends ConversationEvent {
  final String conversationId;
  final String participantId;
  final String name;
  final String role;
  ConversationAddParticipantRequested({
    required this.conversationId,
    required this.participantId,
    required this.name,
    required this.role,
  });
}

class ConversationRemoveParticipantRequested extends ConversationEvent {
  final String conversationId;
  final String participantId;
  final String name;
  ConversationRemoveParticipantRequested({
    required this.conversationId,
    required this.participantId,
    required this.name,
  });
}

// ─── Private reply from group ───
class ConversationPrivateReplyRequested extends ConversationEvent {
  final String participantId;
  final String participantName;
  final String participantRole;
  final String? message;
  ConversationPrivateReplyRequested({
    required this.participantId,
    required this.participantName,
    required this.participantRole,
    this.message,
  });
}

// ─── New conversation flow ───
class ConversationStartNewRequested extends ConversationEvent {
  final String type;
  final String? title;
  final List<Map<String, String>> participants;
  final String? firstMessage;
  ConversationStartNewRequested({
    required this.type,
    this.title,
    required this.participants,
    this.firstMessage,
  });
}
