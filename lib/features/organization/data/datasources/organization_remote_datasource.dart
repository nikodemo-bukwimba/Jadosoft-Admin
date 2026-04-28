// organization_remote_datasource.dart
import 'package:dio/dio.dart';
import '../../../../core/context/org_context.dart';
import '../../../../core/network/api_paths.dart';
import '../../../../core/network/base_remote_datasource.dart';
import '../models/organization_model.dart';
import '../models/branch_model.dart';
import '../models/org_role_model.dart';
import '../models/org_member_model.dart';
import '../models/delegation_model.dart';
import '../models/permission_request_model.dart';
import '../models/org_tree_model.dart';

class OrganizationRemoteDataSource extends BaseRemoteDataSource {
  final OrgContext _orgContext;

  OrganizationRemoteDataSource({
    required super.dio,
    required OrgContext orgContext,
  }) : _orgContext = orgContext;

  // ── Organization ──────────────────────────────────────────

  Future<OrganizationModel> createOrg(Map<String, dynamic> data) =>
      postAndParse(
        ApiPaths.orgs.create,
        data,
        OrganizationModel.fromJson,
        dataKey: 'organization',
      );

  Future<OrganizationModel> getOrg(String id) => fetchSingle(
    '/orgs/$id',
    OrganizationModel.fromJson,
    dataKey: 'organization',
  );

  Future<OrgTreeNodeModel> getOrgTree(String orgId) async {
    try {
      final response = await dio.get('/orgs/$orgId/tree');
      final data = response.data is Map<String, dynamic>
          ? (response.data['tree'] ?? response.data['data'] ?? response.data)
                as Map<String, dynamic>
          : response.data as Map<String, dynamic>;
      return OrgTreeNodeModel.fromJson(data);
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  // ── Branches ──────────────────────────────────────────────

  Future<List<BranchModel>> getBranches(String orgId) async {
    try {
      final response = await dio.get(ApiPaths.orgs.tree(orgId));
      final raw = response.data;
      final List<dynamic> items = raw is List ? raw : [];
      return items
          .where((e) => (e as Map<String, dynamic>)['type'] == 'branch')
          .map((e) => BranchModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  Future<BranchModel> createBranch(String orgId, Map<String, dynamic> data) =>
      postAndParse(
        ApiPaths.orgs.branches(orgId),
        data,
        BranchModel.fromJson,
        dataKey: 'branch',
      );

  // ── Roles ─────────────────────────────────────────────────

  Future<List<OrgRoleModel>> getRoles(String orgId) async {
    try {
      final response = await dio.get(ApiPaths.orgs.roles(orgId));
      final data = response.data;
      final List<dynamic> items = data is Map<String, dynamic>
          ? (data['data'] as List<dynamic>? ??
                data['roles'] as List<dynamic>? ??
                [])
          : (data as List<dynamic>? ?? []);
      return items
          .map((e) => OrgRoleModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  Future<OrgRoleModel> createRole(String orgId, Map<String, dynamic> data) =>
      postAndParse(
        ApiPaths.orgs.roles(orgId),
        data,
        OrgRoleModel.fromJson,
        dataKey: 'role',
      );

  Future<void> deleteRole(String orgId, String roleId) async {
    try {
      await dio.delete('${ApiPaths.orgs.roles(orgId)}/$roleId');
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  Future<void> syncRolePermissions(
    String orgId,
    String roleId,
    List<String> permissionIds,
  ) async {
    try {
      await dio.post(
        ApiPaths.orgs.rolePermissions(orgId, roleId),
        data: {'permission_ids': permissionIds},
      );
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  // ── Members ───────────────────────────────────────────────
  // FIX: requests per_page=200 to get all members (root org tree query).
  // The backend fix includes branch members when querying root org.

  Future<List<OrgMemberModel>> getMembers(String orgId) async {
    try {
      final response = await dio.get(
        ApiPaths.orgs.members(orgId),
        queryParameters: {'per_page': 200},
      );
      final data = response.data;
      // Paginated response: { data: [...], ... } or flat list
      final List<dynamic> items = data is Map<String, dynamic>
          ? (data['data'] as List<dynamic>? ??
                data['members'] as List<dynamic>? ??
                [])
          : (data as List<dynamic>? ?? []);
      return items
          .map((e) => OrgMemberModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  /// Invite by email to a SPECIFIC org/branch (orgId = target branch).
  Future<Map<String, dynamic>> inviteMember(
    String orgId,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await dio.post(
        '${ApiPaths.orgs.members(orgId)}/invite',
        data: data,
      );
      final body = response.data;
      if (body is Map<String, dynamic>) {
        // Server returns: { message: '...', invitation: { token, email, ... } }
        return body['invitation'] as Map<String, dynamic>? ?? body;
      }
      return {};
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  Future<OrgMemberModel> updateMember(
    String orgId,
    String userId,
    Map<String, dynamic> data,
  ) => patchAndParse(
    ApiPaths.orgs.member(orgId, userId),
    data,
    OrgMemberModel.fromJson,
    dataKey: 'member',
  );

  Future<void> removeMember(String orgId, String userId) =>
      deleteResource(ApiPaths.orgs.member(orgId, userId));

  Future<void> assignMemberToBranch(
    String branchId,
    Map<String, dynamic> data,
  ) async {
    try {
      await dio.post('${ApiPaths.orgs.members(branchId)}/assign', data: data);
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  // ── User Account Management ───────────────────────────────
  // These call platform admin endpoints to update user info.

  /// Update user's display name (actor.display_name) via profile endpoint.
  /// The platform exposes PATCH /admin/users/{id}/status for status changes.
  /// For name/email we use a workaround via the actor endpoint if available,
  /// or fall back to the member update endpoint.
  Future<void> updateUserInfo(String userId, Map<String, dynamic> data) async {
    try {
      // Try admin endpoint first
      await dio.patch('/admin/users/$userId/info', data: data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404 || e.response?.statusCode == 405) {
        // Fallback: update via org membership actor name (best effort)
        try {
          await dio.patch(
            '/actors/${data['actor_id'] ?? userId}',
            data: {if (data['name'] != null) 'display_name': data['name']},
          );
        } on DioException catch (_) {}
      } else {
        throw mapDioException(e);
      }
    }
  }

  /// Change user account status: active | suspended | banned.
  Future<void> updateUserStatus(String userId, String status) async {
    try {
      await dio.patch(
        ApiPaths.admin.userStatus(userId),
        data: {'status': status},
      );
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  /// Trigger password reset email (uses Fortify's forgot-password endpoint).
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await dio.post('/forgot-password', data: {'email': email});
    } on DioException catch (e) {
      // 422 = email not found; surface that clearly
      throw mapDioException(e);
    }
  }

  // ── Delegations ───────────────────────────────────────────

  Future<List<DelegationModel>> getDelegations(String orgId) async {
    try {
      final response = await dio.get(ApiPaths.orgs.delegations(orgId));
      final data = response.data;
      final List<dynamic> items = data is Map<String, dynamic>
          ? (data['data'] as List<dynamic>? ??
                data['delegations'] as List<dynamic>? ??
                [])
          : (data as List<dynamic>? ?? []);
      return items
          .map((e) => DelegationModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  Future<DelegationModel> createDelegation(
    String orgId,
    Map<String, dynamic> data,
  ) => postAndParse(
    ApiPaths.orgs.delegations(orgId),
    data,
    DelegationModel.fromJson,
    dataKey: 'delegation',
  );

  Future<void> revokeDelegation(String orgId, String delegationId) =>
      deleteResource('${ApiPaths.orgs.delegations(orgId)}/$delegationId');

  // ── Permission Requests ───────────────────────────────────

  Future<List<PermissionRequestModel>> getPermissionRequests(
    String orgId,
  ) async {
    try {
      final response = await dio.get('/orgs/$orgId/permission-requests');
      final data = response.data;
      final List<dynamic> items = data is Map<String, dynamic>
          ? (data['data'] as List<dynamic>? ?? [])
          : (data as List<dynamic>? ?? []);
      return items
          .map(
            (e) => PermissionRequestModel.fromJson(e as Map<String, dynamic>),
          )
          .toList();
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  Future<PermissionRequestModel> approvePermissionRequest(
    String orgId,
    String id,
  ) => postAction(
    '/orgs/$orgId/permission-requests/$id/approve',
    PermissionRequestModel.fromJson,
    dataKey: 'request',
  );

  Future<PermissionRequestModel> denyPermissionRequest(
    String orgId,
    String id,
  ) => postAction(
    '/orgs/$orgId/permission-requests/$id/deny',
    PermissionRequestModel.fromJson,
    dataKey: 'request',
  );

  Future<List<OrgPermissionModel>> getPermissions(String orgId) async {
    try {
      final response = await dio.get(ApiPaths.orgs.permissions(orgId));
      final data = response.data;
      final List<dynamic> items = data is Map<String, dynamic>
          ? (data['data'] as List<dynamic>? ??
                data['permissions'] as List<dynamic>? ??
                [])
          : (data as List<dynamic>? ?? []);
      return items
          .map((e) => OrgPermissionModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  Future<Map<String, dynamic>> acceptInvitation(String token) async {
    try {
      final response = await dio.post('orgs/invitations/$token/accept');
      final data = response.data;
      return data is Map<String, dynamic>
          ? (data['membership'] as Map<String, dynamic>? ?? data)
          : <String, dynamic>{};
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }
}
