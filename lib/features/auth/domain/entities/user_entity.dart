//admin app user_entity.dart
// ─────────────────────────────────────────────────────────────
// Pure Dart — zero Flutter or Drift imports.
// Shape mirrors the Laravel API /user and toApiArray() response.
//
// CHANGE: UserEntity.id is String — Laravel uses ULIDs.
// RoleEntity / PermissionEntity keep int ids (standard auto-increment).
//
// DESIGN: Roles on the entity are for DISPLAY only (badge, label).
// UI gating uses permission checks via RbacExtensions.can().
// No hardcoded role names anywhere in this file.
// ─────────────────────────────────────────────────────────────

class RoleEntity {
  final String id; // was int
  final String name;
  final String slug;
  const RoleEntity({required this.id, required this.name, required this.slug});
}

class PermissionEntity {
  final String id; // was int
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
  final String? actorId; // ← ADD — platform actor ULID
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

  const UserEntity({
    required this.id,
    this.actorId, // ← ADD
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
  });

  String get displayName => name.isNotEmpty ? name : email;

  bool hasRole(String roleName) => roles.any((r) => r.name == roleName);
}
