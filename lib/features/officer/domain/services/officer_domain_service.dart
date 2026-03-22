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
    required String userId, required OfficerStatus targetStatus,
  }) async {
    final loadResult = await repository.getById(userId);
    if (loadResult.isLeft()) return loadResult;
    final entity = loadResult.getOrElse(() => throw StateError('unreachable'));
    final guardResult = guard.validate(
      current: OfficerStatusX.fromString(entity.effectiveStatus), target: targetStatus,
    );
    if (guardResult.isLeft()) return guardResult.fold((f) => Left(f), (_) => throw StateError(''));
    switch (targetStatus) {
      case OfficerStatus.active: return repository.activate(userId);
      case OfficerStatus.suspended: return repository.suspend(userId);
      case OfficerStatus.deactivated:
        final r = await repository.deactivateUser(userId);
        return r.fold((f) => Left(f), (_) => repository.getById(userId));
    }
  }

  Future<Either<Failure, void>> reassignBranch({
    required String userId, required String fromBranchId,
    required String toBranchId, required String orgRoleId,
  }) => repository.reassignBranch(userId: userId, fromBranchId: fromBranchId,
    toBranchId: toBranchId, orgRoleId: orgRoleId);
}
