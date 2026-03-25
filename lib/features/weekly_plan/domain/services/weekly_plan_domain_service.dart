import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/weekly_plan_entity.dart';
import '../repositories/weekly_plan_repository.dart';
import '../value_objects/weekly_plan_status.dart';

class WeeklyPlanDomainService {
  final WeeklyPlanRepository repository;

  WeeklyPlanDomainService({required this.repository});

  Future<Either<Failure, WeeklyPlanEntity>> transition({
    required String id,
    required WeeklyPlanStatus targetStatus,
    String? notes,
  }) async {
    switch (targetStatus) {
      case WeeklyPlanStatus.approved:
        return repository.approve(id, notes: notes);
      case WeeklyPlanStatus.rejected:
        if (notes == null || notes.trim().isEmpty) {
          return const Left(ValidationFailure('Rejection reason is required'));
        }
        return repository.reject(id, notes: notes);
      case WeeklyPlanStatus.submitted:
        // Resubmit: update status to submitted via update
        final loadResult = await repository.getById(id);
        return loadResult.fold(
          Left.new,
          (entity) => repository.update(entity.copyWith(status: 'submitted')),
        );
      default:
        return const Left(ValidationFailure('Transition not supported'));
    }
  }
}