import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/conversation_repository.dart';

class DeleteConversationParams {
  final String id;
  const DeleteConversationParams({required this.id});
}

class DeleteConversationUseCase implements UseCase<void, DeleteConversationParams> {
  final ConversationRepository repository;
  DeleteConversationUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(DeleteConversationParams p) =>
      repository.delete(p.id);
}
