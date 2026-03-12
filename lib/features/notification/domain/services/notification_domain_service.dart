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

  /// Performs a status transition: load, guard, apply, persist.
  Future<Either<Failure, NotificationEntity>> transition({
    required String id,
    required NotificationStatus targetStatus,
  }) async {
    // 1. Load
    final loadResult = await repository.getById(id);
    if (loadResult.isLeft()) return loadResult;
    final entity = loadResult.getOrElse(() => throw StateError('unreachable'));

    // 2. Guard
    final guardResult = guard.validate(
      current: NotificationStatusX.fromString(entity.status),
      target: targetStatus,
    );
    if (guardResult.isLeft()) {
      return guardResult.fold(
        (f) => Left(f),
        (_) => throw StateError('unreachable'),
      );
    }
    final validTarget = guardResult.getOrElse(
      () => throw StateError('unreachable'),
    );

    // 3. Apply + Persist
    final updated = entity.copyWith(status: validTarget.name);
    return repository.update(updated);
  }
}
