import '../../domain/entities/organization_entity.dart';
import '../../domain/entities/branch_entity.dart';
import '../../domain/entities/org_role_entity.dart';
import '../../domain/entities/org_member_entity.dart';
import '../../domain/entities/delegation_entity.dart';
import '../../domain/entities/permission_request_entity.dart';
import '../../domain/entities/org_tree_entity.dart';

abstract class OrganizationState {}

class OrganizationInitial extends OrganizationState {}

class OrganizationLoading extends OrganizationState {}

class OrganizationFailure extends OrganizationState {
  final String message;
  OrganizationFailure(this.message);
}

class OrganizationOperationSuccess extends OrganizationState {
  final String message;
  OrganizationOperationSuccess(this.message);
}

/// No organization exists yet — show create org form.
class NoOrganizationState extends OrganizationState {}

/// Organization just created — pending platform admin approval.
class OrgCreatedSuccess extends OrganizationState {
  final OrganizationEntity org;
  OrgCreatedSuccess(this.org);
}

/// Invitation accepted — user joined an org. Reload everything.
class InvitationAccepted extends OrganizationState {
  final String message;
  InvitationAccepted(this.message);
}

// ── Org ─────────────────────────────────────────────────────
class OrgLoaded extends OrganizationState {
  final OrganizationEntity org;
  OrgLoaded(this.org);
}

class OrgTreeLoaded extends OrganizationState {
  final OrgTreeNode tree;
  OrgTreeLoaded(this.tree);
}

// ── Branches ────────────────────────────────────────────────
class BranchesLoaded extends OrganizationState {
  final List<BranchEntity> branches;
  BranchesLoaded(this.branches);
}

// ── Roles ───────────────────────────────────────────────────
class RolesLoaded extends OrganizationState {
  final List<OrgRoleEntity> roles;
  final List<OrgPermissionEntity> availablePermissions;
  RolesLoaded(this.roles, {this.availablePermissions = const []});
}

// ── Members ─────────────────────────────────────────────────
class MembersLoaded extends OrganizationState {
  final List<OrgMemberEntity> members;
  MembersLoaded(this.members);
}

// ── Delegations ─────────────────────────────────────────────
class DelegationsLoaded extends OrganizationState {
  final List<DelegationEntity> delegations;
  DelegationsLoaded(this.delegations);
}

// ── Permission Requests ─────────────────────────────────────
class PermissionRequestsLoaded extends OrganizationState {
  final List<PermissionRequestEntity> requests;
  PermissionRequestsLoaded(this.requests);
}
