import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/actor_repository.dart';

class DeleteActorParams {
  final String id;
  const DeleteActorParams({required this.id});
}

class DeleteActorUseCase implements UseCase<void, DeleteActorParams> {
  final ActorRepository repository;
  DeleteActorUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(DeleteActorParams p) =>
      repository.delete(p.id);
}
