import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/officer_entity.dart';
import '../guards/officer_transition_guard.dart';
import '../repositories/officer_repository.dart';
import '../value_objects/officer_status.dart';

class OfficerDomainService {
  final OfficerRepository repository;
  final OfficerTransitionGuard guard;

  OfficerDomainService({required this.repository, required this.guard});

  /// Performs a status transition: load, guard, apply, persist.
  Future<Either<Failure, OfficerEntity>> transition({
    required String id,
    required OfficerStatus targetStatus,
  }) async {
    // 1. Load
    final loadResult = await repository.getById(id);
    if (loadResult.isLeft()) return loadResult;
    final entity = loadResult.getOrElse(() => throw StateError('unreachable'));

    // 2. Guard
    final guardResult = guard.validate(
      current: OfficerStatusX.fromString(entity.status),
      target: targetStatus,
    );
    if (guardResult.isLeft()) {
      return guardResult.fold(
        (f) => Left(f),
        (_) => throw StateError('unreachable'),
      );
    }
    final validTarget = guardResult.getOrElse(
      () => throw StateError('unreachable'),
    );

    // 3. Apply + Persist
    final updated = entity.copyWith(status: validTarget.name);
    return repository.update(updated);
  }
}
