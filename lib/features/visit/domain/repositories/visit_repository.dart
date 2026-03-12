import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/visit_entity.dart';

abstract class VisitRepository {
  Future<Either<Failure, List<VisitEntity>>> getAll();
  Future<Either<Failure, VisitEntity>>       getById(String id);
  Future<Either<Failure, VisitEntity>>       create(VisitEntity entity);
  Future<Either<Failure, VisitEntity>>       update(VisitEntity entity);
  Future<Either<Failure, void>>                 delete(String id);
}
