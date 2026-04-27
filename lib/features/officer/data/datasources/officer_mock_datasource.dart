// officer_mock_datasource.dart
// ─────────────────────────────────────────────────────────────
// Mock implementation matching the new OfficerRemoteDataSource
// interface with org membership model.
//
// Mock data uses the new field names (userId, actorId, branchId,
// username, org_role_id, etc.) to match what the real API will
// return from GET /orgs/{orgId}/members.
// ─────────────────────────────────────────────────────────────

import '../../../../core/network/paginated_response.dart';
import '../models/officer_model.dart';
import 'officer_remote_datasource.dart';

class OfficerMockDataSource implements OfficerRemoteDataSource {
  static final List<Map<String, dynamic>> _store = [
    {
      'user_id': 'usr-001',
      'org_id': 'branch-mbeya',
      'org_role_id': 'role-field-officer',
      'level': 50,
      'status': 'active',
      'created_at': '2024-03-15T08:00:00.000Z',
      'user': {
        'id': 'usr-001',
        'username': 'celestine.msigwa',
        'email': 'celestine.msigwa@barickpharmacy.co.tz',
        'phone': '+255 754 321 001',
        'status': 'active',
        'actor_id': 'act-001',
      },
      'role': {'id': 'role-field-officer', 'name': 'Senior Marketing Officer'},
      'org': {'name': 'Mbeya Branch'},
    },
    {
      'user_id': 'usr-002',
      'org_id': 'branch-mbeya',
      'org_role_id': 'role-field-officer',
      'level': 40,
      'status': 'active',
      'created_at': '2024-06-01T09:00:00.000Z',
      'user': {
        'id': 'usr-002',
        'username': 'amina.mwakasege',
        'email': 'amina.mwakasege@barickpharmacy.co.tz',
        'phone': '+255 765 432 002',
        'status': 'active',
        'actor_id': 'act-002',
      },
      'role': {'id': 'role-field-officer', 'name': 'Marketing Officer'},
      'org': {'name': 'Mbeya Branch'},
    },
    {
      'user_id': 'usr-003',
      'org_id': 'branch-dar',
      'org_role_id': 'role-field-officer',
      'level': 40,
      'status': 'active',
      'created_at': '2024-08-20T10:00:00.000Z',
      'user': {
        'id': 'usr-003',
        'username': 'joseph.mwakyusa',
        'email': 'joseph.mwakyusa@barickpharmacy.co.tz',
        'phone': '+255 712 543 003',
        'status': 'active',
        'actor_id': 'act-003',
      },
      'role': {'id': 'role-field-officer', 'name': 'Marketing Officer'},
      'org': {'name': 'Dar es Salaam Branch'},
    },
    {
      'user_id': 'usr-004',
      'org_id': 'branch-mbeya',
      'org_role_id': 'role-junior',
      'level': 20,
      'status': 'suspended',
      'created_at': '2025-01-10T07:30:00.000Z',
      'user': {
        'id': 'usr-004',
        'username': 'grace.mwakalinga',
        'email': 'grace.mwakalinga@barickpharmacy.co.tz',
        'phone': '+255 783 654 004',
        'status': 'active',
        'actor_id': 'act-004',
      },
      'role': {'id': 'role-junior', 'name': 'Junior Marketing Officer'},
      'org': {'name': 'Mbeya Branch'},
    },
    {
      'user_id': 'usr-005',
      'org_id': 'branch-dar',
      'org_role_id': 'role-field-officer',
      'level': 40,
      'status': 'active',
      'created_at': '2023-11-05T11:00:00.000Z',
      'user': {
        'id': 'usr-005',
        'username': 'baraka.kileo',
        'email': 'baraka.kileo@barickpharmacy.co.tz',
        'phone': '+255 745 765 005',
        'status': 'deactivated',
        'actor_id': 'act-005',
      },
      'role': {'id': 'role-field-officer', 'name': 'Marketing Officer'},
      'org': {'name': 'Dar es Salaam Branch'},
    },
  ];

  static int _idCounter = 6;

  Future<void> _delay() => Future.delayed(const Duration(milliseconds: 300));

  // ── LIST ─────────────────────────────────────────────────

  @override
  Future<PaginatedResponse<OfficerModel>> getAll({
    String? status,
    String? search,
    int? perPage,
    int? page,
  }) async {
    await _delay();
    var filtered = List<Map<String, dynamic>>.from(_store);

    if (status != null) {
      filtered = filtered.where((e) => e['status'] == status).toList();
    }
    if (search != null && search.isNotEmpty) {
      final q = search.toLowerCase();
      filtered = filtered.where((e) {
        final user = e['user'] as Map<String, dynamic>? ?? {};
        final name = (user['username'] ?? '').toString().toLowerCase();
        final email = (user['email'] ?? '').toString().toLowerCase();
        return name.contains(q) || email.contains(q);
      }).toList();
    }

    final items = filtered.map((e) => OfficerModel.fromJson(e)).toList();
    return PaginatedResponse<OfficerModel>(
      items: items,
      currentPage: page ?? 1,
      lastPage: 1,
      total: items.length,
      perPage: perPage ?? 25,
    );
  }

  // ── GET BY ID ────────────────────────────────────────────

  @override
  Future<OfficerModel> getById(String userId) async {
    await _delay();
    final item = _store.firstWhere(
      (e) => e['user_id'] == userId,
      orElse: () => throw Exception('Officer not found'),
    );
    return OfficerModel.fromJson(item);
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
    await _delay();
    final id = _idCounter++;
    final userId = 'usr-${id.toString().padLeft(3, '0')}';
    final actorId = 'act-${id.toString().padLeft(3, '0')}';
    final newItem = {
      'user_id': userId,
      'org_id': branchId,
      'org_role_id': orgRoleId,
      'level': 40,
      'status': 'active',
      'created_at': DateTime.now().toIso8601String(),
      'user': {
        'id': userId,
        'username': username ?? email.split('@').first,
        'email': email,
        'phone': phone,
        'status': 'active',
        'actor_id': actorId,
      },
      'role': {'id': orgRoleId, 'name': 'Marketing Officer'},
      'org': {'name': 'Branch'},
    };
    _store.add(newItem);
    return OfficerModel.fromJson(newItem);
  }

  // ── UPDATE MEMBERSHIP ────────────────────────────────────

  @override
  Future<OfficerModel> updateMembership(
    String userId, {
    String? orgRoleId,
    int? level,
    String? status,
  }) async {
    await _delay();
    final index = _store.indexWhere((e) => e['user_id'] == userId);
    if (index == -1) throw Exception('Officer not found');
    if (orgRoleId != null) _store[index]['org_role_id'] = orgRoleId;
    if (level != null) _store[index]['level'] = level;
    if (status != null) _store[index]['status'] = status;
    return OfficerModel.fromJson(_store[index]);
  }

  // ── REASSIGN BRANCH ──────────────────────────────────────

  @override
  Future<void> reassignBranch({
    required String userId,
    required String fromBranchId,
    required String toBranchId,
    required String orgRoleId,
  }) async {
    await _delay();
    final index = _store.indexWhere((e) => e['user_id'] == userId);
    if (index == -1) throw Exception('Officer not found');
    _store[index]['org_id'] = toBranchId;
    _store[index]['org_role_id'] = orgRoleId;
  }

  // ── TRANSITIONS (org-level) ──────────────────────────────

  @override
  Future<OfficerModel> suspend(String userId) =>
      updateMembership(userId, status: 'suspended');

  @override
  Future<OfficerModel> activate(String userId) =>
      updateMembership(userId, status: 'active');

  // ── TRANSITIONS (platform-level) ─────────────────────────

  @override
  Future<void> suspendUser(String userId) async {
    await _delay();
    final index = _store.indexWhere((e) => e['user_id'] == userId);
    if (index == -1) throw Exception('Officer not found');
    final user = Map<String, dynamic>.from(
      _store[index]['user'] as Map<String, dynamic>,
    );
    user['status'] = 'suspended';
    _store[index]['user'] = user;
  }

  @override
  Future<void> deactivateUser(String userId) async {
    await _delay();
    final index = _store.indexWhere((e) => e['user_id'] == userId);
    if (index == -1) throw Exception('Officer not found');
    final user = Map<String, dynamic>.from(
      _store[index]['user'] as Map<String, dynamic>,
    );
    user['status'] = 'deactivated';
    _store[index]['user'] = user;
  }

  // ── REMOVE ───────────────────────────────────────────────

  @override
  Future<void> remove(String userId) async {
    await _delay();
    _store.removeWhere((e) => e['user_id'] == userId);
  }
}
