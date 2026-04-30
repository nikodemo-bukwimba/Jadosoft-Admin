// org_context.dart
// ─────────────────────────────────────────────────────────────
// Holds the currently-active organisation + branch context.
//
// BUSINESS RULES:
//   - Org admin sees root org + all branches (can filter by branch)
//   - Branch admin sees only their assigned branch
//   - activeBranchId = null means "all branches" (org admin view)
//   - activeBranchId = specific ID means "viewing one branch"
//
// APPROVAL CHAIN:
//   - Branch admin approves first (plans, reports)
//   - Org admin can override any branch admin decision
//
// CUSTOMER SCOPE:
//   - Customer belongs to a branch (stays on officer transfer)
//   - Same customer can be served at any branch with same reference
//   - Customer is NOT duplicated across branches
//
// PRODUCT SCOPE:
//   - Catalog is org-level (root org owns all products)
//   - Branches select which products they carry
//   - If branch hasn't selected, their users see full org catalog
//
// USAGE IN DATASOURCES:
//   final orgId = _orgContext.effectiveOrgId;
//   // Returns activeBranchId if set, otherwise rootOrgId
//   // This controls which org's data the API returns
//
//   final rootId = _orgContext.requireRootOrgId();
//   // Always the root — use for org-level resources (products, catalog)
// ─────────────────────────────────────────────────────────────

import '../storage/secure_storage_service.dart';

/// Role of the current user within the org hierarchy.
enum OrgRole {
  /// Manages root org + all branches. Can override branch admin decisions.
  orgAdmin,

  /// Manages one branch only. Approves plans/reports for branch officers.
  branchAdmin,

  fieldOfficer,

  /// Unknown — fallback until /auth/me provides membership data.
  unknown,
}

/// Centralized org status values (prevents string drift).
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
  String? _orgStatus; // ✅ NEW
  String? _activeBranchId;
  String? _activeBranchName;
  OrgRole _orgRole = OrgRole.unknown;
  String? _actorId;
  String? _actorName;

  OrgContext({required SecureStorageService storage}) : _storage = storage;

  // ── Getters ──────────────────────────────────────────────

  /// Root organisation ID (Barick Pharmacy).
  String? get rootOrgId => _rootOrgId;

  /// Root organisation display name.
  String? get rootOrgName => _rootOrgName;

  /// Org lifecycle status (pending_approval, active, etc.)
  String? get orgStatus => _orgStatus;

  bool get isOrgPendingApproval => _orgStatus == OrgStatuses.pendingApproval;

  bool get isOrgActive => _orgStatus == OrgStatuses.active;

  /// Currently selected branch, or null = "all branches" view.
  String? get activeBranchId => _activeBranchId;

  /// Currently selected branch name.
  String? get activeBranchName => _activeBranchName;

  /// Current user's role in the org hierarchy.
  OrgRole get orgRole => _orgRole;

  /// Whether the user is an org-level admin.
  bool get isOrgAdmin => _orgRole == OrgRole.orgAdmin;

  /// Whether the user is a branch-level admin.
  bool get isBranchAdmin => _orgRole == OrgRole.branchAdmin;

  bool get isFieldOfficer => _orgRole == OrgRole.fieldOfficer;

  /// Whether any org is set.
  bool get hasOrg => _rootOrgId != null && _rootOrgId!.isNotEmpty;

  /// Whether a specific branch is selected.
  bool get hasBranch => _activeBranchId != null && _activeBranchId!.isNotEmpty;

  /// Whether viewing all branches (org admin, no branch filter).
  bool get isViewingAllBranches => isOrgAdmin && !hasBranch;

  String? get actorId => _actorId;
  String? get actorName => _actorName;

  /// The org ID to use for org-scoped API calls.
  String get effectiveOrgId {
    if (_activeBranchId != null && _activeBranchId!.isNotEmpty) {
      return _activeBranchId!;
    }
    return requireRootOrgId();
  }

  /// Root org ID — throws if not set.
  String requireRootOrgId() {
    if (_rootOrgId == null || _rootOrgId!.isEmpty) {
      throw StateError(
        'OrgContext.requireRootOrgId() called but no org is set. '
        'Ensure the auth flow sets the org after login.',
      );
    }
    return _rootOrgId!;
  }

  // ── Setters ──────────────────────────────────────────────

  /// Sets the root org after login. Called once per session.
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

    if (actorId != null) {
      await _storage.write(_actorIdKey, actorId);
    }
    if (actorName != null) {
      await _storage.write(_actorNameKey, actorName);
    }
  }

  /// Sets org lifecycle status (pending_approval, active, etc.)
  Future<void> setOrgStatus(String? status) async {
    _orgStatus = status;

    if (status != null) {
      await _storage.write(_kOrgStatus, status);
    } else {
      await _storage.delete(_kOrgStatus);
    }
  }

  /// Switches active branch (org admin filtering).
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

  /// Restores context from secure storage (call on app startup).
  Future<void> restore() async {
    _rootOrgId = await _storage.read(_rootOrgIdKey);
    _rootOrgName = await _storage.read(_rootOrgNameKey);
    _activeBranchId = await _storage.read(_activeBranchIdKey);
    _activeBranchName = await _storage.read(_activeBranchNameKey);
    _actorId = await _storage.read(_actorIdKey);
    _actorName = await _storage.read(_actorNameKey);

    _orgStatus = await _storage.read(_kOrgStatus); // ✅ NEW

    final roleStr = await _storage.read(_orgRoleKey);
    _orgRole = OrgRole.values.firstWhere(
      (r) => r.name == roleStr,
      orElse: () => OrgRole.unknown,
    );
  }

  /// Clears all context (call on logout).
  Future<void> clear() async {
    _rootOrgId = null;
    _rootOrgName = null;
    _orgStatus = null; // ✅ NEW
    _activeBranchId = null;
    _activeBranchName = null;
    _orgRole = OrgRole.unknown;
    _actorId = null;
    _actorName = null;

    await _storage.delete(_actorIdKey);
    await _storage.delete(_actorNameKey);
    await _storage.delete(_rootOrgIdKey);
    await _storage.delete(_rootOrgNameKey);
    await _storage.delete(_kOrgStatus); // ✅ NEW
    await _storage.delete(_activeBranchIdKey);
    await _storage.delete(_activeBranchNameKey);
    await _storage.delete(_orgRoleKey);
  }

  /// Display label for current view context.
  String get displayLabel {
    final root = _rootOrgName ?? 'Organization';

    if (hasBranch) {
      return '$root > ${_activeBranchName ?? 'Branch'}';
    }

    if (isOrgAdmin) {
      return '$root (All Branches)';
    }

    return root;
  }
}
