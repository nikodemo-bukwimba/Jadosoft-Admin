import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/activity_log_entity.dart';
import '../repositories/activity_log_repository.dart';

class GetActivityLogParams {
  final String id;
  const GetActivityLogParams({required this.id});
}

class GetActivityLogUseCase implements UseCase<ActivityLogEntity, GetActivityLogParams> {
  final ActivityLogRepository repository;
  GetActivityLogUseCase(this.repository);

  @override
  Future<Either<Failure, ActivityLogEntity>> call(GetActivityLogParams p) =>
      repository.getById(p.id);
}
