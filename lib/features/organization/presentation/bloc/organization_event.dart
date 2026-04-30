// organization_event.dart
// import '../../domain/entities/org_role_entity.dart';

abstract class OrganizationEvent {}

// ── Organization ────────────────────────────────────────────
class OrgLoadRequested extends OrganizationEvent {}

class OrgCreateRequested extends OrganizationEvent {
  final Map<String, dynamic> data;
  OrgCreateRequested(this.data);
}

class OrgTreeLoadRequested extends OrganizationEvent {}

// ── Branches ────────────────────────────────────────────────
class BranchesLoadRequested extends OrganizationEvent {}

class BranchCreateRequested extends OrganizationEvent {
  final Map<String, dynamic> data;
  BranchCreateRequested(this.data);
}

// ── Roles ───────────────────────────────────────────────────
class RolesLoadRequested extends OrganizationEvent {}

class RoleCreateRequested extends OrganizationEvent {
  final Map<String, dynamic> data;
  RoleCreateRequested(this.data);
}

class RoleDeleteRequested extends OrganizationEvent {
  final String roleId;
  RoleDeleteRequested(this.roleId);
}

class RolePermissionsSyncRequested extends OrganizationEvent {
  final String roleId;
  final List<String> permissionIds;
  RolePermissionsSyncRequested({
    required this.roleId,
    required this.permissionIds,
  });
}

// ── Members ─────────────────────────────────────────────────
class MembersLoadRequested extends OrganizationEvent {
  final String? orgId;
  MembersLoadRequested({this.orgId});
}

/// Invite a user by email to a SPECIFIC branch with a role.
/// [orgId] = target branch/org to invite into (required).
class MemberInviteRequested extends OrganizationEvent {
  final String orgId; // ← required: which branch they're invited to
  final Map<String, dynamic> data; // { email, org_role_id, level }
  MemberInviteRequested({required this.orgId, required this.data});
}

class MemberUpdateRequested extends OrganizationEvent {
  final String? orgId;
  final String userId;
  final Map<String, dynamic> data;
  MemberUpdateRequested({this.orgId, required this.userId, required this.data});
}

class MemberRemoveRequested extends OrganizationEvent {
  final String? orgId;
  final String userId;
  MemberRemoveRequested({this.orgId, required this.userId});
}

/// Assign an existing root-org member directly to a branch (no email invite).
class MemberAssignToBranchRequested extends OrganizationEvent {
  final String branchId;
  final Map<String, dynamic> data; // { user_id, org_role_id, level? }
  MemberAssignToBranchRequested({required this.branchId, required this.data});
}

// ── User Account Management ─────────────────────────────────
/// Update a member's display name / email at the platform level.
class UserInfoUpdateRequested extends OrganizationEvent {
  final String userId;
  final String? name;
  final String? email;
  UserInfoUpdateRequested({required this.userId, this.name, this.email});
}

/// Trigger a password reset email for a member.
class UserPasswordResetRequested extends OrganizationEvent {
  final String email;
  UserPasswordResetRequested(this.email);
}

/// Change a member's account status (active / suspended / banned).
class UserStatusUpdateRequested extends OrganizationEvent {
  final String userId;
  final String status; // 'active' | 'suspended' | 'banned'
  UserStatusUpdateRequested({required this.userId, required this.status});
}

// ── Invitation Accept ───────────────────────────────────────
class InvitationAcceptRequested extends OrganizationEvent {
  final String token;
  InvitationAcceptRequested(this.token);
}

// ── Delegations ─────────────────────────────────────────────
class DelegationsLoadRequested extends OrganizationEvent {}

/// Create a delegation: grant a specific member an additional role on a branch.
/// [parentOrgId] = the org that owns the role being delegated (root org).
/// [childOrgId]  = the branch receiving the delegated role.
/// [orgRoleId]   = the role being delegated.
/// [memberId]    = optional: the specific member to grant this on the branch.
class DelegationCreateRequested extends OrganizationEvent {
  final Map<String, dynamic> data;
  // data shape: {
  //   child_org_id:    String,   required
  //   org_role_id:     String,   required
  //   permission_ids:  List<String>,  optional (defaults to all role perms)
  //   member_user_id:  String?,  optional — for member-specific delegation display
  // }
  DelegationCreateRequested(this.data);
}

class DelegationRevokeRequested extends OrganizationEvent {
  final String delegationId;
  DelegationRevokeRequested(this.delegationId);
}

// ── Permission Requests ─────────────────────────────────────
class PermissionRequestsLoadRequested extends OrganizationEvent {}

class PermissionRequestApproveRequested extends OrganizationEvent {
  final String requestId;
  PermissionRequestApproveRequested(this.requestId);
}

class PermissionRequestDenyRequested extends OrganizationEvent {
  final String requestId;
  PermissionRequestDenyRequested(this.requestId);
}

class InvitationsLoadRequested extends OrganizationEvent {
  final String? status; // null = 'pending'
  InvitationsLoadRequested({this.status});
}

class InvitationCancelRequested extends OrganizationEvent {
  final String invitationId;
  InvitationCancelRequested(this.invitationId);
}
