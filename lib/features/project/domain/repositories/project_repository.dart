import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/project_entity.dart';

abstract class ProjectRepository {
  Future<Either<Failure, List<ProjectEntity>>> getAll();
  Future<Either<Failure, ProjectEntity>>       getById(String id);
  Future<Either<Failure, ProjectEntity>>       create(ProjectEntity entity);
  Future<Either<Failure, ProjectEntity>>       update(ProjectEntity entity);
  Future<Either<Failure, void>>                 delete(String id);
}
