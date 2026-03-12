import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/notification_entity.dart';

abstract class NotificationRepository {
  Future<Either<Failure, List<NotificationEntity>>> getAll();
  Future<Either<Failure, NotificationEntity>>       getById(String id);
  Future<Either<Failure, NotificationEntity>>       create(NotificationEntity entity);
  Future<Either<Failure, NotificationEntity>>       update(NotificationEntity entity);
  Future<Either<Failure, void>>                 delete(String id);
}
