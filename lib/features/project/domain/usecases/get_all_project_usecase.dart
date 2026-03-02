import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/project_entity.dart';
import '../repositories/project_repository.dart';

class GetAllProjectUseCase implements UseCase<List<ProjectEntity>, NoParams> {
  final ProjectRepository repository;
  GetAllProjectUseCase(this.repository);

  @override
  Future<Either<Failure, List<ProjectEntity>>> call(NoParams _) =>
      repository.getAll();
}
