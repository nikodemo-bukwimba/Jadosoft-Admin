import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../features/project/domain/entities/project_entity.dart';
import '../../../../features/project/domain/repositories/project_repository.dart';
import '../../domain/providers/project_data_provider.dart';

class ProjectDataProviderImpl implements ProjectDataProvider {
  final ProjectRepository _repository;

  ProjectDataProviderImpl({required ProjectRepository repository})
      : _repository = repository;

  @override
  Future<Either<Failure, List<ProjectEntity>>> getAll() =>
      _repository.getAll();
}
