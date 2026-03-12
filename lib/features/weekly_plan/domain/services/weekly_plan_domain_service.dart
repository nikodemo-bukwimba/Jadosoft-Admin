import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/weekly_plan_entity.dart';
import '../guards/weekly_plan_transition_guard.dart';
import '../repositories/weekly_plan_repository.dart';
import '../value_objects/weekly_plan_status.dart';

class WeeklyPlanDomainService {
  final WeeklyPlanRepository repository;
  final WeeklyPlanTransitionGuard guard;

  WeeklyPlanDomainService({
    required this.repository,
    required this.guard,
  });

  /// Performs a status transition: load, guard, apply, persist.
  Future<Either<Failure, WeeklyPlanEntity>> transition({
    required String id,
    required WeeklyPlanStatus targetStatus,
  }) async {
    // 1. Load
    final loadResult = await repository.getById(id);
    if (loadResult.isLeft()) return loadResult;
    final entity = loadResult.getOrElse(() => throw StateError('unreachable'));

    // 2. Guard
final guardResult = guard.validate(
  current: WeeklyPlanStatusX.fromString(entity.status),
  target:  targetStatus,
);
    if (guardResult.isLeft()) {
      return guardResult.fold((f) => Left(f), (_) => throw StateError('unreachable'));
    }
    final validTarget = guardResult.getOrElse(() => throw StateError('unreachable'));

    // 3. Apply + Persist
    final updated = entity.copyWith(status: validTarget.name);
    return repository.update(updated);
  }
}
