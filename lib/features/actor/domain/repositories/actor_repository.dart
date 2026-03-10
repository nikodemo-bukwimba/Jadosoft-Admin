import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/actor_entity.dart';

abstract class ActorRepository {
  Future<Either<Failure, List<ActorEntity>>> getAll();
  Future<Either<Failure, ActorEntity>>       getById(String id);
  Future<Either<Failure, ActorEntity>>       create(ActorEntity entity);
  Future<Either<Failure, ActorEntity>>       update(ActorEntity entity);
  Future<Either<Failure, void>>                 delete(String id);
}
