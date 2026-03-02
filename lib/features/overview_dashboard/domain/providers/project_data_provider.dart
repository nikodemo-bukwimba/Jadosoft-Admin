import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../features/project/domain/entities/project_entity.dart';

/// Provider interface to access Project data from project feature.
abstract class ProjectDataProvider {
  Future<Either<Failure, List<ProjectEntity>>> getAll();
}
