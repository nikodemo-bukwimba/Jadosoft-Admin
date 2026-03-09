// user_model.dart
// ─────────────────────────────────────────────────────────────
// CHANGE: UserModel.id is now String (Laravel uses ULIDs).
// RoleModel / PermissionModel keep int ids (standard auto-increment)
// but use safe parsing so they never hard-cast.
// ─────────────────────────────────────────────────────────────

import '../../domain/entities/user_entity.dart';

class RoleModel extends RoleEntity {
  const RoleModel({
    required super.id,
    required super.name,
    required super.slug,
  });

  factory RoleModel.fromJson(Map<String, dynamic> json) => RoleModel(
    // Safe parse — handles both int and numeric-string ids
    id: int.parse(json['id'].toString()),
    name: json['name'] as String,
    slug: json['slug'] as String,
  );

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'slug': slug};
}

class PermissionModel extends PermissionEntity {
  const PermissionModel({
    required super.id,
    required super.name,
    required super.slug,
  });

  factory PermissionModel.fromJson(Map<String, dynamic> json) =>
      PermissionModel(
        id: int.parse(json['id'].toString()),
        name: json['name'] as String,
        slug: json['slug'] as String,
      );

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'slug': slug};
}

class UserModel extends UserEntity {
  const UserModel({
    required super.id, // String — Laravel ULID
    required super.name,
    required super.email,
    super.phone,
    required super.isActive,
    super.emailVerifiedAt,
    super.primaryRole,
    super.roles,
    required super.hasActiveSubscription,
    required super.subscriptionStatus,
    super.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final rawRoles = json['roles'] as List<dynamic>? ?? [];
    final roles = rawRoles
        .map((r) => RoleModel.fromJson(r as Map<String, dynamic>))
        .toList();

    RoleModel? primaryRole;
    if (json['primary_role'] != null) {
      primaryRole = RoleModel.fromJson(
        json['primary_role'] as Map<String, dynamic>,
      );
    }

    return UserModel(
      // ULID — always a String, never cast to int
      id: json['id'].toString(),

      name: json['name'] as String? ?? '',
      email: json['email'] as String,
      phone: json['phone'] as String?,

      // Laravel may return 0/1 or true/false for booleans
      isActive: json['is_active'] == true || json['is_active'] == 1,
      hasActiveSubscription:
          json['has_active_subscription'] == true ||
          json['has_active_subscription'] == 1,

      emailVerifiedAt: json['email_verified_at'] != null
          ? DateTime.tryParse(json['email_verified_at'].toString())
          : null,

      primaryRole: primaryRole,
      roles: roles,

      subscriptionStatus: json['subscription_status'] as String? ?? 'none',

      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'phone': phone,
    'is_active': isActive,
    'email_verified_at': emailVerifiedAt?.toIso8601String(),
    'primary_role': primaryRole == null
        ? null
        : RoleModel(
            id: primaryRole!.id,
            name: primaryRole!.name,
            slug: primaryRole!.slug,
          ).toJson(),
    'roles': roles
        .map((r) => RoleModel(id: r.id, name: r.name, slug: r.slug).toJson())
        .toList(),
    'has_active_subscription': hasActiveSubscription,
    'subscription_status': subscriptionStatus,
    'created_at': createdAt?.toIso8601String(),
  };
}
