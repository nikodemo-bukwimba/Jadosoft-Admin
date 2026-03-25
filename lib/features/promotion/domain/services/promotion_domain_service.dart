// promotion_domain_service.dart
// ─────────────────────────────────────────────────────────────
// Replaces the Maishell version entirely.
// Keeps the same class name, constructor, and transition() signature.
//
// Changes vs Maishell:
//   • activate (draft → active): calls datasource.publish() directly
//     instead of repository.update() — this hits the real Nexora
//     POST /pharma/product-updates/{id}/publish endpoint.
//   • end (active → ended): PATCH with local status 'ended' via update().
//   • cancel (draft/active → cancelled): PATCH with status 'cancelled'
//     via update().
//   • Guard still validates all transitions before any API call.
// ─────────────────────────────────────────────────────────────

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

  /// Performs a status transition with guard validation.
  ///
  /// [PromotionStatus.active]    → calls repository.publish() (real broadcast)
  /// [PromotionStatus.ended]     → PATCH status via repository.update()
  /// [PromotionStatus.cancelled] → PATCH status via repository.update()
  Future<Either<Failure, PromotionEntity>> transition({
    required String id,
    required PromotionStatus targetStatus,
  }) async {
    // 1. Load current entity
    final loadResult = await repository.getById(id);
    if (loadResult.isLeft()) return loadResult;
    final entity = loadResult.getOrElse(() => throw StateError('unreachable'));

    // 2. Guard — validate transition is allowed
    final guardResult = guard.validate(
      current: PromotionStatusX.fromString(entity.status),
      target:  targetStatus,
    );
    if (guardResult.isLeft()) {
      return guardResult.fold((f) => Left(f), (_) => throw StateError('unreachable'));
    }

    // 3. Execute the correct API action per target status
    switch (targetStatus) {
      case PromotionStatus.active:
        // Publish triggers the broadcast — dedicated Nexora endpoint
        return repository.publish(id);

      case PromotionStatus.ended:
      case PromotionStatus.cancelled:
        // Local status patch — Nexora has no dedicated endpoint for these
        final updated = entity.copyWith(status: targetStatus.name);
        return repository.update(updated);

      case PromotionStatus.draft:
        return const Left(ValidationFailure('Cannot transition back to draft'));
    }
  }
}