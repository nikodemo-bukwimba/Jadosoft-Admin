import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/actor_entity.dart';
import '../repositories/actor_repository.dart';

class UpdateActorParams {
  final ActorEntity entity;
  const UpdateActorParams({required this.entity});
}

class UpdateActorUseCase implements UseCase<ActorEntity, UpdateActorParams> {
  final ActorRepository repository;
  UpdateActorUseCase(this.repository);

  @override
  Future<Either<Failure, ActorEntity>> call(UpdateActorParams p) async {
    return repository.update(p.entity);
  }
}
