// officer_remote_datasource.dart
// Fix: dedup returned members by actorId so the customer form officer
// dropdown never receives two items with the same value (which causes
// the Flutter assertion "There should be exactly one item with value X").
//
// Root cause: GET /orgs/{rootOrgId}/members returns ALL members across
// the full org tree (root + all branches).  A user who is a member of
// both the root org AND a branch node appears twice in the list, each
// entry with the same actorId.  Flutter's DropdownButtonFormField
// requires every value to be unique — duplicates throw the assertion.
//
// Fix strategy:
//   1. Fetch the full list as before.
//   2. Deduplicate by actorId, keeping the entry with the higher level
//      (preferred) or, on tie, the one with membershipStatus == 'active'.
//   3. Return the deduplicated list wrapped in the same PaginatedResponse.

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

  Future<OfficerModel> getById(String userId);

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
  });

  Future<void> reassignBranch({
    required String userId,
    required String fromBranchId,
    required String toBranchId,
    required String orgRoleId,
  });

  Future<OfficerModel> suspend(String userId);

  Future<OfficerModel> activate(String userId);

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
      // Always fetch a large page so we don't miss members when deduping.
      'per_page': perPage ?? 200,
      if (page != null) 'page': page,
    };

    final raw = await fetchPaginatedList(
      ApiPaths.orgs.members(orgId),
      OfficerModel.fromJson,
      queryParams: params,
    );

    // ── Deduplicate by actorId ────────────────────────────
    // The org members endpoint for a root org returns ALL members of
    // every branch in the tree.  Users with multiple memberships
    // (root + branch) appear more than once with the same actorId.
    // Flutter DropdownButtonFormField requires unique values —
    // duplicates throw an assertion error at runtime.
    //
    // We keep the membership with the highest level, breaking ties by
    // preferring 'active' status, then by most recent createdAt.
    final Map<String, OfficerModel> byActor = {};
    for (final officer in raw.items) {
      final key = officer.actorId;
      if (key.isEmpty) continue;
      final existing = byActor[key];
      if (existing == null) {
        byActor[key] = officer;
      } else {
        // Prefer higher level
        if (officer.level > existing.level) {
          byActor[key] = officer;
        } else if (officer.level == existing.level) {
          // Prefer active membership status
          if (officer.membershipStatus == 'active' &&
              existing.membershipStatus != 'active') {
            byActor[key] = officer;
          }
        }
      }
    }

    final deduped = byActor.values.toList();
    return PaginatedResponse(
      items: deduped,
      currentPage: raw.currentPage,
      lastPage: raw.lastPage,
      total: deduped.length,
      perPage: raw.perPage,
    );
  }

  // ── GET BY ID ────────────────────────────────────────────

  @override
  Future<OfficerModel> getById(String userId) async {
    final orgId = _orgContext.effectiveOrgId;
    return fetchSingle(
      '${ApiPaths.orgs.members(orgId)}/$userId',
      OfficerModel.fromJson,
      dataKey: 'membership',
    );
  }

  // ── INVITE ───────────────────────────────────────────────

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

  // ── UPDATE MEMBERSHIP ────────────────────────────────────

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

  @override
  Future<void> reassignBranch({
    required String userId,
    required String fromBranchId,
    required String toBranchId,
    required String orgRoleId,
  }) async {
    await deleteResource(ApiPaths.orgs.member(fromBranchId, userId));
    await dio.post(
      '${ApiPaths.orgs.members(toBranchId)}/invite',
      data: {'user_id': userId, 'org_role_id': orgRoleId},
    );
  }

  // ── SUSPEND / ACTIVATE ───────────────────────────────────

  @override
  Future<OfficerModel> suspend(String userId) =>
      updateMembership(userId, status: 'suspended');

  @override
  Future<OfficerModel> activate(String userId) =>
      updateMembership(userId, status: 'active');

  // ── PLATFORM-LEVEL ACTIONS ───────────────────────────────

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

  // ── REMOVE FROM ORG ──────────────────────────────────────

  @override
  Future<void> remove(String userId) async {
    final orgId = _orgContext.effectiveOrgId;
    await deleteResource(ApiPaths.orgs.member(orgId, userId));
  }
}
