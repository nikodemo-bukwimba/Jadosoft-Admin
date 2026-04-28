// organization_state.dart
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

/// Fired when a user account action succeeded (reset, update info, etc.)
class UserManagementSuccess extends OrganizationState {
  final String message;
  UserManagementSuccess(this.message);
}

/// No organization exists yet — show create org form.
class NoOrganizationState extends OrganizationState {}

/// Organization just created — pending platform admin approval.
class OrgCreatedSuccess extends OrganizationState {
  final OrganizationEntity org;
  OrgCreatedSuccess(this.org);
}

/// Invitation accepted — user joined an org.
class InvitationAccepted extends OrganizationState {
  final String message;
  InvitationAccepted(this.message);
}

/// Carries the invitation token so the admin can share it via WhatsApp
/// or any other channel rather than relying solely on email.
class MemberInvitedWithToken extends OrganizationState {
  /// The email address the invitation was sent to.
  final String email;

  /// The 64-character invitation token from the server.
  final String token;

  /// The org/branch name the user is being invited to.
  final String orgName;

  MemberInvitedWithToken({
    required this.email,
    required this.token,
    required this.orgName,
  });

  List<Object?> get props => [email, token, orgName];
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
