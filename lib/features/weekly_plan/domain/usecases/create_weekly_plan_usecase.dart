import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/weekly_plan_entity.dart';
import '../repositories/weekly_plan_repository.dart';

class CreateWeeklyPlanParams {
  final String officerId;
  final DateTime weekStart;
  final DateTime weekEnd;
  final List<String>? plannedCustomerIds;
  final String? plannedActivities;
  final String? notes;

  const CreateWeeklyPlanParams({
    required this.officerId,
    required this.weekStart,
    required this.weekEnd,
    this.plannedCustomerIds,
    this.plannedActivities,
    this.notes,
  });
}

class CreateWeeklyPlanUseCase implements UseCase<WeeklyPlanEntity, CreateWeeklyPlanParams> {
  final WeeklyPlanRepository repository;
  CreateWeeklyPlanUseCase(this.repository);

  @override
  Future<Either<Failure, WeeklyPlanEntity>> call(CreateWeeklyPlanParams p) async {
    // -- Validation gate --
    if (p.officerId.trim().isEmpty) {
      return const Left(ValidationFailure('Officer is required'));
    }

    return repository.create(
      WeeklyPlanEntity(
        id: '',
        officerId: p.officerId.trim(),
        weekStart: p.weekStart,
        weekEnd: p.weekEnd,
        plannedCustomerIds: p.plannedCustomerIds,
        plannedActivities: p.plannedActivities?.trim(),
        notes: p.notes?.trim(),
        status: '',
        submittedAt: null,
        reviewedAt: null,
        createdAt: DateTime.now(),
      ),
    );
  }
}
