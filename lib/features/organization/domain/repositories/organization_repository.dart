// organization_repository.dart
import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/org_invitation_entity.dart';
import '../entities/organization_entity.dart';
import '../entities/branch_entity.dart';
import '../entities/org_role_entity.dart';
import '../entities/org_member_entity.dart';
import '../entities/delegation_entity.dart';
import '../entities/permission_request_entity.dart';
import '../entities/org_tree_entity.dart';

abstract class OrganizationRepository {
  // ── Organization ──────────────────────────────────────────
  Future<Either<Failure, OrganizationEntity>> createOrg(
    Map<String, dynamic> data,
  );
  Future<Either<Failure, OrganizationEntity>> getOrg(String id);
  Future<Either<Failure, OrgTreeNode>> getOrgTree(String orgId);

  // ── Branches ──────────────────────────────────────────────
  Future<Either<Failure, List<BranchEntity>>> getBranches(String orgId);
  Future<Either<Failure, BranchEntity>> createBranch(
    String orgId,
    Map<String, dynamic> data,
  );

  // ── Roles ─────────────────────────────────────────────────
  Future<Either<Failure, List<OrgRoleEntity>>> getRoles(String orgId);
  Future<Either<Failure, OrgRoleEntity>> createRole(
    String orgId,
    Map<String, dynamic> data,
  );
  Future<Either<Failure, void>> deleteRole(String orgId, String roleId);
  Future<Either<Failure, void>> syncRolePermissions(
    String orgId,
    String roleId,
    List<String> permissionIds,
  );
  Future<Either<Failure, Map<String, dynamic>>> acceptInvitation(String token);

  // ── Members ───────────────────────────────────────────────
  Future<Either<Failure, List<OrgMemberEntity>>> getMembers(String orgId);
  Future<Either<Failure, Map<String, dynamic>>> inviteMember(
    String orgId,
    Map<String, dynamic> data,
  );
  Future<Either<Failure, OrgMemberEntity>> updateMember(
    String orgId,
    String userId,
    Map<String, dynamic> data,
  );
  Future<Either<Failure, void>> removeMember(String orgId, String userId);
  Future<Either<Failure, void>> assignMemberToBranch(
    String branchId,
    Map<String, dynamic> data,
  );

  // ── Invitations ───────────────────────────────────────────
  Future<Either<Failure, List<OrgInvitationEntity>>> getInvitations(
    String orgId, {
    String status = 'pending',
  });
  Future<Either<Failure, void>> cancelInvitation(
    String orgId,
    String invitationId,
  );

  // ── User Account Management ───────────────────────────────
  Future<Either<Failure, void>> updateUserInfo(
    String userId,
    Map<String, dynamic> data,
  );
  Future<Either<Failure, void>> updateUserStatus(String userId, String status);
  Future<Either<Failure, void>> sendPasswordResetEmail(String email);

  // ── Delegations ───────────────────────────────────────────
  Future<Either<Failure, List<DelegationEntity>>> getDelegations(String orgId);
  Future<Either<Failure, DelegationEntity>> createDelegation(
    String orgId,
    Map<String, dynamic> data,
  );
  Future<Either<Failure, void>> revokeDelegation(
    String orgId,
    String delegationId,
  );

  // ── Permission Requests ───────────────────────────────────
  Future<Either<Failure, List<PermissionRequestEntity>>> getPermissionRequests(
    String orgId,
  );
  Future<Either<Failure, PermissionRequestEntity>> approvePermissionRequest(
    String orgId,
    String requestId,
  );
  Future<Either<Failure, PermissionRequestEntity>> denyPermissionRequest(
    String orgId,
    String requestId,
  );
  Future<Either<Failure, List<OrgPermissionEntity>>> getPermissions(
    String orgId,
  );
}
