import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/visit_entity.dart';
import '../guards/visit_transition_guard.dart';
import '../repositories/visit_repository.dart';
import '../value_objects/visit_status.dart';

class VisitDomainService {
  final VisitRepository repository;
  final VisitTransitionGuard guard;

  VisitDomainService({
    required this.repository,
    required this.guard,
  });

  /// Performs a status transition: load, guard, apply, persist.
  Future<Either<Failure, VisitEntity>> transition({
    required String id,
    required VisitStatus targetStatus,
  }) async {
    // 1. Load
    final loadResult = await repository.getById(id);
    if (loadResult.isLeft()) return loadResult;
    final entity = loadResult.getOrElse(() => throw StateError('unreachable'));

    // 2. Guard
final guardResult = guard.validate(
  current: VisitStatusX.fromString(entity.status),
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
