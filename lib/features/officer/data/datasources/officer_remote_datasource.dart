// officer_remote_datasource.dart
// ─────────────────────────────────────────────────────────────
// Real API datasource for officer management.
//
// Officers are a COMPOSITE in HMSCP. This datasource orchestrates:
//   - GET /orgs/{orgId}/members → list officers
//   - PATCH /orgs/{orgId}/members/{userId} → update role/status
//   - DELETE /orgs/{orgId}/members/{userId} → remove from org
//   - PATCH /admin/users/{id}/status → suspend/deactivate at platform level
//   - POST /orgs/{orgId}/members/invite → MISSING (not yet in API)
//
// Requires OrgContext for org/branch scoping.
// ─────────────────────────────────────────────────────────────

import 'package:dio/dio.dart';
import '../../../../core/context/org_context.dart';
import '../../../../core/network/api_paths.dart';
import '../../../../core/network/base_remote_datasource.dart';
import '../../../../core/network/paginated_response.dart';
import '../models/officer_model.dart';

abstract class OfficerRemoteDataSource {
  /// List officers (org members) for the active org/branch.
  Future<PaginatedResponse<OfficerModel>> getAll({
    String? status,
    String? search,
    int? perPage,
    int? page,
  });

  /// Get a single officer's membership details.
  Future<OfficerModel> getById(String userId);

  /// Invite/add a new officer to the org with a role.
  /// NOTE: Endpoint may not exist yet — see MISSING ENDPOINTS.
  Future<OfficerModel> invite({
    required String email,
    required String orgRoleId,
    required String branchId,
    String? username,
    String? phone,
  });

  /// Update an officer's membership (role, level, status).
  Future<OfficerModel> updateMembership(
    String userId, {
    String? orgRoleId,
    int? level,
    String? status,
  });

  /// Reassign officer to a different branch.
  /// This removes from current branch and adds to new branch.
  Future<void> reassignBranch({
    required String userId,
    required String fromBranchId,
    required String toBranchId,
    required String orgRoleId,
  });

  /// Suspend officer at org membership level.
  Future<OfficerModel> suspend(String userId);

  /// Activate (unsuspend) officer at org membership level.
  Future<OfficerModel> activate(String userId);

  /// Suspend user at platform level (affects all orgs).
  Future<void> suspendUser(String userId);

  /// Deactivate user at platform level (permanent).
  Future<void> deactivateUser(String userId);

  /// Remove officer from the org entirely.
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

  // ── LIST ─────────────────────────────────────────────────

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

  // ── GET BY ID ────────────────────────────────────────────
  // The API returns a single membership via the members list.
  // There is no GET /orgs/{orgId}/members/{userId} documented,
  // so we fetch the list filtered or use the detail from the list.
  // If the API adds a single-member endpoint, swap here.

  @override
  Future<OfficerModel> getById(String userId) async {
    final orgId = _orgContext.effectiveOrgId;
    return fetchSingle(
      '${ApiPaths.orgs.members(orgId)}/$userId',
      OfficerModel.fromJson,
      dataKey: 'membership',
    );
  }

  // ── INVITE (Add new officer) ─────────────────────────────
  // ENDPOINT: POST /orgs/{orgId}/members/invite
  // STATUS: MISSING IN API — needs to be built by API team.
  //
  // Expected request:
  //   { email, username, phone, org_role_id, branch_id }
  // Expected response:
  //   { message: "Member invited.", membership: { ... } }

  @override
  Future<OfficerModel> invite({
    required String email,
    required String orgRoleId,
    required String branchId,
    String? username,
    String? phone,
  }) async {
    final response = await dio.post(
      '${ApiPaths.orgs.members(branchId)}/invite',
      data: {
        'email': email,
        if (username != null) 'username': username,
        if (phone != null) 'phone': phone,
        'org_role_id': orgRoleId,
      },
    );
    final body = response.data as Map<String, dynamic>? ?? {};
    // Try all known response key variants
    final raw = body['membership'] ?? body['member'] ?? body['data'] ?? body;
    return OfficerModel.fromJson(raw as Map<String, dynamic>);
  }

  // ── UPDATE MEMBERSHIP ────────────────────────────────────
  // ENDPOINT: PATCH /orgs/{orgId}/members/{userId}

  @override
  Future<OfficerModel> updateMembership(
    String userId, {
    String? orgRoleId,
    int? level,
    String? status,
  }) async {
    final orgId = _orgContext.effectiveOrgId;
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

  // ── REASSIGN BRANCH ──────────────────────────────────────
  // Two-step: remove from old branch, add to new branch.
  // ENDPOINT: DELETE /orgs/{fromBranchId}/members/{userId}
  //           POST /orgs/{toBranchId}/members/invite (or add)
  //
  // NOTE: This may need a dedicated API endpoint for atomic transfer.
  // For now, implemented as two calls. Ask API team if they can
  // provide POST /orgs/{orgId}/members/{userId}/transfer.

  @override
  Future<void> reassignBranch({
    required String userId,
    required String fromBranchId,
    required String toBranchId,
    required String orgRoleId,
  }) async {
    // Step 1: Remove from current branch
    await deleteResource(ApiPaths.orgs.member(fromBranchId, userId));

    // Step 2: Add to new branch (using invite endpoint)
    // This re-adds the existing user to the new branch org.
    await dio.post(
      '${ApiPaths.orgs.members(toBranchId)}/invite',
      data: {'user_id': userId, 'org_role_id': orgRoleId},
    );
  }

  // ── SUSPEND (org membership level) ───────────────────────
  // ENDPOINT: PATCH /orgs/{orgId}/members/{userId} with status: suspended

  @override
  Future<OfficerModel> suspend(String userId) =>
      updateMembership(userId, status: 'suspended');

  // ── ACTIVATE (org membership level) ──────────────────────
  // ENDPOINT: PATCH /orgs/{orgId}/members/{userId} with status: active

  @override
  Future<OfficerModel> activate(String userId) =>
      updateMembership(userId, status: 'active');

  // ── SUSPEND USER (platform level) ────────────────────────
  // ENDPOINT: PATCH /admin/users/{id}/status
  // This suspends the user across ALL orgs.

  @override
  Future<void> suspendUser(String userId) async {
    await dio.patch(
      ApiPaths.admin.userStatus(userId),
      data: {'status': 'suspended'},
    );
  }

  // ── DEACTIVATE USER (platform level) ─────────────────────
  // ENDPOINT: PATCH /admin/users/{id}/status
  // Permanent deactivation — user can no longer log in.

  @override
  Future<void> deactivateUser(String userId) async {
    await dio.patch(
      ApiPaths.admin.userStatus(userId),
      data: {'status': 'deactivated'},
    );
  }

  // ── REMOVE FROM ORG ──────────────────────────────────────
  // ENDPOINT: DELETE /orgs/{orgId}/members/{userId}

  @override
  Future<void> remove(String userId) async {
    final orgId = _orgContext.effectiveOrgId;
    await deleteResource(ApiPaths.orgs.member(orgId, userId));
  }
}
