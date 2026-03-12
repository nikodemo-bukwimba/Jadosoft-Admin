import '../../domain/entities/conversation_entity.dart';
import '../../domain/usecases/create_conversation_usecase.dart';

abstract class ConversationEvent {}

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
