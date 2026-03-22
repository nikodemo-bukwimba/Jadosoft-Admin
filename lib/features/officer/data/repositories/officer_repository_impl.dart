import 'package:dartz/dartz.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/paginated_response.dart';
import '../../domain/entities/officer_entity.dart';
import '../../domain/repositories/officer_repository.dart';
import '../datasources/officer_remote_datasource.dart';

class OfficerRepositoryImpl implements OfficerRepository {
  final OfficerRemoteDataSource _remote;
  OfficerRepositoryImpl({required OfficerRemoteDataSource remoteDataSource}) : _remote = remoteDataSource;

  Future<Either<Failure, T>> _guard<T>(Future<T> Function() call) async {
    try { return Right(await call());
    } on AuthException catch (e) { return Left(AuthFailure(e.message));
    } on ServerException catch (e) { return Left(ServerFailure(e.message));
    } on NetworkException catch (e) { return Left(NetworkFailure(e.message));
    } catch (e) { return Left(GenericFailure(e.toString())); }
  }

  @override
  Future<Either<Failure, PaginatedResponse<OfficerEntity>>> getAll({
    String? status, String? search, int? perPage, int? page,
  }) => _guard(() => _remote.getAll(status: status, search: search, perPage: perPage, page: page));

  @override Future<Either<Failure, OfficerEntity>> getById(String userId) => _guard(() => _remote.getById(userId));
  @override Future<Either<Failure, OfficerEntity>> invite({
    required String email, String? username, String? phone, required String branchId, required String orgRoleId,
  }) => _guard(() => _remote.invite(email: email, username: username, phone: phone, branchId: branchId, orgRoleId: orgRoleId));
  @override Future<Either<Failure, OfficerEntity>> updateMembership(String userId, {String? orgRoleId, int? level, String? status}) =>
      _guard(() => _remote.updateMembership(userId, orgRoleId: orgRoleId, level: level, status: status));
  @override Future<Either<Failure, void>> reassignBranch({required String userId, required String fromBranchId, required String toBranchId, required String orgRoleId}) =>
      _guard(() => _remote.reassignBranch(userId: userId, fromBranchId: fromBranchId, toBranchId: toBranchId, orgRoleId: orgRoleId));
  @override Future<Either<Failure, OfficerEntity>> suspend(String userId) => _guard(() => _remote.suspend(userId));
  @override Future<Either<Failure, OfficerEntity>> activate(String userId) => _guard(() => _remote.activate(userId));
  @override Future<Either<Failure, void>> suspendUser(String userId) => _guard(() => _remote.suspendUser(userId));
  @override Future<Either<Failure, void>> deactivateUser(String userId) => _guard(() => _remote.deactivateUser(userId));
  @override Future<Either<Failure, void>> remove(String userId) => _guard(() => _remote.remove(userId));
}
