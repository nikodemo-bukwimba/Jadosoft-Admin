import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/conversation_entity.dart';
import '../repositories/conversation_repository.dart';

class CreateConversationParams {
  final List<ConversationParticipant> participants;
  final ConversationType type;
  final String? title;
  final String? lastMessage;
  final DateTime? lastMessageAt;
  final int unreadCount;

  const CreateConversationParams({
    required this.participants,
    required this.type,
    this.title,
    this.lastMessage,
    this.lastMessageAt,
    this.unreadCount = 0,
  });
}

class CreateConversationUseCase
    implements UseCase<ConversationEntity, CreateConversationParams> {
  final ConversationRepository repository;
  CreateConversationUseCase(this.repository);

  @override
  Future<Either<Failure, ConversationEntity>> call(
    CreateConversationParams p,
  ) async {
    return repository.create(
      ConversationEntity(
        id: '',
        type: p.type,
        status: ConversationStatus.open,
        title: p.title,
        participants: p.participants,
        lastMessage: p.lastMessage?.trim(),
        lastMessageAt: p.lastMessageAt,
        unreadCount: p.unreadCount,
        createdAt: DateTime.now(),
      ),
    );
  }
}
