// rbac_extensions.dart
// ─────────────────────────────────────────────────────────────
// Extension methods on AuthAuthenticated for clean, readable
// role and permission checks anywhere in the UI layer.
//
// Usage:
//   final auth = context.read<AuthBloc>().state as AuthAuthenticated;
//   auth.can('users.view')          → bool
//   auth.hasRole('admin')           → bool
//   auth.canAny(['users.view', 'users.edit']) → bool
// ─────────────────────────────────────────────────────────────

import 'package:fca/features/auth/presentation/bloc/auth_state.dart';

extension RbacExtensions on AuthAuthenticated {
  // ── Permission checks ─────────────────────────────────────

  /// True if the active user has the given permission slug.
  bool can(String permissionSlug) =>
      activeSession.permissions.any((p) => p.slug == permissionSlug);

  /// True if the active user has ALL of the given permission slugs.
  bool canAll(List<String> slugs) => slugs.every((slug) => can(slug));

  /// True if the active user has ANY of the given permission slugs.
  bool canAny(List<String> slugs) => slugs.any((slug) => can(slug));

  // ── Role checks ───────────────────────────────────────────

  /// True if the active user has the given role slug.
  bool hasRole(String roleSlug) =>
      activeSession.user.roles.any((r) => r.slug == roleSlug);

  /// True if the active user has ANY of the given role slugs.
  bool hasAnyRole(List<String> slugs) => slugs.any((slug) => hasRole(slug));

  /// True if the active user has ALL of the given role slugs.
  bool hasAllRoles(List<String> slugs) => slugs.every((slug) => hasRole(slug));

  // ── Convenience shortcuts ─────────────────────────────────

  bool get isSuperAdmin => hasRole('super-admin');
  bool get isAdmin => hasRole('admin') || isSuperAdmin;
  bool get isManager => hasRole('manager') || isAdmin;
  bool get isSupport => hasRole('support') || isManager;
  bool get isUser => hasRole('user');

  /// True if user can access the admin dashboard.
  bool get canViewDashboard => isAdmin;

  /// User's display name from active session.
  String get displayName => activeSession.user.displayName;

  /// Primary role name for display.
  String get primaryRoleName => activeSession.user.primaryRole?.name ?? 'User';
}
