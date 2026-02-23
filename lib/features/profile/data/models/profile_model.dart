// profile_model.dart
// ─────────────────────────────────────────────────────────────
// Data-layer representation of ProfileEntity.
// Reuses RoleModel and PermissionModel from auth feature.
// ─────────────────────────────────────────────────────────────

import '../../domain/entities/profile_entity.dart';

class ProfileModel extends ProfileEntity {
  const ProfileModel({
    required super.user,
    required super.roles,
    required super.permissions,
    super.stats,
    required super.fetchedAt,
  });
}
