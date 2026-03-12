import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/conversation_entity.dart';
import '../repositories/conversation_repository.dart';

class CreateConversationParams {
  final List<String> participantIds;
  final List<String> participantRoles;
  final String? lastMessage;
  final DateTime? lastMessageAt;
  final int unreadCount;

  const CreateConversationParams({
    required this.participantIds,
    required this.participantRoles,
    this.lastMessage,
    this.lastMessageAt,
    required this.unreadCount,
  });
}

class CreateConversationUseCase implements UseCase<ConversationEntity, CreateConversationParams> {
  final ConversationRepository repository;
  CreateConversationUseCase(this.repository);

  @override
  Future<Either<Failure, ConversationEntity>> call(CreateConversationParams p) async {
    // -- Validation gate --
    // No validation rules configured

    return repository.create(
      ConversationEntity(
        id: '',
        participantIds: p.participantIds,
        participantRoles: p.participantRoles,
        lastMessage: p.lastMessage?.trim(),
        lastMessageAt: p.lastMessageAt,
        unreadCount: p.unreadCount,
        createdAt: DateTime.now(),
      ),
    );
  }
}
