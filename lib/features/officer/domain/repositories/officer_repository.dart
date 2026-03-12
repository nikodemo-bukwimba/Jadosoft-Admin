import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/officer_entity.dart';

abstract class OfficerRepository {
  Future<Either<Failure, List<OfficerEntity>>> getAll();
  Future<Either<Failure, OfficerEntity>>       getById(String id);
  Future<Either<Failure, OfficerEntity>>       create(OfficerEntity entity);
  Future<Either<Failure, OfficerEntity>>       update(OfficerEntity entity);
  Future<Either<Failure, void>>                 delete(String id);
}
