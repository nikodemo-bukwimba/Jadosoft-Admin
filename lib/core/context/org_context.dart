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

  /// Unknown — fallback until /auth/me provides membership data.
  unknown,
}

class OrgContext {
  final SecureStorageService _storage;

  static const String _rootOrgIdKey = 'root_org_id';
  static const String _rootOrgNameKey = 'root_org_name';
  static const String _activeBranchIdKey = 'active_branch_id';
  static const String _activeBranchNameKey = 'active_branch_name';
  static const String _orgRoleKey = 'org_role';

  String? _rootOrgId;
  String? _rootOrgName;
  String? _activeBranchId;
  String? _activeBranchName;
  OrgRole _orgRole = OrgRole.unknown;

  OrgContext({required SecureStorageService storage}) : _storage = storage;

  // ── Getters ──────────────────────────────────────────────

  /// Root organisation ID (Barick Pharmacy).
  String? get rootOrgId => _rootOrgId;

  /// Root organisation display name.
  String? get rootOrgName => _rootOrgName;

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

  /// Whether any org is set.
  bool get hasOrg => _rootOrgId != null && _rootOrgId!.isNotEmpty;

  /// Whether a specific branch is selected.
  bool get hasBranch => _activeBranchId != null && _activeBranchId!.isNotEmpty;

  /// Whether viewing all branches (org admin, no branch filter).
  bool get isViewingAllBranches => isOrgAdmin && !hasBranch;

  /// The org ID to use for org-scoped API calls.
  ///
  /// - If a branch is selected → returns the branch ID
  ///   (API scopes data to that branch)
  /// - If no branch selected (org admin "all" view) → returns root org ID
  ///   (API returns data across all branches under root)
  ///
  /// This is the value you pass to:
  ///   ApiPaths.pharma.customers(effectiveOrgId)
  ///   ApiPaths.commerce.orders(effectiveOrgId)
  String get effectiveOrgId {
    if (_activeBranchId != null && _activeBranchId!.isNotEmpty) {
      return _activeBranchId!;
    }
    return requireRootOrgId();
  }

  /// Root org ID — throws if not set.
  /// Use for org-level resources: products catalog, roles, settings.
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
  }) async {
    _rootOrgId = id;
    _rootOrgName = name;
    _orgRole = role;
    await _storage.write(_rootOrgIdKey, id);
    await _storage.write(_rootOrgNameKey, name);
    await _storage.write(_orgRoleKey, role.name);
  }

  /// Switches active branch (org admin filtering).
  /// Pass null to go back to "all branches" view.
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
    _activeBranchId = null;
    _activeBranchName = null;
    _orgRole = OrgRole.unknown;
    await _storage.delete(_rootOrgIdKey);
    await _storage.delete(_rootOrgNameKey);
    await _storage.delete(_activeBranchIdKey);
    await _storage.delete(_activeBranchNameKey);
    await _storage.delete(_orgRoleKey);
  }

  /// Display label for current view context.
  /// Used in app bar: "Barick Pharmacy" or "Barick Pharmacy > Mbeya Branch"
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
