import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/project_entity.dart';
import '../repositories/project_repository.dart';

class UpdateProjectParams {
  final ProjectEntity entity;
  const UpdateProjectParams({required this.entity});
}

class UpdateProjectUseCase implements UseCase<ProjectEntity, UpdateProjectParams> {
  final ProjectRepository repository;
  UpdateProjectUseCase(this.repository);

  @override
  Future<Either<Failure, ProjectEntity>> call(UpdateProjectParams p) async {
    return repository.update(p.entity);
  }
}
