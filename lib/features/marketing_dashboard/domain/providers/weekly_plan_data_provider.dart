import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../features/weekly_plan/domain/entities/weekly_plan_entity.dart';

/// Provider interface to access WeeklyPlan data from weekly_plan feature.
abstract class WeeklyPlanDataProvider {
  Future<Either<Failure, List<WeeklyPlanEntity>>> getAll();
}
