// lib/features/officer/data/datasources/officer_remote_datasource.dart
//
// FIX 3 — Officer update fails + branch transfer broken
// ─────────────────────────────────────────────────────────────────────
// Root causes fixed here:
//
// A) updateMembership / activate / suspend used _orgContext.effectiveOrgId
//    (the root org) as the {orgId} segment.  The backend only stores the
//    membership on the specific *branch* the officer was assigned to, so
//    PATCH /api/v1/orgs/{rootOrgId}/members/{userId} returns 404.
//    Fix: accept an optional `branchId`; fall back to effectiveOrgId only
//    when no branchId is supplied (so callers that already know the branch
//    pass it explicitly).
//
// B) reassignBranch POSTed to /invite instead of /assign.
//    /invite requires an email address and dispatches an invitation email.
//    /assign accepts user_id directly and creates an active membership.
//    Fix: use /assign endpoint.
// ─────────────────────────────────────────────────────────────────────

import '../../../../core/network/api_paths.dart';
import '../../../../core/network/base_remote_datasource.dart';
import '../../../../core/network/paginated_response.dart';
import '../models/officer_model.dart';
import 'package:dio/dio.dart';
import '../../../../core/context/org_context.dart';

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

  /// [branchId] — the branch whose membership record to update.
  /// Must be the officer's actual branch, NOT the root org id.
  Future<OfficerModel> updateMembership(
    String userId, {
    String? orgRoleId,
    int? level,
    String? status,
    String? branchId, // ← FIX A: caller supplies officer's branchId
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

// ─────────────────────────────────────────────────────────────────────
// Implementation
// ─────────────────────────────────────────────────────────────────────

class OfficerRemoteDataSourceImpl extends BaseRemoteDataSource
    implements OfficerRemoteDataSource {
  final OrgContext _orgContext;

  OfficerRemoteDataSourceImpl({
    required Dio dio,
    required OrgContext orgContext,
  }) : _orgContext = orgContext,
       super(dio: dio);

  // ── GET ALL ──────────────────────────────────────────────

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
      'per_page': perPage ?? 200,
      if (page != null) 'page': page,
    };

    final raw = await fetchPaginatedList(
      ApiPaths.orgs.members(orgId),
      OfficerModel.fromJson,
      queryParams: params,
    );

    // Deduplicate by actorId — root-org query returns one row per
    // membership; users belonging to both root + branch appear twice.
    final Map<String, OfficerModel> byActor = {};
    for (final officer in raw.items) {
      final key = officer.actorId;
      if (key.isEmpty) continue;
      final existing = byActor[key];
      if (existing == null) {
        byActor[key] = officer;
      } else {
        if (officer.level > existing.level) {
          byActor[key] = officer;
        } else if (officer.level == existing.level &&
            officer.membershipStatus == 'active' &&
            existing.membershipStatus != 'active') {
          byActor[key] = officer;
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

  // ── UPDATE MEMBERSHIP ─────────────────────────────────────
  // FIX A: use officer's own branchId, NOT the root org id.

  @override
  Future<OfficerModel> updateMembership(
    String userId, {
    String? orgRoleId,
    int? level,
    String? status,
    String? branchId, // ← supplied by domain layer; never empty in practice
  }) async {
    // Use the officer's actual branch; fall back to root only if truly unknown.
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
  // FIX B: use /assign endpoint (not /invite).
  //   • /assign: accepts user_id, creates active membership immediately.
  //   • /invite: accepts email, sends invitation email — wrong for transfers.

  @override
  Future<void> reassignBranch({
    required String userId,
    required String fromBranchId,
    required String toBranchId,
    required String orgRoleId,
  }) async {
    // 1. Remove from current branch
    await deleteResource(ApiPaths.orgs.member(fromBranchId, userId));

    // 2. Assign directly to new branch (no invitation email sent)
    await dio.post(
      '${ApiPaths.orgs.members(toBranchId)}/assign',
      data: {'user_id': userId, 'org_role_id': orgRoleId},
    );
  }

  // ── SUSPEND / ACTIVATE ────────────────────────────────────
  // FIX A applied: accept branchId and forward to updateMembership.

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
