import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/actor_entity.dart';
import '../repositories/actor_repository.dart';

class GetActorParams {
  final String id;
  const GetActorParams({required this.id});
}

class GetActorUseCase implements UseCase<ActorEntity, GetActorParams> {
  final ActorRepository repository;
  GetActorUseCase(this.repository);

  @override
  Future<Either<Failure, ActorEntity>> call(GetActorParams p) =>
      repository.getById(p.id);
}
