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
    required Dio dio,
    required OrgContext orgContext,
  }) : _orgContext = orgContext,
       super(dio: dio);

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

      // /tree returns a FLAT list of all orgs in the hierarchy.
      // Root has type:'root', depth:0. Branches have type:'branch', depth:1.
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
        data: {'permission_ids': permissionIds}, // ← key is permission_ids
      );
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  // ── Members ───────────────────────────────────────────────

  Future<List<OrgMemberModel>> getMembers(String orgId) async {
    try {
      final response = await dio.get(ApiPaths.orgs.members(orgId));
      final data = response.data;
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

  Future<OrgMemberModel> inviteMember(
    String orgId,
    Map<String, dynamic> data,
  ) => postAndParse(
    '${ApiPaths.orgs.members(orgId)}/invite',
    data,
    OrgMemberModel.fromJson,
    dataKey: 'member',
  );

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

  Future<PermissionRequestModel> denyPermissionRequest(
    String orgId,
    String id,
  ) => postAction(
    '/orgs/$orgId/permission-requests/$id/deny',
    PermissionRequestModel.fromJson,
    dataKey: 'request',
  );

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
}
