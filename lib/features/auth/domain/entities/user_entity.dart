// user_entity.dart
// ─────────────────────────────────────────────────────────────
// Pure Dart — zero Flutter or Drift imports.
// Shape mirrors the Laravel API /user and toApiArray() response.
//
// CHANGE: UserEntity.id is String — Laravel uses ULIDs.
// RoleEntity / PermissionEntity keep int ids (standard auto-increment).
// ─────────────────────────────────────────────────────────────

class RoleEntity {
  final int id;
  final String name;
  final String slug;

  const RoleEntity({required this.id, required this.name, required this.slug});
}

class PermissionEntity {
  final int id;
  final String name;
  final String slug;

  const PermissionEntity({
    required this.id,
    required this.name,
    required this.slug,
  });
}

class UserEntity {
  final String id; // ULID — always a String
  final String name;
  final String email;
  final String? phone;
  final bool isActive;
  final DateTime? emailVerifiedAt;
  final RoleEntity? primaryRole;
  final List<RoleEntity> roles;
  final bool hasActiveSubscription;
  final String subscriptionStatus; // 'active' | 'expired' | 'none'
  final DateTime? createdAt;

  const UserEntity({
    required this.id,
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

  /// Display name falls back to email if name is empty.
  String get displayName => name.isNotEmpty ? name : email;

  /// Whether this user has a specific role by slug.
  bool hasRole(String slug) => roles.any((r) => r.slug == slug);

  bool get isSuperAdmin => hasRole('super-admin');
  bool get isAdmin => hasRole('admin') || isSuperAdmin;
}
