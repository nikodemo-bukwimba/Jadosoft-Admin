// officer_repository.dart
// ─────────────────────────────────────────────────────────────
// Domain repository contract for officer management.
//
// Officers are org members — this interface abstracts over
// the composite nature (user + actor + membership) so the
// domain layer doesn't care how they are stored or fetched.
// ─────────────────────────────────────────────────────────────

import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/paginated_response.dart';
import '../entities/officer_entity.dart';

abstract class OfficerRepository {
  /// List officers for the current org/branch context (paginated).
  Future<Either<Failure, PaginatedResponse<OfficerEntity>>> getAll({
    String? status,
    String? search,
    int? perPage,
    int? page,
  });

  /// Get a single officer by user ID.
  Future<Either<Failure, OfficerEntity>> getById(String userId);

  /// Invite/add a new officer to a branch with a role.
  Future<Either<Failure, OfficerEntity>> invite({
    required String email,
    String? username,
    String? phone,
    required String branchId,
    required String orgRoleId,
  });

  /// Update an officer's membership (role, level, status).
  Future<Either<Failure, OfficerEntity>> updateMembership(
    String userId, {
    String? orgRoleId,
    int? level,
    String? status,
  });

  /// Reassign an officer to a different branch.
  Future<Either<Failure, void>> reassignBranch({
    required String userId,
    required String fromBranchId,
    required String toBranchId,
    required String orgRoleId,
  });

  /// Suspend officer at org membership level.
  Future<Either<Failure, OfficerEntity>> suspend(String userId);

  /// Activate (unsuspend) officer at org membership level.
  Future<Either<Failure, OfficerEntity>> activate(String userId);

  /// Suspend user at platform level (all orgs affected).
  Future<Either<Failure, void>> suspendUser(String userId);

  /// Deactivate user at platform level (permanent).
  Future<Either<Failure, void>> deactivateUser(String userId);

  /// Remove officer from the org entirely.
  Future<Either<Failure, void>> remove(String userId);
}