// profile_entity.dart
// ─────────────────────────────────────────────────────────────
// Pure Dart. Represents the current logged-in user's full profile.
// Built from GET /user + GET /me/roles responses combined.
// ─────────────────────────────────────────────────────────────

 

import 'package:fca/features/auth/domain/entities/user_entity.dart';

class ProfileStats {
  final int    totalSubscriptions;
  final int    activeSubscriptions;
  final int    totalPayments;
  final int    successfulPayments;
  final double totalPaid;
  final String subscriptionStatus;
  final bool   isVerified;
  final bool   isRecentlyActive;

  const ProfileStats({
    required this.totalSubscriptions,
    required this.activeSubscriptions,
    required this.totalPayments,
    required this.successfulPayments,
    required this.totalPaid,
    required this.subscriptionStatus,
    required this.isVerified,
    required this.isRecentlyActive,
  });
}

class ProfileEntity {
  final UserEntity           user;
  final List<RoleEntity>     roles;
  final List<PermissionEntity> permissions;
  final ProfileStats?        stats;
  final DateTime             fetchedAt;

  const ProfileEntity({
    required this.user,
    required this.roles,
    required this.permissions,
    this.stats,
    required this.fetchedAt,
  });

  /// Quick permission check without importing RBAC layer.
  bool can(String slug) => permissions.any((p) => p.slug == slug);

  /// Quick role check.
  bool hasRole(String slug) => roles.any((r) => r.slug == slug);
}
