import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/weekly_plan_entity.dart';
import '../repositories/weekly_plan_repository.dart';

class GetWeeklyPlanParams {
  final String id;
  const GetWeeklyPlanParams({required this.id});
}

class GetWeeklyPlanUseCase implements UseCase<WeeklyPlanEntity, GetWeeklyPlanParams> {
  final WeeklyPlanRepository repository;
  GetWeeklyPlanUseCase(this.repository);

  @override
  Future<Either<Failure, WeeklyPlanEntity>> call(GetWeeklyPlanParams p) =>
      repository.getById(p.id);
}
