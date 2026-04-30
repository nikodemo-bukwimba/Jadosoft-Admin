// organization_repository_impl.dart
import 'package:dartz/dartz.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/org_invitation_entity.dart';
import '../../domain/entities/organization_entity.dart';
import '../../domain/entities/branch_entity.dart';
import '../../domain/entities/org_role_entity.dart';
import '../../domain/entities/org_member_entity.dart';
import '../../domain/entities/delegation_entity.dart';
import '../../domain/entities/permission_request_entity.dart';
import '../../domain/entities/org_tree_entity.dart';
import '../../domain/repositories/organization_repository.dart';
import '../datasources/organization_remote_datasource.dart';

class OrganizationRepositoryImpl implements OrganizationRepository {
  final OrganizationRemoteDataSource _remote;
  OrganizationRepositoryImpl({required OrganizationRemoteDataSource remote})
    : _remote = remote;

  Future<Either<Failure, T>> _guard<T>(Future<T> Function() fn) async {
    try {
      return Right(await fn());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(GenericFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, OrganizationEntity>> createOrg(
    Map<String, dynamic> data,
  ) => _guard(() => _remote.createOrg(data));
  @override
  Future<Either<Failure, OrganizationEntity>> getOrg(String id) =>
      _guard(() => _remote.getOrg(id));
  @override
  Future<Either<Failure, OrgTreeNode>> getOrgTree(String orgId) =>
      _guard(() => _remote.getOrgTree(orgId));
  @override
  Future<Either<Failure, List<BranchEntity>>> getBranches(String orgId) =>
      _guard(() async => await _remote.getBranches(orgId));
  @override
  Future<Either<Failure, BranchEntity>> createBranch(
    String orgId,
    Map<String, dynamic> data,
  ) => _guard(() => _remote.createBranch(orgId, data));
  @override
  Future<Either<Failure, List<OrgRoleEntity>>> getRoles(String orgId) =>
      _guard(() async => await _remote.getRoles(orgId));
  @override
  Future<Either<Failure, OrgRoleEntity>> createRole(
    String orgId,
    Map<String, dynamic> data,
  ) => _guard(() => _remote.createRole(orgId, data));
  @override
  Future<Either<Failure, void>> deleteRole(String orgId, String roleId) =>
      _guard(() => _remote.deleteRole(orgId, roleId));
  @override
  Future<Either<Failure, void>> syncRolePermissions(
    String orgId,
    String roleId,
    List<String> permissionIds,
  ) => _guard(() => _remote.syncRolePermissions(orgId, roleId, permissionIds));
  @override
  Future<Either<Failure, Map<String, dynamic>>> acceptInvitation(
    String token,
  ) => _guard(() => _remote.acceptInvitation(token));
  @override
  Future<Either<Failure, List<OrgMemberEntity>>> getMembers(String orgId) =>
      _guard(() async => await _remote.getMembers(orgId));
  @override
  Future<Either<Failure, Map<String, dynamic>>> inviteMember(
    String orgId,
    Map<String, dynamic> data,
  ) => _guard(() => _remote.inviteMember(orgId, data));
  @override
  Future<Either<Failure, OrgMemberEntity>> updateMember(
    String orgId,
    String userId,
    Map<String, dynamic> data,
  ) => _guard(() => _remote.updateMember(orgId, userId, data));
  @override
  Future<Either<Failure, void>> removeMember(String orgId, String userId) =>
      _guard(() => _remote.removeMember(orgId, userId));
  @override
  Future<Either<Failure, void>> assignMemberToBranch(
    String branchId,
    Map<String, dynamic> data,
  ) => _guard(() => _remote.assignMemberToBranch(branchId, data));

  // ── User account management ────────────────────────────────
  @override
  Future<Either<Failure, void>> updateUserInfo(
    String userId,
    Map<String, dynamic> data,
  ) => _guard(() => _remote.updateUserInfo(userId, data));
  @override
  Future<Either<Failure, void>> updateUserStatus(
    String userId,
    String status,
  ) => _guard(() => _remote.updateUserStatus(userId, status));
  @override
  Future<Either<Failure, void>> sendPasswordResetEmail(String email) =>
      _guard(() => _remote.sendPasswordResetEmail(email));

  @override
  Future<Either<Failure, List<DelegationEntity>>> getDelegations(
    String orgId,
  ) => _guard(() async => await _remote.getDelegations(orgId));
  @override
  Future<Either<Failure, DelegationEntity>> createDelegation(
    String orgId,
    Map<String, dynamic> data,
  ) => _guard(() => _remote.createDelegation(orgId, data));
  @override
  Future<Either<Failure, void>> revokeDelegation(
    String orgId,
    String delegationId,
  ) => _guard(() => _remote.revokeDelegation(orgId, delegationId));
  @override
  Future<Either<Failure, List<PermissionRequestEntity>>> getPermissionRequests(
    String orgId,
  ) => _guard(() async => await _remote.getPermissionRequests(orgId));
  @override
  Future<Either<Failure, PermissionRequestEntity>> approvePermissionRequest(
    String orgId,
    String id,
  ) => _guard(() => _remote.approvePermissionRequest(orgId, id));
  @override
  Future<Either<Failure, PermissionRequestEntity>> denyPermissionRequest(
    String orgId,
    String id,
  ) => _guard(() => _remote.denyPermissionRequest(orgId, id));
  @override
  Future<Either<Failure, List<OrgPermissionEntity>>> getPermissions(
    String orgId,
  ) => _guard(() async => await _remote.getPermissions(orgId));
  @override
  Future<Either<Failure, List<OrgInvitationEntity>>> getInvitations(
    String orgId, {
    String status = 'pending',
  }) => _guard(() => _remote.getInvitations(orgId, status: status));

  @override
  Future<Either<Failure, void>> cancelInvitation(
    String orgId,
    String invitationId,
  ) => _guard(() => _remote.cancelInvitation(orgId, invitationId));
}
