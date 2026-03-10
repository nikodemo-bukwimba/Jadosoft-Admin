// rbac_extensions.dart
// ─────────────────────────────────────────────────────────────
// Extension methods on AuthAuthenticated.
//
// TWO SEPARATE CONCERNS:
//
//   1. GATING (show/hide, enable/disable)
//      → Use can() / canAny() / canAll() with PERMISSION slugs.
//      Permission slugs match the backend's PlatformPermissionSeeder.
//      Convention: 'module.action' (e.g. 'dashboard.view')
//
//   2. DISPLAY (badge color, label, greeting)
//      → Use hasRole() / primaryRoleName with ROLE names.
//      Role names match the backend's platform_roles.name column.
//
// Generator integration:
//   feature.config.json declares "permission": "actor_types"
//   Generator wires: auth.can('actor_types.view')
//   No Dart code changes needed when adding features.
// ─────────────────────────────────────────────────────────────

import 'package:admin_panel/features/auth/presentation/bloc/auth_state.dart';

extension RbacExtensions on AuthAuthenticated {
  // ═════════════════════════════════════════════════════════════
  // GATING — permission checks (primary mechanism)
  // ═════════════════════════════════════════════════════════════

  /// True if the active user has the given permission slug.
  bool can(String permissionSlug) =>
      activeSession.permissions.any((p) => p.slug == permissionSlug);

  /// True if the active user has ALL of the given permission slugs.
  bool canAll(List<String> slugs) => slugs.every((slug) => can(slug));

  /// True if the active user has ANY of the given permission slugs.
  bool canAny(List<String> slugs) => slugs.any((slug) => can(slug));

  /// True if user can access the admin dashboard.
  /// Permission slug 'dashboard.view' is defined in PlatformPermissionSeeder.
  bool get canViewDashboard => can('dashboard.view');

  // ═════════════════════════════════════════════════════════════
  // DISPLAY — role checks (badge, label, greeting ONLY)
  //
  // ⚠ NEVER use these for show/hide or enable/disable logic.
  //   Use can() with a permission slug instead.
  //
  // Role names below match platform_roles.name from the backend
  // seeder (super_admin, support_agent, auditor, platform_ops).
  // ═════════════════════════════════════════════════════════════

  /// True if the active user has a role with the given name.
  /// FOR DISPLAY ONLY — badge color, role label, greeting text.
  bool hasRole(String roleName) =>
      activeSession.user.roles.any((r) => r.name == roleName);

  /// True if the active user has ANY of the given role names.
  bool hasAnyRole(List<String> names) => names.any((name) => hasRole(name));

  /// True if user holds the super_admin platform role.
  /// FOR DISPLAY ONLY — e.g. dashboard shows different badge color.
  bool get isSuperAdmin => hasRole('super_admin');

  /// User's display name from active session.
  String get displayName => activeSession.user.displayName;

  /// Primary role name for display (greeting, badge).
  String get primaryRoleName => activeSession.user.primaryRole?.name ?? 'User';

  /// Total permission count — useful for debug/profile pages.
  int get permissionCount => activeSession.permissions.length;

  /// All permission slugs as a flat set — useful for bulk checks.
  Set<String> get permissionSlugs =>
      activeSession.permissions.map((p) => p.slug).toSet();
}
