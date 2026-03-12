import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/conversation_entity.dart';
import '../repositories/conversation_repository.dart';

class GetConversationParams {
  final String id;
  const GetConversationParams({required this.id});
}

class GetConversationUseCase implements UseCase<ConversationEntity, GetConversationParams> {
  final ConversationRepository repository;
  GetConversationUseCase(this.repository);

  @override
  Future<Either<Failure, ConversationEntity>> call(GetConversationParams p) =>
      repository.getById(p.id);
}
