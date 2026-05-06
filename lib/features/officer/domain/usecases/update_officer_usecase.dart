// lib/features/officer/domain/usecases/update_officer_usecase.dart
//
// FIX 3: Pass entity.branchId so updateMembership hits the correct URL.

import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/officer_entity.dart';
import '../repositories/officer_repository.dart';

class UpdateOfficerParams {
  final OfficerEntity entity;
  const UpdateOfficerParams({required this.entity});
}

class UpdateOfficerUseCase
    implements UseCase<OfficerEntity, UpdateOfficerParams> {
  final OfficerRepository repository;
  UpdateOfficerUseCase(this.repository);

  @override
  Future<Either<Failure, OfficerEntity>> call(UpdateOfficerParams p) =>
      repository.updateMembership(
        p.entity.userId,
        orgRoleId: p.entity.orgRoleId,
        status: p.entity.membershipStatus,
        // FIX: pass the officer's actual branch so the PATCH goes to
        // /orgs/{branchId}/members/{userId}, not /orgs/{rootOrgId}/...
        branchId: p.entity.branchId,
      );
}
