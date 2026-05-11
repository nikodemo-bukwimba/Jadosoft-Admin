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

  /// Problem #2 fix: creates a fully active User account.
  /// The officer can log in immediately using [email] + [password].
  /// [fullName] becomes actor.display_name (the real displayed name).
  Future<Either<Failure, OfficerEntity>> create({
    required String fullName,
    required String email,
    required String password,
    required String passwordConfirmation,
    String? phone,
    required String branchId,
    required String orgRoleId,
    int? level,
  });

  Future<Either<Failure, OfficerEntity>> updateMembership(
    String userId, {
    String? orgRoleId,
    int? level,
    String? status,
    String? branchId,
  });

  /// Problem #3 fix: safe branch transfer via the dedicated transfer endpoint.
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
