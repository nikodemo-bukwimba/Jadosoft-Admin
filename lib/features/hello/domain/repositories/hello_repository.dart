import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/h_e_l_l_o_entity.dart';

abstract class HelloRepository {
  Future<Either<Failure, List<HelloEntity>>> getAll();
  Future<Either<Failure, HelloEntity>>       getById(String id);
  Future<Either<Failure, HelloEntity>>       create(HelloEntity entity);
  Future<Either<Failure, HelloEntity>>       update(HelloEntity entity);
  Future<Either<Failure, void>>                 delete(String id);
}
