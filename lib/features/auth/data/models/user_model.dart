// user_model.dart
// ─────────────────────────────────────────────────────────────
// Extends domain entities with JSON deserialization.
// fromJson shapes match Laravel's toApiArray() exactly.
// ─────────────────────────────────────────────────────────────

import '../../domain/entities/user_entity.dart';

class RoleModel extends RoleEntity {
  const RoleModel({
    required super.id,
    required super.name,
    required super.slug,
  });

  factory RoleModel.fromJson(Map<String, dynamic> json) => RoleModel(
        id:   json['id']   as int,
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

  factory PermissionModel.fromJson(Map<String, dynamic> json) => PermissionModel(
        id:   json['id']   as int,
        name: json['name'] as String,
        slug: json['slug'] as String,
      );

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'slug': slug};
}

class UserModel extends UserEntity {
  const UserModel({
    required super.id,
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

  /// Parses the shape returned by Laravel's toApiArray() / GET /user.
  factory UserModel.fromJson(Map<String, dynamic> json) {
    // roles list
    final rawRoles = json['roles'] as List<dynamic>? ?? [];
    final roles = rawRoles
        .map((r) => RoleModel.fromJson(r as Map<String, dynamic>))
        .toList();

    // primary_role (nullable)
    RoleModel? primaryRole;
    if (json['primary_role'] != null) {
      primaryRole = RoleModel.fromJson(
        json['primary_role'] as Map<String, dynamic>,
      );
    }

    return UserModel(
      id:                   json['id'] as int,
      name:                 json['name'] as String? ?? '',
      email:                json['email'] as String,
      phone:                json['phone'] as String?,
      isActive:             json['is_active'] as bool? ?? false,
      emailVerifiedAt:      json['email_verified_at'] != null
          ? DateTime.tryParse(json['email_verified_at'].toString())
          : null,
      primaryRole:          primaryRole,
      roles:                roles,
      hasActiveSubscription: json['has_active_subscription'] as bool? ?? false,
      subscriptionStatus:   json['subscription_status'] as String? ?? 'none',
      createdAt:            json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id':                      id,
        'name':                    name,
        'email':                   email,
        'phone':                   phone,
        'is_active':               isActive,
        'email_verified_at':       emailVerifiedAt?.toIso8601String(),
        'primary_role':            primaryRole == null
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
        'subscription_status':     subscriptionStatus,
        'created_at':              createdAt?.toIso8601String(),
      };
}
