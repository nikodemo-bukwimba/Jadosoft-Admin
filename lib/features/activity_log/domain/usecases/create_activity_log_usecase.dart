import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/activity_log_entity.dart';
import '../repositories/activity_log_repository.dart';

class CreateActivityLogParams {
  const CreateActivityLogParams();
}

class CreateActivityLogUseCase
    implements UseCase<ActivityLogEntity, CreateActivityLogParams> {
  final ActivityLogRepository repository;
  CreateActivityLogUseCase(this.repository);

  @override
  Future<Either<Failure, ActivityLogEntity>> call(
    CreateActivityLogParams p,
  ) async {
    return repository.create(
      ActivityLogEntity(
        id: '',
        actorId: '',
        actorName: '',
        actorRole: '',
        action: '',
        entityType: '',
        entityId: '',
        entitySnapshot: null,
        ipAddress: '',
        userAgent: '',
        occurredAt: DateTime.now(),
      ),
    );
  }
}
