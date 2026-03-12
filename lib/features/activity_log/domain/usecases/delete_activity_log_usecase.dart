import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/activity_log_repository.dart';

class DeleteActivityLogParams {
  final String id;
  const DeleteActivityLogParams({required this.id});
}

class DeleteActivityLogUseCase implements UseCase<void, DeleteActivityLogParams> {
  final ActivityLogRepository repository;
  DeleteActivityLogUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(DeleteActivityLogParams p) =>
      repository.delete(p.id);
}
