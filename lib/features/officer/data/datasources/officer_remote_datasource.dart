// lib/features/officer/data/datasources/officer_remote_datasource.dart

import 'package:dio/dio.dart';
import '../../../../core/context/org_context.dart';
import '../../../../core/network/api_paths.dart';
import '../../../../core/network/base_remote_datasource.dart';
import '../../../../core/network/paginated_response.dart';
import '../models/officer_model.dart';

abstract class OfficerRemoteDataSource {
  Future<PaginatedResponse<OfficerModel>> getAll({
    String? status,
    String? search,
    int? perPage,
    int? page,
  });

  /// [branchId] — the org the officer actually belongs to.
  /// Branch-only officers 404 on root org; pass their branchId here.
  Future<OfficerModel> getById(String userId, {String? branchId});

  Future<OfficerModel> invite({
    required String email,
    required String orgRoleId,
    required String branchId,
    String? username,
    String? phone,
    String? appPassword,
    String? appPasswordConfirmation,
  });

  Future<OfficerModel> updateMembership(
    String userId, {
    String? orgRoleId,
    int? level,
    String? status,
    String? branchId,
  });

  Future<void> reassignBranch({
    required String userId,
    required String fromBranchId,
    required String toBranchId,
    required String orgRoleId,
  });

  Future<OfficerModel> suspend(String userId, {String? branchId});
  Future<OfficerModel> activate(String userId, {String? branchId});
  Future<void> suspendUser(String userId);
  Future<void> deactivateUser(String userId);
  Future<void> remove(String userId);
}

class OfficerRemoteDataSourceImpl extends BaseRemoteDataSource
    implements OfficerRemoteDataSource {
  final OrgContext _orgContext;

  OfficerRemoteDataSourceImpl({
    required Dio dio,
    required OrgContext orgContext,
  }) : _orgContext = orgContext,
       super(dio: dio);

  // ── LIST ──────────────────────────────────────────────────

  @override
  Future<PaginatedResponse<OfficerModel>> getAll({
    String? status,
    String? search,
    int? perPage,
    int? page,
  }) async {
    final orgId = _orgContext.effectiveOrgId;
    final params = <String, dynamic>{
      if (status != null) 'status': status,
      if (search != null) 'search': search,
      if (perPage != null) 'per_page': perPage,
      if (page != null) 'page': page,
    };
    return fetchPaginatedList(
      ApiPaths.orgs.members(orgId),
      OfficerModel.fromJson,
      queryParams: params.isNotEmpty ? params : null,
    );
  }

  // ── GET BY ID ─────────────────────────────────────────────
  // FIX 1: Use officer's actual branchId, not always the root org.
  // Officers who are branch-only members have no root membership row,
  // so GET /orgs/{rootOrgId}/members/{userId} returns 404 for them.
  // The list response includes branchId — callers pass it here.

  @override
  Future<OfficerModel> getById(String userId, {String? branchId}) async {
    final orgId = (branchId != null && branchId.isNotEmpty)
        ? branchId
        : _orgContext.effectiveOrgId;

    return fetchSingle(
      '${ApiPaths.orgs.members(orgId)}/$userId',
      OfficerModel.fromJson,
      dataKey: 'membership',
    );
  }

  // ── INVITE ────────────────────────────────────────────────

  @override
  Future<OfficerModel> invite({
    required String email,
    required String orgRoleId,
    required String branchId,
    String? username,
    String? phone,
    String? appPassword,
    String? appPasswordConfirmation,
  }) async {
    final response = await dio.post(
      '${ApiPaths.orgs.members(branchId)}/invite',
      data: {
        'email': email,
        if (username != null) 'username': username,
        if (phone != null) 'phone': phone,
        'org_role_id': orgRoleId,
        if (appPassword != null) 'app_password': appPassword,
        if (appPasswordConfirmation != null)
          'app_password_confirmation': appPasswordConfirmation,
      },
    );
    final body = response.data as Map<String, dynamic>? ?? {};
    final raw = body['membership'] ?? body['member'] ?? body['data'] ?? body;
    return OfficerModel.fromJson(raw as Map<String, dynamic>);
  }

  // ── UPDATE MEMBERSHIP ─────────────────────────────────────

  @override
  Future<OfficerModel> updateMembership(
    String userId, {
    String? orgRoleId,
    int? level,
    String? status,
    String? branchId,
  }) async {
    final orgId = (branchId != null && branchId.isNotEmpty)
        ? branchId
        : _orgContext.effectiveOrgId;

    return patchAndParse(
      ApiPaths.orgs.member(orgId, userId),
      {
        if (orgRoleId != null) 'org_role_id': orgRoleId,
        if (level != null) 'level': level,
        if (status != null) 'status': status,
      },
      OfficerModel.fromJson,
      dataKey: 'membership',
    );
  }

  // ── REASSIGN BRANCH ───────────────────────────────────────
  // FIX 2: Never delete the root-org membership.
  //
  // The backend /assign endpoint guard:
  //   "User must be an active member of the root organization first."
  //
  // The root membership is the anchor — it must stay alive so /assign
  // can validate it. Only the branch membership should be moved.
  //
  // Logic:
  //   • fromBranchId == rootOrgId → officer is at root level only,
  //     no branch row to delete; just /assign to new branch.
  //   • fromBranchId != rootOrgId → delete old branch row, /assign
  //     to new branch (root row is untouched → /assign passes guard).

  @override
  Future<void> reassignBranch({
    required String userId,
    required String fromBranchId,
    required String toBranchId,
    required String orgRoleId,
  }) async {
    final rootOrgId = _orgContext.rootOrgId ?? _orgContext.effectiveOrgId;

    // Step 1: Remove old branch membership — never touch root org.
    if (fromBranchId != rootOrgId) {
      await deleteResource(ApiPaths.orgs.member(fromBranchId, userId));
    }

    // Step 2: Assign to new branch.
    // /assign verifies root membership still active → succeeds.
    await dio.post(
      '${ApiPaths.orgs.members(toBranchId)}/assign',
      data: {'user_id': userId, 'org_role_id': orgRoleId},
    );
  }

  // ── SUSPEND / ACTIVATE ────────────────────────────────────

  @override
  Future<OfficerModel> suspend(String userId, {String? branchId}) =>
      updateMembership(userId, status: 'suspended', branchId: branchId);

  @override
  Future<OfficerModel> activate(String userId, {String? branchId}) =>
      updateMembership(userId, status: 'active', branchId: branchId);

  // ── PLATFORM-LEVEL ACTIONS ────────────────────────────────

  @override
  Future<void> suspendUser(String userId) async {
    await dio.patch(
      ApiPaths.admin.userStatus(userId),
      data: {'status': 'suspended'},
    );
  }

  @override
  Future<void> deactivateUser(String userId) async {
    await dio.patch(
      ApiPaths.admin.userStatus(userId),
      data: {'status': 'deactivated'},
    );
  }

  // ── REMOVE FROM ORG ───────────────────────────────────────

  @override
  Future<void> remove(String userId) async {
    final orgId = _orgContext.effectiveOrgId;
    await deleteResource(ApiPaths.orgs.member(orgId, userId));
  }
}
