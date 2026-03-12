import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/notification_entity.dart';
import '../repositories/notification_repository.dart';

class GetAllNotificationUseCase implements UseCase<List<NotificationEntity>, NoParams> {
  final NotificationRepository repository;
  GetAllNotificationUseCase(this.repository);

  @override
  Future<Either<Failure, List<NotificationEntity>>> call(NoParams _) =>
      repository.getAll();
}
