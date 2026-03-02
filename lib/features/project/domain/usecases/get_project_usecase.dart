import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/project_entity.dart';
import '../repositories/project_repository.dart';

class GetProjectParams {
  final String id;
  const GetProjectParams({required this.id});
}

class GetProjectUseCase implements UseCase<ProjectEntity, GetProjectParams> {
  final ProjectRepository repository;
  GetProjectUseCase(this.repository);

  @override
  Future<Either<Failure, ProjectEntity>> call(GetProjectParams p) =>
      repository.getById(p.id);
}
