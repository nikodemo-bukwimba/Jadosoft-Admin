import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/activity_log_entity.dart';
import '../repositories/activity_log_repository.dart';

class UpdateActivityLogParams {
  final ActivityLogEntity entity;
  const UpdateActivityLogParams({required this.entity});
}

class UpdateActivityLogUseCase implements UseCase<ActivityLogEntity, UpdateActivityLogParams> {
  final ActivityLogRepository repository;
  UpdateActivityLogUseCase(this.repository);

  @override
  Future<Either<Failure, ActivityLogEntity>> call(UpdateActivityLogParams p) async {
    return repository.update(p.entity);
  }
}
