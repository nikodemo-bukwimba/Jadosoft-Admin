import '../../domain/entities/conversation_entity.dart';
import '../../domain/entities/message_entity.dart';

abstract class ConversationState {}

class ConversationInitial extends ConversationState {}

class ConversationLoading extends ConversationState {}

class ConversationListLoaded extends ConversationState {
  final List<ConversationEntity> items;
  ConversationListLoaded(this.items);
}

class ConversationDetailLoaded extends ConversationState {
  final ConversationEntity item;
  ConversationDetailLoaded(this.item);
}

class ConversationOperationSuccess extends ConversationState {
  final String message;
  ConversationOperationSuccess(this.message);
}

class ConversationEmpty extends ConversationState {}

class ConversationFailure extends ConversationState {
  final String message;
  ConversationFailure(this.message);
}

class ConversationChatLoaded extends ConversationState {
  final ConversationEntity conversation;
  final List<MessageEntity> messages;
  final String? typingUser;
  final List<MessageEntity>? searchResults;
  final String? searchQuery;
  final List<MessageEntity>? pinnedMessages;

  ConversationChatLoaded({
    required this.conversation,
    required this.messages,
    this.typingUser,
    this.searchResults,
    this.searchQuery,
    this.pinnedMessages,
  });

  ConversationChatLoaded copyWith({
    ConversationEntity? conversation,
    List<MessageEntity>? messages,
    String? typingUser,
    bool clearTyping = false,
    List<MessageEntity>? searchResults,
    String? searchQuery,
    bool clearSearch = false,
    List<MessageEntity>? pinnedMessages,
  }) {
    return ConversationChatLoaded(
      conversation: conversation ?? this.conversation,
      messages: messages ?? this.messages,
      typingUser: clearTyping ? null : (typingUser ?? this.typingUser),
      searchResults: clearSearch ? null : (searchResults ?? this.searchResults),
      searchQuery: clearSearch ? null : (searchQuery ?? this.searchQuery),
      pinnedMessages: pinnedMessages ?? this.pinnedMessages,
    );
  }
}

class ConversationNewCreated extends ConversationState {
  final String conversationId;
  ConversationNewCreated(this.conversationId);
}

class ConversationReadReceiptsLoaded extends ConversationState {
  final List<ReadReceipt> receipts;
  final String messageId;
  ConversationReadReceiptsLoaded({
    required this.receipts,
    required this.messageId,
  });
}

class ConversationBroadcastSuccess extends ConversationState {
  final int sentCount;
  ConversationBroadcastSuccess(this.sentCount);
}
