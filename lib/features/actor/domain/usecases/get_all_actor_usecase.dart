import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/actor_entity.dart';
import '../repositories/actor_repository.dart';

class GetAllActorUseCase implements UseCase<List<ActorEntity>, NoParams> {
  final ActorRepository repository;
  GetAllActorUseCase(this.repository);

  @override
  Future<Either<Failure, List<ActorEntity>>> call(NoParams _) =>
      repository.getAll();
}
