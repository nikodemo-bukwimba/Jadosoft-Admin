// FILE: lib/core/context/org_context.dart
// CHANGE: One getter added — isBranchScopedUser.
//         Everything else unchanged (no structural changes).
//         Only the section below the isFieldOfficer getter is shown;
//         paste it in that spot, or apply the diff below.
//
// ── DIFF (find → replace) ────────────────────────────────────────────
//
// FIND (existing line):
//   bool get isFieldOfficer => _orgRole == OrgRole.fieldOfficer;
//
// REPLACE WITH:
//   bool get isFieldOfficer => _orgRole == OrgRole.fieldOfficer;
//
//   /// True when the user is always scoped to a single branch.
//   /// Field officers and branch admins never see the all-branches view.
//   bool get isBranchScopedUser => isBranchAdmin || isFieldOfficer;
//
// ─────────────────────────────────────────────────────────────────────
//
// Full file shown below for reference (no other lines changed):

import '../storage/secure_storage_service.dart';

enum OrgRole { orgAdmin, branchAdmin, fieldOfficer, unknown }

class OrgStatuses {
  static const pendingApproval = 'pending_approval';
  static const active = 'active';
}

class OrgContext {
  final SecureStorageService _storage;

  static const String _rootOrgIdKey = 'root_org_id';
  static const String _rootOrgNameKey = 'root_org_name';
  static const String _kOrgStatus = 'org_status';
  static const String _activeBranchIdKey = 'active_branch_id';
  static const String _activeBranchNameKey = 'active_branch_name';
  static const String _orgRoleKey = 'org_role';
  static const String _actorIdKey = 'actor_id';
  static const String _actorNameKey = 'actor_name';

  String? _rootOrgId;
  String? _rootOrgName;
  String? _orgStatus;
  String? _activeBranchId;
  String? _activeBranchName;
  OrgRole _orgRole = OrgRole.unknown;
  String? _actorId;
  String? _actorName;

  OrgContext({required SecureStorageService storage}) : _storage = storage;

  // ── Getters ──────────────────────────────────────────────────────

  String? get rootOrgId => _rootOrgId;
  String? get rootOrgName => _rootOrgName;
  String? get orgStatus => _orgStatus;
  bool get isOrgPendingApproval => _orgStatus == OrgStatuses.pendingApproval;
  bool get isOrgActive => _orgStatus == OrgStatuses.active;
  String? get activeBranchId => _activeBranchId;
  String? get activeBranchName => _activeBranchName;
  OrgRole get orgRole => _orgRole;
  bool get isOrgAdmin => _orgRole == OrgRole.orgAdmin;
  bool get isBranchAdmin => _orgRole == OrgRole.branchAdmin;
  bool get isFieldOfficer => _orgRole == OrgRole.fieldOfficer;

  // ── NEW ───────────────────────────────────────────────────────────
  /// True when the user is always scoped to a single branch.
  /// Field officers and branch admins never see the all-branches view.
  bool get isBranchScopedUser => isBranchAdmin || isFieldOfficer;
  // ─────────────────────────────────────────────────────────────────

  bool get hasOrg => _rootOrgId != null && _rootOrgId!.isNotEmpty;
  bool get hasBranch => _activeBranchId != null && _activeBranchId!.isNotEmpty;
  bool get isViewingAllBranches => isOrgAdmin && !hasBranch;

  String? get actorId => _actorId;
  String? get actorName => _actorName;

  String get effectiveOrgId {
    if (_activeBranchId != null && _activeBranchId!.isNotEmpty) {
      return _activeBranchId!;
    }
    return requireRootOrgId();
  }

  String requireRootOrgId() {
    if (_rootOrgId == null || _rootOrgId!.isEmpty) {
      throw StateError(
        'OrgContext.requireRootOrgId() called but no org is set. '
        'Ensure the auth flow sets the org after login.',
      );
    }
    return _rootOrgId!;
  }

  // ── Setters ───────────────────────────────────────────────────────

  Future<void> setRootOrg({
    required String id,
    required String name,
    required OrgRole role,
    String? actorId,
    String? actorName,
  }) async {
    _rootOrgId = id;
    _rootOrgName = name;
    _orgRole = role;
    _actorId = actorId;
    _actorName = actorName;

    await _storage.write(_rootOrgIdKey, id);
    await _storage.write(_rootOrgNameKey, name);
    await _storage.write(_orgRoleKey, role.name);

    if (actorId != null) await _storage.write(_actorIdKey, actorId);
    if (actorName != null) await _storage.write(_actorNameKey, actorName);
  }

  Future<void> setOrgStatus(String? status) async {
    _orgStatus = status;
    if (status != null) {
      await _storage.write(_kOrgStatus, status);
    } else {
      await _storage.delete(_kOrgStatus);
    }
  }

  Future<void> switchBranch({String? branchId, String? branchName}) async {
    _activeBranchId = branchId;
    _activeBranchName = branchName;

    if (branchId != null) {
      await _storage.write(_activeBranchIdKey, branchId);
      if (branchName != null) {
        await _storage.write(_activeBranchNameKey, branchName);
      }
    } else {
      await _storage.delete(_activeBranchIdKey);
      await _storage.delete(_activeBranchNameKey);
    }
  }

  Future<void> restore() async {
    _rootOrgId = await _storage.read(_rootOrgIdKey);
    _rootOrgName = await _storage.read(_rootOrgNameKey);
    _activeBranchId = await _storage.read(_activeBranchIdKey);
    _activeBranchName = await _storage.read(_activeBranchNameKey);
    _actorId = await _storage.read(_actorIdKey);
    _actorName = await _storage.read(_actorNameKey);
    _orgStatus = await _storage.read(_kOrgStatus);

    final roleStr = await _storage.read(_orgRoleKey);
    _orgRole = OrgRole.values.firstWhere(
      (r) => r.name == roleStr,
      orElse: () => OrgRole.unknown,
    );
  }

  Future<void> clear() async {
    _rootOrgId = null;
    _rootOrgName = null;
    _orgStatus = null;
    _activeBranchId = null;
    _activeBranchName = null;
    _orgRole = OrgRole.unknown;
    _actorId = null;
    _actorName = null;

    await _storage.delete(_actorIdKey);
    await _storage.delete(_actorNameKey);
    await _storage.delete(_rootOrgIdKey);
    await _storage.delete(_rootOrgNameKey);
    await _storage.delete(_kOrgStatus);
    await _storage.delete(_activeBranchIdKey);
    await _storage.delete(_activeBranchNameKey);
    await _storage.delete(_orgRoleKey);
  }

  String get displayLabel {
    final root = _rootOrgName ?? 'Organization';
    if (hasBranch) return '$root > ${_activeBranchName ?? 'Branch'}';
    if (isOrgAdmin) return '$root (All Branches)';
    return root;
  }
}
