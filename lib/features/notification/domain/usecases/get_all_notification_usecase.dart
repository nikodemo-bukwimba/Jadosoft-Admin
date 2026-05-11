// get_all_notification_usecase.dart
import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/notification_entity.dart';
import '../repositories/notification_repository.dart';

class GetAllNotificationParams {
  final String? status;
  final String? channel;
  final int perPage;
  final int page;

  const GetAllNotificationParams({
    this.status,
    this.channel,
    this.perPage = 50,
    this.page = 1,
  });
}

class GetAllNotificationUseCase
    implements UseCase<List<NotificationEntity>, GetAllNotificationParams> {
  final NotificationRepository repository;
  GetAllNotificationUseCase(this.repository);

  @override
  Future<Either<Failure, List<NotificationEntity>>> call(
    GetAllNotificationParams p,
  ) => repository.getAll(
    status: p.status,
    channel: p.channel,
    perPage: p.perPage,
    page: p.page,
  );
}
