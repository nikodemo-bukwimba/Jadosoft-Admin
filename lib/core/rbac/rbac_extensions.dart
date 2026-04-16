// rbac_extensions.dart — ADMIN APP
// ─────────────────────────────────────────────────────────────
// FIX: isAdminAppRole now covers ALL org-management role slugs
// created by OrganizationService for Barick Pharmacy:
//   owner, org_admin, manager, staff, viewer (org roles)
//   branch_manager (branch-level admin)
//   super_admin, support_agent, billing_admin (platform staff)
//
// Without this fix, users with 'manager'/'staff' slugs were sent
// to /pending-activation because hasNoRole = true in the router.
// ─────────────────────────────────────────────────────────────

import 'package:jadosoft_admin/features/auth/presentation/bloc/auth_state.dart';

extension RbacExtensions on AuthAuthenticated {
  // ══════════════════════════════════════════════════════════
  // GATING — permission checks (primary mechanism for UI)
  // ══════════════════════════════════════════════════════════

  bool can(String permissionSlug) =>
      activeSession.permissions.any((p) => p.slug == permissionSlug);

  bool canAll(List<String> slugs) => slugs.every(can);
  bool canAny(List<String> slugs) => slugs.any(can);

  bool get canViewDashboard => can('dashboard.view');

  // ══════════════════════════════════════════════════════════
  // APP-TYPE ROUTING — role slug checks
  // Used ONLY by AppRouter._redirect(). Never use for UI gating.
  // ══════════════════════════════════════════════════════════

  String get _primarySlug =>
      activeSession.user.primaryRole?.slug.toLowerCase() ?? '';

  /// True if this role belongs in the ADMIN app.
  /// Covers every org-management role the backend creates:
  ///   - Custom org roles:   owner, org_admin, manager, staff, viewer
  ///   - Branch admin role:  branch_manager
  ///   - Platform staff:     super_admin, support_agent, billing_admin
  bool get isAdminAppRole =>
      // Exact matches for org roles created by OrganizationService
      _primarySlug == 'owner' ||
      _primarySlug == 'org_admin' ||
      _primarySlug == 'manager' ||
      _primarySlug == 'staff' ||
      _primarySlug == 'viewer' ||
      _primarySlug == 'branch_manager' ||
      // Platform staff role exact matches
      _primarySlug == 'super_admin' ||
      _primarySlug == 'support_agent' ||
      _primarySlug == 'billing_admin' ||
      _primarySlug == 'content_admin' ||
      // Partial matches for variant spellings / future roles
      _primarySlug.contains('admin') || // org_admin, branch_admin, super_admin
      _primarySlug.contains('manager') || // branch_manager, manager
      _primarySlug.contains('super') ||
      _primarySlug.contains('support') ||
      _primarySlug.contains('auditor') ||
      _primarySlug.contains('ops');

  /// True if this role belongs in the OFFICER app.
  /// Branch managers can also use the officer app.
  bool get isOfficerAppRole =>
      _primarySlug.contains('officer') ||
      _primarySlug == 'junior_officer' ||
      _primarySlug.contains('field') ||
      _primarySlug.contains('pharma_rep') ||
      _primarySlug.contains('sales_rep');

  // ══════════════════════════════════════════════════════════
  // DISPLAY — for labels/badges only. Never use for routing/gating.
  // ══════════════════════════════════════════════════════════

  bool hasRole(String roleName) =>
      activeSession.user.roles.any((r) => r.name == roleName);

  bool hasAnyRole(List<String> names) => names.any(hasRole);

  bool get isSuperAdmin => hasRole('super_admin');

  String get displayName => activeSession.user.displayName;

  String get primaryRoleName => activeSession.user.primaryRole?.name ?? 'User';

  int get permissionCount => activeSession.permissions.length;

  Set<String> get permissionSlugs =>
      activeSession.permissions.map((p) => p.slug).toSet();
}
