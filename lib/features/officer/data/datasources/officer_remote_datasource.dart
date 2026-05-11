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
  Future<OfficerModel> getById(String userId, {String? branchId});

  /// Problem #2 fix: creates a fully active User account immediately.
  /// No invitation email — the officer can log in with [password].
  ///
  /// Always creates:
  ///   1. A root org membership (required anchor for future transfers)
  ///   2. A branch membership if [branchId] != rootOrgId
  Future<OfficerModel> create({
    required String fullName,
    required String email,
    required String password,
    required String passwordConfirmation,
    String? phone,
    required String branchId,
    required String orgRoleId,
    int? level,
  });

  Future<OfficerModel> updateMembership(
    String userId, {
    String? orgRoleId,
    int? level,
    String? status,
    String? branchId,
  });

  /// Problem #3 fix: safe branch transfer that never deletes root membership.
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

  // ── CREATE WITH ACCOUNT ───────────────────────────────────
  //
  // Problem #2 fix: calls POST /orgs/{rootOrgId}/officers
  //
  // The backend:
  //   1. Creates User + Actor (actor.display_name = fullName)
  //   2. Creates root org membership (so login + transfer both work)
  //   3. Creates branch membership (if branchId != rootOrgId)
  //   4. Returns the officer JSON with 'name' = actor.display_name
  //
  // The officer receives their credentials out-of-band (e.g. SMS/WhatsApp)
  // and can log in immediately — no invitation acceptance step.

  @override
  Future<OfficerModel> create({
    required String fullName,
    required String email,
    required String password,
    required String passwordConfirmation,
    String? phone,
    required String branchId,
    required String orgRoleId,
    int? level,
  }) async {
    final rootOrgId = _orgContext.rootOrgId ?? _orgContext.effectiveOrgId;

    final response = await dio.post(
      ApiPaths.orgs.officers(rootOrgId),
      data: {
        'full_name': fullName,
        'email': email,
        'password': password,
        'password_confirmation': passwordConfirmation,
        if (phone != null && phone.isNotEmpty) 'phone': phone,
        'org_role_id': orgRoleId,
        if (level != null) 'level': level,
        // Only send branch_id when it differs from root org;
        // otherwise the backend only creates the root membership.
        if (branchId != rootOrgId) 'branch_id': branchId,
      },
    );

    final body = response.data as Map<String, dynamic>? ?? {};
    final raw = body['officer'] ?? body['member'] ?? body['data'] ?? body;
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
  //
  // Problem #3 fix: calls POST /orgs/{rootOrgId}/officers/{userId}/transfer
  //
  // The backend handles all the edge cases:
  //   - Self-heals missing root membership if it somehow doesn't exist
  //   - Only removes the branch membership (never root)
  //   - Creates new branch membership inheriting level from root

  @override
  Future<void> reassignBranch({
    required String userId,
    required String fromBranchId,
    required String toBranchId,
    required String orgRoleId,
  }) async {
    final rootOrgId = _orgContext.rootOrgId ?? _orgContext.effectiveOrgId;

    await dio.post(
      ApiPaths.orgs.officerTransfer(rootOrgId, userId),
      data: {
        'from_branch_id': fromBranchId,
        'to_branch_id': toBranchId,
        'org_role_id': orgRoleId,
      },
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
