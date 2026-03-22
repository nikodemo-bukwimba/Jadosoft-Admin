// officer_domain_service.dart
// ─────────────────────────────────────────────────────────────
// Orchestrates officer status transitions with guard validation.
//
// CHANGE from old version:
//   - No longer calls repository.update() to change status.
//   - Instead calls dedicated repository.suspend(), .activate(),
//     .suspendUser(), .deactivateUser() which map to real
//     API endpoints.
//   - Guard still validates the transition is allowed before
//     calling the API.
// ─────────────────────────────────────────────────────────────

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

  /// Performs a status transition: load → guard → call API.
  Future<Either<Failure, OfficerEntity>> transition({
    required String userId,
    required OfficerStatus targetStatus,
  }) async {
    // 1. Load current officer
    final loadResult = await repository.getById(userId);
    if (loadResult.isLeft()) return loadResult;
    final entity = loadResult.getOrElse(() => throw StateError('unreachable'));

    // 2. Guard — validate the transition is allowed
    final currentStatus = OfficerStatusX.fromString(entity.effectiveStatus);
    final guardResult = guard.validate(
      current: currentStatus,
      target: targetStatus,
    );
    if (guardResult.isLeft()) {
      return guardResult.fold(
        (f) => Left(f),
        (_) => throw StateError('unreachable'),
      );
    }

    // 3. Call the appropriate repository method based on target
    switch (targetStatus) {
      case OfficerStatus.active:
        return repository.activate(userId);

      case OfficerStatus.suspended:
        // Suspend at org membership level (reversible)
        return repository.suspend(userId);

      case OfficerStatus.deactivated:
        // Deactivate at platform level (permanent)
        final result = await repository.deactivateUser(userId);
        return result.fold(
          (f) => Left(f),
          (_) async {
            // Re-fetch the updated officer to return current state
            return repository.getById(userId);
          },
        );
    }
  }

  /// Reassign officer to a different branch.
  Future<Either<Failure, void>> reassignBranch({
    required String userId,
    required String fromBranchId,
    required String toBranchId,
    required String orgRoleId,
  }) {
    return repository.reassignBranch(
      userId: userId,
      fromBranchId: fromBranchId,
      toBranchId: toBranchId,
      orgRoleId: orgRoleId,
    );
  }
}