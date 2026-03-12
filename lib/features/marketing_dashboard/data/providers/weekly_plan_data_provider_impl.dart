import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../features/weekly_plan/domain/entities/weekly_plan_entity.dart';
import '../../../../features/weekly_plan/domain/repositories/weekly_plan_repository.dart';
import '../../domain/providers/weekly_plan_data_provider.dart';

class WeeklyPlanDataProviderImpl implements WeeklyPlanDataProvider {
  final WeeklyPlanRepository _repository;

  WeeklyPlanDataProviderImpl({required WeeklyPlanRepository repository})
      : _repository = repository;

  @override
  Future<Either<Failure, List<WeeklyPlanEntity>>> getAll() =>
      _repository.getAll();
}
