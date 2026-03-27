import '../../domain/entities/org_role_entity.dart';

class OrgPermissionModel extends OrgPermissionEntity {
  const OrgPermissionModel({
    required super.id,
    required super.name,
    required super.slug,
    super.group,
  });

  factory OrgPermissionModel.fromJson(Map<String, dynamic> json) =>
      OrgPermissionModel(
        id: json['id']?.toString() ?? '',
        name: json['name'] as String? ?? '',
        slug: json['slug'] as String? ?? '',
        group: json['group'] as String?,
      );
}

class OrgRoleModel extends OrgRoleEntity {
  const OrgRoleModel({
    required super.id,
    required super.name,
    super.description,
    super.permissions,
    super.memberCount,
    super.isDefault,
    required super.createdAt,
  });

  factory OrgRoleModel.fromJson(Map<String, dynamic> json) {
    final permList =
        (json['permissions'] as List<dynamic>?)?.map((p) {
          final pm = p as Map<String, dynamic>;
          return OrgPermissionModel.fromJson(pm);
        }).toList() ??
        [];

    return OrgRoleModel(
      id: json['id']?.toString() ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      permissions: permList,
      memberCount:
          json['member_count'] as int? ?? json['users_count'] as int? ?? 0,
      isDefault: json['is_default'] as bool? ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'].toString())
          : DateTime.now(),
    );
  }
}
