// user_entity.dart
// ─────────────────────────────────────────────────────────────
// Pure Dart — zero Flutter or Drift imports.
// Shape mirrors the Laravel API /user and toApiArray() response.
//
// CHANGE: Added orgStatus and orgName from /auth/me response so the
// app can distinguish:
//   null              → no membership yet (pending activation)
//   'pending_approval'→ org exists but not yet admin-approved
//   'active'          → fully operational
//   'suspended'/'rejected' → org not usable
// ─────────────────────────────────────────────────────────────

class RoleEntity {
  final String id;
  final String name;
  final String slug;
  const RoleEntity({required this.id, required this.name, required this.slug});
}

class PermissionEntity {
  final String id;
  final String name;
  final String slug;
  const PermissionEntity({
    required this.id,
    required this.name,
    required this.slug,
  });
}

class UserEntity {
  final String id;
  final String? actorId;
  final String name;
  final String email;
  final String? phone;
  final bool isActive;
  final DateTime? emailVerifiedAt;
  final RoleEntity? primaryRole;
  final List<RoleEntity> roles;
  final bool hasActiveSubscription;
  final String subscriptionStatus;
  final DateTime? createdAt;

  // ── Org context fields from /auth/me ─────────────────────
  /// The org_status returned by the server for the resolved membership.
  /// null means the user has no active membership at all.
  final String? orgStatus;

  /// The name of the resolved org node (for display during pending state).
  final String? orgName;
  final String? orgId;

  const UserEntity({
    required this.id,
    this.actorId,
    required this.name,
    required this.email,
    this.phone,
    required this.isActive,
    this.emailVerifiedAt,
    this.primaryRole,
    this.roles = const [],
    required this.hasActiveSubscription,
    required this.subscriptionStatus,
    this.createdAt,
    this.orgStatus,
    this.orgId,
    this.orgName,
  });

  String get displayName => name.isNotEmpty ? name : email;

  bool hasRole(String roleName) => roles.any((r) => r.name == roleName);

  /// True when the user has an org but it hasn't been approved yet.
  bool get isOrgPendingApproval => orgStatus == 'pending_approval';

  /// True when org is fully active.
  bool get isOrgActive => orgStatus == 'active';
}
