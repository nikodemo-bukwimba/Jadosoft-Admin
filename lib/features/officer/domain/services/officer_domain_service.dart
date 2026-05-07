// lib/features/officer/domain/services/officer_domain_service.dart

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
    String? branchId, // forwarded from the loaded entity
  }) async {
    // Load officer using their actual branchId to avoid 404
    final loadResult = await repository.getById(userId, branchId: branchId);
    if (loadResult.isLeft()) return loadResult;

    final entity = loadResult.getOrElse(() => throw StateError('unreachable'));

    final guardResult = guard.validate(
      current: OfficerStatusX.fromString(entity.effectiveStatus),
      target: targetStatus,
    );
    if (guardResult.isLeft()) {
      return guardResult.fold((f) => Left(f), (_) => throw StateError(''));
    }

    // Use entity.branchId for the actual PATCH URL
    switch (targetStatus) {
      case OfficerStatus.active:
        return repository.activate(userId, branchId: entity.branchId);
      case OfficerStatus.suspended:
        return repository.suspend(userId, branchId: entity.branchId);
      case OfficerStatus.deactivated:
        final r = await repository.deactivateUser(userId);
        return r.fold(
          (f) => Left(f),
          (_) => repository.getById(userId, branchId: entity.branchId),
        );
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
