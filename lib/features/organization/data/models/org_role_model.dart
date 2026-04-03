import '../../domain/entities/org_role_entity.dart';

class OrgPermissionModel extends OrgPermissionEntity {
  const OrgPermissionModel({
    required super.id,
    required super.name,
    required super.slug,
    super.group,
  });

  /// Maps from the actual API response:
  /// { "id": "01KM...", "name": "members.view", "group_name": "members", "description": null }
  ///
  /// - API "name" field IS the slug (e.g. "members.view")
  /// - API has NO separate "slug" field
  /// - API uses "group_name" not "group"
  factory OrgPermissionModel.fromJson(Map<String, dynamic> json) {
    final nameVal = json['name'] as String? ?? '';
    return OrgPermissionModel(
      id: json['id']?.toString() ?? '',
      name:
          json['description'] as String? ??
          _humanize(nameVal), // human-readable
      slug: nameVal, // e.g. "members.view"
      group: json['group_name'] as String? ?? json['group'] as String?,
    );
  }

  /// Converts "members.view" → "Members View"
  static String _humanize(String slug) {
    return slug
        .replaceAll('.', ' ')
        .replaceAll('_', ' ')
        .split(' ')
        .map((w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }
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
      isDefault:
          json['is_default'] as bool? ?? json['is_system'] as bool? ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'].toString())
          : DateTime.now(),
    );
  }
}
