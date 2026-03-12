import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/conversation_entity.dart';
import '../repositories/conversation_repository.dart';

class UpdateConversationParams {
  final ConversationEntity entity;
  const UpdateConversationParams({required this.entity});
}

class UpdateConversationUseCase implements UseCase<ConversationEntity, UpdateConversationParams> {
  final ConversationRepository repository;
  UpdateConversationUseCase(this.repository);

  @override
  Future<Either<Failure, ConversationEntity>> call(UpdateConversationParams p) async {
    return repository.update(p.entity);
  }
}
