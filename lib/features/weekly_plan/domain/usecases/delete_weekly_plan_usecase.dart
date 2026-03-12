import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/weekly_plan_repository.dart';

class DeleteWeeklyPlanParams {
  final String id;
  const DeleteWeeklyPlanParams({required this.id});
}

class DeleteWeeklyPlanUseCase implements UseCase<void, DeleteWeeklyPlanParams> {
  final WeeklyPlanRepository repository;
  DeleteWeeklyPlanUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(DeleteWeeklyPlanParams p) =>
      repository.delete(p.id);
}
