import '../../domain/entities/conversation_entity.dart';

abstract class ConversationState {}

class ConversationInitial          extends ConversationState {}
class ConversationLoading           extends ConversationState {}

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
