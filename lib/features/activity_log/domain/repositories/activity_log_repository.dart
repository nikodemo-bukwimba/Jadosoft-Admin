import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/activity_log_entity.dart';

abstract class ActivityLogRepository {
  Future<Either<Failure, List<ActivityLogEntity>>> getAll();
  Future<Either<Failure, ActivityLogEntity>>       getById(String id);
  Future<Either<Failure, ActivityLogEntity>>       create(ActivityLogEntity entity);
  Future<Either<Failure, ActivityLogEntity>>       update(ActivityLogEntity entity);
  Future<Either<Failure, void>>                 delete(String id);
}
