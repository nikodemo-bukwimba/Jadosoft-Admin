import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/notification_entity.dart';
import '../repositories/notification_repository.dart';

class GetNotificationParams {
  final String id;
  const GetNotificationParams({required this.id});
}

class GetNotificationUseCase implements UseCase<NotificationEntity, GetNotificationParams> {
  final NotificationRepository repository;
  GetNotificationUseCase(this.repository);

  @override
  Future<Either<Failure, NotificationEntity>> call(GetNotificationParams p) =>
      repository.getById(p.id);
}
