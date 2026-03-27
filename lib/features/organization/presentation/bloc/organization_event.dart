import '../../domain/entities/org_role_entity.dart';

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
  final String? orgId; // null = use effectiveOrgId
  MembersLoadRequested({this.orgId});
}

class MemberInviteRequested extends OrganizationEvent {
  final String? orgId;
  final Map<String, dynamic> data;
  MemberInviteRequested({this.orgId, required this.data});
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

// ── Delegations ─────────────────────────────────────────────
class DelegationsLoadRequested extends OrganizationEvent {}

class DelegationCreateRequested extends OrganizationEvent {
  final Map<String, dynamic> data;
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

class PermissionsLoadRequested extends OrganizationEvent {}
