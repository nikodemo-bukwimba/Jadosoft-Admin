import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/conversation_entity.dart';
import '../repositories/conversation_repository.dart';

class GetAllConversationUseCase implements UseCase<List<ConversationEntity>, NoParams> {
  final ConversationRepository repository;
  GetAllConversationUseCase(this.repository);

  @override
  Future<Either<Failure, List<ConversationEntity>>> call(NoParams _) =>
      repository.getAll();
}
