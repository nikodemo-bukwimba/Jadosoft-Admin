// organization_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/context/org_context.dart';
import '../../domain/repositories/organization_repository.dart';
import 'organization_event.dart';
import 'organization_state.dart';

class OrganizationBloc extends Bloc<OrganizationEvent, OrganizationState> {
  final OrganizationRepository repository;
  final OrgContext orgContext;

  OrganizationBloc({required this.repository, required this.orgContext})
    : super(OrganizationInitial()) {
    on<OrgLoadRequested>(_onLoadOrg);
    on<OrgCreateRequested>(_onCreateOrg);
    on<OrgTreeLoadRequested>(_onLoadTree);
    on<BranchesLoadRequested>(_onLoadBranches);
    on<BranchCreateRequested>(_onCreateBranch);
    on<RolesLoadRequested>(_onLoadRoles);
    on<RoleCreateRequested>(_onCreateRole);
    on<RoleDeleteRequested>(_onDeleteRole);
    on<RolePermissionsSyncRequested>(_onSyncPermissions);
    on<MembersLoadRequested>(_onLoadMembers);
    on<MemberInviteRequested>(_onInviteMember);
    on<MemberUpdateRequested>(_onUpdateMember);
    on<MemberRemoveRequested>(_onRemoveMember);
    on<MemberAssignToBranchRequested>(_onAssignToBranch);
    on<UserInfoUpdateRequested>(_onUpdateUserInfo);
    on<UserPasswordResetRequested>(_onPasswordReset);
    on<UserStatusUpdateRequested>(_onUpdateUserStatus);
    on<InvitationAcceptRequested>(_onAcceptInvitation);
    on<DelegationsLoadRequested>(_onLoadDelegations);
    on<DelegationCreateRequested>(_onCreateDelegation);
    on<DelegationRevokeRequested>(_onRevokeDelegation);
    on<PermissionRequestsLoadRequested>(_onLoadPermRequests);
    on<PermissionRequestApproveRequested>(_onApprovePermRequest);
    on<PermissionRequestDenyRequested>(_onDenyPermRequest);
    on<InvitationsLoadRequested>(_onLoadInvitations);
    on<InvitationCancelRequested>(_onCancelInvitation);
  }

  String? get _orgIdOrNull => orgContext.rootOrgId;

  String? _requireOrg(Emitter<OrganizationState> emit) {
    final id = _orgIdOrNull;
    if (id == null || id.isEmpty) {
      emit(NoOrganizationState());
      return null;
    }
    return id;
  }

  String _resolveOrgId(String? override) =>
      override ?? orgContext.effectiveOrgId;

  // ── Organization ──────────────────────────────────────────

  Future<void> _onLoadOrg(
    OrgLoadRequested e,
    Emitter<OrganizationState> emit,
  ) async {
    final id = _orgIdOrNull;
    debugPrint('[OrgBloc] rootOrgId = $id, hasOrg = ${orgContext.hasOrg}');
    if (id == null || id.isEmpty) {
      emit(NoOrganizationState());
      return;
    }
    emit(OrganizationLoading());
    final result = await repository.getOrg(id);
    result.fold(
      (f) => emit(OrganizationFailure(f.message)),
      (org) => emit(OrgLoaded(org)),
    );
  }

  Future<void> _onCreateOrg(
    OrgCreateRequested e,
    Emitter<OrganizationState> emit,
  ) async {
    emit(OrganizationLoading());
    final result = await repository.createOrg(e.data);
    result.fold((f) => emit(OrganizationFailure(f.message)), (org) async {
      await orgContext.setRootOrg(
        id: org.id,
        name: org.name,
        role: OrgRole.orgAdmin,
      );
      emit(OrgCreatedSuccess(org));
    });
  }

  Future<void> _onLoadTree(
    OrgTreeLoadRequested e,
    Emitter<OrganizationState> emit,
  ) async {
    final id = _requireOrg(emit);
    if (id == null) return;
    emit(OrganizationLoading());
    final result = await repository.getOrgTree(id);
    result.fold(
      (f) => emit(OrganizationFailure(f.message)),
      (tree) => emit(OrgTreeLoaded(tree)),
    );
  }

  Future<void> _onLoadInvitations(
    InvitationsLoadRequested e,
    Emitter<OrganizationState> emit,
  ) async {
    final id = _requireOrg(emit);
    if (id == null) return;
    emit(OrganizationLoading());
    final result = await repository.getInvitations(
      id,
      status: e.status ?? 'pending',
    );
    result.fold(
      (f) => emit(OrganizationFailure(f.message)),
      (invitations) => emit(InvitationsLoaded(invitations)),
    );
  }

  Future<void> _onCancelInvitation(
    InvitationCancelRequested e,
    Emitter<OrganizationState> emit,
  ) async {
    final id = _requireOrg(emit);
    if (id == null) return;
    emit(OrganizationLoading());
    final result = await repository.cancelInvitation(id, e.invitationId);
    result.fold((f) => emit(OrganizationFailure(f.message)), (_) {
      emit(OrganizationOperationSuccess('Invitation cancelled'));
      // Reload so list refreshes
      add(InvitationsLoadRequested());
    });
  }

  // ── Branches ──────────────────────────────────────────────

  Future<void> _onLoadBranches(
    BranchesLoadRequested e,
    Emitter<OrganizationState> emit,
  ) async {
    final id = _requireOrg(emit);
    if (id == null) return;
    emit(OrganizationLoading());
    final result = await repository.getBranches(id);
    result.fold(
      (f) => emit(OrganizationFailure(f.message)),
      (b) => emit(BranchesLoaded(b)),
    );
  }

  Future<void> _onCreateBranch(
    BranchCreateRequested e,
    Emitter<OrganizationState> emit,
  ) async {
    final id = _requireOrg(emit);
    if (id == null) return;
    emit(OrganizationLoading());
    final result = await repository.createBranch(id, e.data);
    result.fold(
      (f) => emit(OrganizationFailure(f.message)),
      (_) => emit(OrganizationOperationSuccess('Branch created')),
    );
  }

  // ── Roles ─────────────────────────────────────────────────

  Future<void> _onLoadRoles(
    RolesLoadRequested e,
    Emitter<OrganizationState> emit,
  ) async {
    final id = _requireOrg(emit);
    if (id == null) return;
    emit(OrganizationLoading());
    final rolesResult = await repository.getRoles(id);
    final permsResult = await repository.getPermissions(id);
    final availablePerms = permsResult.fold((_) => <dynamic>[], (p) => p);
    rolesResult.fold(
      (f) => emit(OrganizationFailure(f.message)),
      (roles) => emit(
        RolesLoaded(roles, availablePermissions: List.from(availablePerms)),
      ),
    );
  }

  Future<void> _onCreateRole(
    RoleCreateRequested e,
    Emitter<OrganizationState> emit,
  ) async {
    final id = _requireOrg(emit);
    if (id == null) return;
    emit(OrganizationLoading());
    final result = await repository.createRole(id, e.data);
    result.fold(
      (f) => emit(OrganizationFailure(f.message)),
      (_) => emit(OrganizationOperationSuccess('Role created')),
    );
  }

  Future<void> _onDeleteRole(
    RoleDeleteRequested e,
    Emitter<OrganizationState> emit,
  ) async {
    final id = _requireOrg(emit);
    if (id == null) return;
    emit(OrganizationLoading());
    final result = await repository.deleteRole(id, e.roleId);
    result.fold(
      (f) => emit(OrganizationFailure(f.message)),
      (_) => emit(OrganizationOperationSuccess('Role deleted')),
    );
  }

  Future<void> _onSyncPermissions(
    RolePermissionsSyncRequested e,
    Emitter<OrganizationState> emit,
  ) async {
    final id = _requireOrg(emit);
    if (id == null) return;
    emit(OrganizationLoading());
    final result = await repository.syncRolePermissions(
      id,
      e.roleId,
      e.permissionIds,
    );
    result.fold(
      (f) => emit(OrganizationFailure(f.message)),
      (_) => emit(OrganizationOperationSuccess('Permissions updated')),
    );
  }

  // ── Members ───────────────────────────────────────────────

  Future<void> _onLoadMembers(
    MembersLoadRequested e,
    Emitter<OrganizationState> emit,
  ) async {
    final id = _requireOrg(emit);
    if (id == null) return;
    emit(OrganizationLoading());
    final oid = _resolveOrgId(e.orgId);
    final result = await repository.getMembers(oid);
    result.fold(
      (f) => emit(OrganizationFailure(f.message)),
      (m) => emit(MembersLoaded(m)),
    );
  }

  Future<void> _onInviteMember(
    MemberInviteRequested e,
    Emitter<OrganizationState> emit,
  ) async {
    final id = _requireOrg(emit);
    if (id == null) return;

    emit(OrganizationLoading());

    final result = await repository.inviteMember(e.orgId, e.data);

    result.fold((f) => emit(OrganizationFailure(f.message)), (invitation) {
      // Extract the token and org name from the raw invitation map.
      final token = invitation['token'] as String? ?? '';
      final email =
          invitation['email'] as String? ?? e.data['email'] as String? ?? '';
      final orgName =
          invitation['organization']?['name'] as String? ??
          invitation['org_name'] as String? ??
          e.orgId; // fallback to orgId if name not returned

      emit(
        MemberInvitedWithToken(email: email, token: token, orgName: orgName),
      );
    });
  }

  Future<void> _onUpdateMember(
    MemberUpdateRequested e,
    Emitter<OrganizationState> emit,
  ) async {
    final id = _requireOrg(emit);
    if (id == null) return;
    emit(OrganizationLoading());
    final oid = _resolveOrgId(e.orgId);
    final result = await repository.updateMember(oid, e.userId, e.data);
    result.fold(
      (f) => emit(OrganizationFailure(f.message)),
      (_) => emit(OrganizationOperationSuccess('Member updated')),
    );
  }

  Future<void> _onRemoveMember(
    MemberRemoveRequested e,
    Emitter<OrganizationState> emit,
  ) async {
    final id = _requireOrg(emit);
    if (id == null) return;
    emit(OrganizationLoading());
    final oid = _resolveOrgId(e.orgId);
    final result = await repository.removeMember(oid, e.userId);
    result.fold(
      (f) => emit(OrganizationFailure(f.message)),
      (_) => emit(OrganizationOperationSuccess('Member removed')),
    );
  }

  Future<void> _onAssignToBranch(
    MemberAssignToBranchRequested e,
    Emitter<OrganizationState> emit,
  ) async {
    final id = _requireOrg(emit);
    if (id == null) return;
    emit(OrganizationLoading());
    final result = await repository.assignMemberToBranch(e.branchId, e.data);
    result.fold(
      (f) => emit(OrganizationFailure(f.message)),
      (_) => emit(OrganizationOperationSuccess('Member assigned to branch')),
    );
  }

  // ── User Account Management ───────────────────────────────

  Future<void> _onUpdateUserInfo(
    UserInfoUpdateRequested e,
    Emitter<OrganizationState> emit,
  ) async {
    emit(OrganizationLoading());
    final data = <String, dynamic>{
      if (e.name != null) 'name': e.name,
      if (e.email != null) 'email': e.email,
    };
    final result = await repository.updateUserInfo(e.userId, data);
    result.fold(
      (f) => emit(OrganizationFailure(f.message)),
      (_) => emit(UserManagementSuccess('User info updated successfully')),
    );
  }

  Future<void> _onPasswordReset(
    UserPasswordResetRequested e,
    Emitter<OrganizationState> emit,
  ) async {
    emit(OrganizationLoading());
    final result = await repository.sendPasswordResetEmail(e.email);
    result.fold(
      (f) => emit(OrganizationFailure(f.message)),
      (_) => emit(
        UserManagementSuccess('Password reset email sent to ${e.email}'),
      ),
    );
  }

  Future<void> _onUpdateUserStatus(
    UserStatusUpdateRequested e,
    Emitter<OrganizationState> emit,
  ) async {
    emit(OrganizationLoading());
    final result = await repository.updateUserStatus(e.userId, e.status);
    result.fold(
      (f) => emit(OrganizationFailure(f.message)),
      (_) => emit(UserManagementSuccess('User status updated to ${e.status}')),
    );
  }

  // ── Invitation Accept ─────────────────────────────────────

  Future<void> _onAcceptInvitation(
    InvitationAcceptRequested e,
    Emitter<OrganizationState> emit,
  ) async {
    emit(OrganizationLoading());
    final result = await repository.acceptInvitation(e.token);
    result.fold((f) => emit(OrganizationFailure(f.message)), (membership) {
      final orgName =
          membership['organization']?['name'] as String? ?? 'Organization';
      emit(InvitationAccepted('You have joined $orgName successfully!'));
    });
  }

  // ── Delegations ───────────────────────────────────────────

  Future<void> _onLoadDelegations(
    DelegationsLoadRequested e,
    Emitter<OrganizationState> emit,
  ) async {
    final id = _requireOrg(emit);
    if (id == null) return;
    emit(OrganizationLoading());
    final result = await repository.getDelegations(id);
    result.fold(
      (f) => emit(OrganizationFailure(f.message)),
      (d) => emit(DelegationsLoaded(d)),
    );
  }

  Future<void> _onCreateDelegation(
    DelegationCreateRequested e,
    Emitter<OrganizationState> emit,
  ) async {
    final id = _requireOrg(emit);
    if (id == null) return;
    emit(OrganizationLoading());
    final result = await repository.createDelegation(id, e.data);
    result.fold(
      (f) => emit(OrganizationFailure(f.message)),
      (_) => emit(OrganizationOperationSuccess('Role delegated to branch')),
    );
  }

  Future<void> _onRevokeDelegation(
    DelegationRevokeRequested e,
    Emitter<OrganizationState> emit,
  ) async {
    final id = _requireOrg(emit);
    if (id == null) return;
    emit(OrganizationLoading());
    final result = await repository.revokeDelegation(id, e.delegationId);
    result.fold(
      (f) => emit(OrganizationFailure(f.message)),
      (_) => emit(OrganizationOperationSuccess('Delegation revoked')),
    );
  }

  // ── Permission Requests ───────────────────────────────────

  Future<void> _onLoadPermRequests(
    PermissionRequestsLoadRequested e,
    Emitter<OrganizationState> emit,
  ) async {
    final id = _requireOrg(emit);
    if (id == null) return;
    emit(OrganizationLoading());
    final result = await repository.getPermissionRequests(id);
    result.fold(
      (f) => emit(OrganizationFailure(f.message)),
      (r) => emit(PermissionRequestsLoaded(r)),
    );
  }

  Future<void> _onApprovePermRequest(
    PermissionRequestApproveRequested e,
    Emitter<OrganizationState> emit,
  ) async {
    final id = _requireOrg(emit);
    if (id == null) return;
    emit(OrganizationLoading());
    final result = await repository.approvePermissionRequest(id, e.requestId);
    result.fold(
      (f) => emit(OrganizationFailure(f.message)),
      (_) => emit(OrganizationOperationSuccess('Request approved')),
    );
  }

  Future<void> _onDenyPermRequest(
    PermissionRequestDenyRequested e,
    Emitter<OrganizationState> emit,
  ) async {
    final id = _requireOrg(emit);
    if (id == null) return;
    emit(OrganizationLoading());
    final result = await repository.denyPermissionRequest(id, e.requestId);
    result.fold(
      (f) => emit(OrganizationFailure(f.message)),
      (_) => emit(OrganizationOperationSuccess('Request denied')),
    );
  }
}
