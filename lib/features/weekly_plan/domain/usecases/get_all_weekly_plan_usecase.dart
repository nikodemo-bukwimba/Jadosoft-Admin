import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/weekly_plan_entity.dart';
import '../repositories/weekly_plan_repository.dart';

class GetAllWeeklyPlanUseCase implements UseCase<List<WeeklyPlanEntity>, NoParams> {
  final WeeklyPlanRepository repository;
  GetAllWeeklyPlanUseCase(this.repository);

  @override
  Future<Either<Failure, List<WeeklyPlanEntity>>> call(NoParams _) =>
      repository.getAll();
}
