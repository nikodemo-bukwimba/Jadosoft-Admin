import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/weekly_plan_entity.dart';

abstract class WeeklyPlanRepository {
  Future<Either<Failure, List<WeeklyPlanEntity>>> getAll();
  Future<Either<Failure, WeeklyPlanEntity>>       getById(String id);
  Future<Either<Failure, WeeklyPlanEntity>>       create(WeeklyPlanEntity entity);
  Future<Either<Failure, WeeklyPlanEntity>>       update(WeeklyPlanEntity entity);
  Future<Either<Failure, void>>                   delete(String id);
  Future<Either<Failure, WeeklyPlanEntity>>       approve(String id, {String? notes});
  Future<Either<Failure, WeeklyPlanEntity>>       reject(String id, {required String notes});
}