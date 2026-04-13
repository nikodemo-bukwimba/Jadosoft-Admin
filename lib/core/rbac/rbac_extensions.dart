// rbac_extensions.dart
import 'package:jadosoft_admin/features/auth/presentation/bloc/auth_state.dart';
// Officer app: change import package name to jadosoft_officer

extension RbacExtensions on AuthAuthenticated {
  // ══════════════════════════════════════════════════════════
  // GATING — permission checks (primary mechanism)
  // ══════════════════════════════════════════════════════════

  /// True if the active user has the given permission slug.
  /// Reads from the permissions list fetched from GET /auth/me at login.
  bool can(String permissionSlug) =>
      activeSession.permissions.any((p) => p.slug == permissionSlug);

  bool canAll(List<String> slugs) => slugs.every((slug) => can(slug));

  bool canAny(List<String> slugs) => slugs.any((slug) => can(slug));

  bool get canViewDashboard => can('dashboard.view');

  // ══════════════════════════════════════════════════════════
  // APP-TYPE ROUTING — role slug checks
  // Used ONLY by the router redirect to enforce app boundaries.
  // Never use these for UI show/hide — always use can() for that.
  // ══════════════════════════════════════════════════════════

  /// The primary role slug, lowercased. Empty string if no role assigned.
  String get _primarySlug =>
      activeSession.user.primaryRole?.slug.toLowerCase() ?? '';

  /// True if this account belongs to an admin-type role.
  /// Admin roles are allowed in the admin app only.
  bool get isAdminAppRole =>
      _primarySlug.contains('admin') ||
      _primarySlug.contains('super') ||
      _primarySlug.contains('support') ||
      _primarySlug.contains('auditor') ||
      _primarySlug.contains('ops') ||
      _primarySlug == 'owner' || // ADD
      _primarySlug == 'branch_manager';

  /// True if this account belongs to an officer-type role.
  /// Officer roles are allowed in the officer app only.
  bool get isOfficerAppRole =>
      _primarySlug.contains('officer') ||
      _primarySlug == 'junior_officer' || // ADD
      _primarySlug.contains('field') ||
      _primarySlug.contains('pharma_rep') ||
      _primarySlug.contains('sales_rep');

  // ══════════════════════════════════════════════════════════
  // DISPLAY — role checks (badge, label, greeting ONLY)
  // ⚠ NEVER use these for show/hide or routing.
  // ══════════════════════════════════════════════════════════

  bool hasRole(String roleName) =>
      activeSession.user.roles.any((r) => r.name == roleName);

  bool hasAnyRole(List<String> names) => names.any((name) => hasRole(name));

  bool get isSuperAdmin => hasRole('super_admin');

  String get displayName => activeSession.user.displayName;

  String get primaryRoleName => activeSession.user.primaryRole?.name ?? 'User';

  int get permissionCount => activeSession.permissions.length;

  Set<String> get permissionSlugs =>
      activeSession.permissions.map((p) => p.slug).toSet();
}
