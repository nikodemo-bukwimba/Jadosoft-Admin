// notification_repository.dart  (abstract)
// ─────────────────────────────────────────────────────────────
// Trimmed to only the operations the backend actually supports.
// create / update / delete are NOT available on NotificationController.
// ─────────────────────────────────────────────────────────────

import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/notification_entity.dart';

abstract class NotificationRepository {
  Future<Either<Failure, List<NotificationEntity>>> getAll({
    String? status,
    String? channel,
    int perPage,
    int page,
  });

  Future<Either<Failure, NotificationEntity>> getById(String id);

  /// Re-queues a failed delivery via POST /notifications/{id}/retry
  Future<Either<Failure, NotificationEntity>> retry(String id);
}
