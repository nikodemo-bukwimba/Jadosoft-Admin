import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/notification_entity.dart';
import '../guards/notification_transition_guard.dart';
import '../repositories/notification_repository.dart';
import '../value_objects/notification_status.dart';

class NotificationDomainService {
  final NotificationRepository repository;
  final NotificationTransitionGuard guard;

  NotificationDomainService({required this.repository, required this.guard});

  Future<Either<Failure, NotificationEntity>> transition({
    required String id,
    required NotificationStatus targetStatus,
  }) async {
    switch (targetStatus) {
      case NotificationStatus.queued:
        // Retry: re-queue a failed notification via dedicated API endpoint
        return repository.retry(id);
      default:
        return const Left(ValidationFailure('Transition not supported'));
    }
  }
}