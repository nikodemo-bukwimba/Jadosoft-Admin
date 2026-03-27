import '../../domain/entities/org_member_entity.dart';

class OrgMemberModel extends OrgMemberEntity {
  const OrgMemberModel({
    required super.userId,
    required super.name,
    required super.email,
    super.phone,
    required super.roleName,
    super.roleId,
    super.authorityLevel,
    required super.status,
    required super.joinedAt,
  });

  factory OrgMemberModel.fromJson(Map<String, dynamic> json) {
    // API returns membership with nested user object OR flat fields
    final user = json['user'] as Map<String, dynamic>?;
    final role = json['role'] as Map<String, dynamic>?;

    // Try multiple name sources
    final name =
        user?['name'] as String? ??
        user?['display_name'] as String? ??
        json['name'] as String? ??
        json['display_name'] as String? ??
        user?['email'] as String? ??
        json['email'] as String? ??
        '';

    final email = user?['email'] as String? ?? json['email'] as String? ?? '';

    return OrgMemberModel(
      userId: json['user_id']?.toString() ?? user?['id']?.toString() ?? '',
      name: name,
      email: email,
      phone: user?['phone'] as String? ?? json['phone'] as String?,
      roleName:
          role?['name'] as String? ??
          json['role_name'] as String? ??
          json['org_role_name'] as String? ??
          'member',
      roleId: json['org_role_id']?.toString() ?? role?['id']?.toString(),
      authorityLevel:
          json['level'] as int? ?? json['authority_level'] as int? ?? 0,
      status: _parseStatus(json['status'] as String?),
      joinedAt: json['joined_at'] != null
          ? DateTime.parse(json['joined_at'].toString())
          : json['created_at'] != null
          ? DateTime.parse(json['created_at'].toString())
          : DateTime.now(),
    );
  }

  static MemberStatus _parseStatus(String? s) => switch (s) {
    'active' => MemberStatus.active,
    'suspended' => MemberStatus.suspended,
    'invited' => MemberStatus.invited,
    _ => MemberStatus.active,
  };
}
