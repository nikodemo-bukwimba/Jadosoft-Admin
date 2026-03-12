import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/weekly_plan_entity.dart';
import '../repositories/weekly_plan_repository.dart';

class UpdateWeeklyPlanParams {
  final WeeklyPlanEntity entity;
  const UpdateWeeklyPlanParams({required this.entity});
}

class UpdateWeeklyPlanUseCase implements UseCase<WeeklyPlanEntity, UpdateWeeklyPlanParams> {
  final WeeklyPlanRepository repository;
  UpdateWeeklyPlanUseCase(this.repository);

  @override
  Future<Either<Failure, WeeklyPlanEntity>> call(UpdateWeeklyPlanParams p) async {
    return repository.update(p.entity);
  }
}
