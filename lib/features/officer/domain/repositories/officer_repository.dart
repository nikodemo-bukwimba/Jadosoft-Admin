// lib/features/officer/domain/repositories/officer_repository.dart

import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/paginated_response.dart';
import '../entities/officer_entity.dart';

abstract class OfficerRepository {
  Future<Either<Failure, PaginatedResponse<OfficerEntity>>> getAll({
    String? status,
    String? search,
    int? perPage,
    int? page,
  });

  /// [branchId] — officer's actual branch; null falls back to root org.
  Future<Either<Failure, OfficerEntity>> getById(
    String userId, {
    String? branchId,
  });

  Future<Either<Failure, OfficerEntity>> invite({
    required String email,
    String? username,
    String? phone,
    required String branchId,
    required String orgRoleId,
    String? appPassword,
    String? appPasswordConfirmation,
  });

  Future<Either<Failure, OfficerEntity>> updateMembership(
    String userId, {
    String? orgRoleId,
    int? level,
    String? status,
    String? branchId,
  });

  Future<Either<Failure, void>> reassignBranch({
    required String userId,
    required String fromBranchId,
    required String toBranchId,
    required String orgRoleId,
  });

  Future<Either<Failure, OfficerEntity>> suspend(
    String userId, {
    String? branchId,
  });

  Future<Either<Failure, OfficerEntity>> activate(
    String userId, {
    String? branchId,
  });

  Future<Either<Failure, void>> suspendUser(String userId);
  Future<Either<Failure, void>> deactivateUser(String userId);
  Future<Either<Failure, void>> remove(String userId);
}
