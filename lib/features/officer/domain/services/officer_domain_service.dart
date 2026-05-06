// lib/features/officer/domain/services/officer_domain_service.dart
//
// FIX 3: Pass officer's actual branchId when calling activate/suspend.
// Previously `repository.activate(userId)` would fall through to the
// datasource which used `_orgContext.effectiveOrgId` (root), causing 404.
// Now we load the officer first, extract branchId, and forward it.

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

  Future<Either<Failure, OfficerEntity>> transition({
    required String userId,
    required OfficerStatus targetStatus,
  }) async {
    // Load the officer to get their actual branchId and current status
    final loadResult = await repository.getById(userId);
    if (loadResult.isLeft()) return loadResult;

    final entity = loadResult.getOrElse(() => throw StateError('unreachable'));

    // Guard: validate the transition is permitted
    final guardResult = guard.validate(
      current: OfficerStatusX.fromString(entity.effectiveStatus),
      target: targetStatus,
    );
    if (guardResult.isLeft()) {
      return guardResult.fold((f) => Left(f), (_) => throw StateError(''));
    }

    // FIX: pass entity.branchId so the datasource uses the correct
    // membership URL instead of the root org fallback.
    switch (targetStatus) {
      case OfficerStatus.active:
        return repository.activate(userId, branchId: entity.branchId);
      case OfficerStatus.suspended:
        return repository.suspend(userId, branchId: entity.branchId);
      case OfficerStatus.deactivated:
        final r = await repository.deactivateUser(userId);
        return r.fold((f) => Left(f), (_) => repository.getById(userId));
    }
  }

  Future<Either<Failure, void>> reassignBranch({
    required String userId,
    required String fromBranchId,
    required String toBranchId,
    required String orgRoleId,
  }) => repository.reassignBranch(
    userId: userId,
    fromBranchId: fromBranchId,
    toBranchId: toBranchId,
    orgRoleId: orgRoleId,
  );
}
