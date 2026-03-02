import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/project_repository.dart';

class DeleteProjectParams {
  final String id;
  const DeleteProjectParams({required this.id});
}

class DeleteProjectUseCase implements UseCase<void, DeleteProjectParams> {
  final ProjectRepository repository;
  DeleteProjectUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(DeleteProjectParams p) =>
      repository.delete(p.id);
}
