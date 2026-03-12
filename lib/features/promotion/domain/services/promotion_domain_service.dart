import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/promotion_entity.dart';
import '../guards/promotion_transition_guard.dart';
import '../repositories/promotion_repository.dart';
import '../value_objects/promotion_status.dart';

class PromotionDomainService {
  final PromotionRepository repository;
  final PromotionTransitionGuard guard;

  PromotionDomainService({
    required this.repository,
    required this.guard,
  });

  /// Performs a status transition: load, guard, apply, persist.
  Future<Either<Failure, PromotionEntity>> transition({
    required String id,
    required PromotionStatus targetStatus,
  }) async {
    // 1. Load
    final loadResult = await repository.getById(id);
    if (loadResult.isLeft()) return loadResult;
    final entity = loadResult.getOrElse(() => throw StateError('unreachable'));

    // 2. Guard
final guardResult = guard.validate(
  current: PromotionStatusX.fromString(entity.status),
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
