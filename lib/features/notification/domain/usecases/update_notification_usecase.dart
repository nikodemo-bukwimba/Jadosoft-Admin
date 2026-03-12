import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/notification_entity.dart';
import '../repositories/notification_repository.dart';

class UpdateNotificationParams {
  final NotificationEntity entity;
  const UpdateNotificationParams({required this.entity});
}

class UpdateNotificationUseCase implements UseCase<NotificationEntity, UpdateNotificationParams> {
  final NotificationRepository repository;
  UpdateNotificationUseCase(this.repository);

  @override
  Future<Either<Failure, NotificationEntity>> call(UpdateNotificationParams p) async {
    return repository.update(p.entity);
  }
}
