import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/notification_repository.dart';

class DeleteNotificationParams {
  final String id;
  const DeleteNotificationParams({required this.id});
}

class DeleteNotificationUseCase implements UseCase<void, DeleteNotificationParams> {
  final NotificationRepository repository;
  DeleteNotificationUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(DeleteNotificationParams p) =>
      repository.delete(p.id);
}
