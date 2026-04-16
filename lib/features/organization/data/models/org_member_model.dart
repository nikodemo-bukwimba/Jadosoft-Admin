// org_member_model.dart
import '../../domain/entities/org_member_entity.dart';

class OrgMemberModel extends OrgMemberEntity {
  const OrgMemberModel({
    required super.userId,
    required super.name,
    required super.email,
    super.phone,
    required super.roleName,
    super.roleSlug,
    super.roleId,
    super.orgId,
    super.orgName,
    super.authorityLevel,
    required super.status,
    required super.joinedAt,
  });

  factory OrgMemberModel.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>?;
    final role = json['org_role'] as Map<String, dynamic>?
        ?? json['role'] as Map<String, dynamic>?;
    final org  = json['organization'] as Map<String, dynamic>?;

    // Name: actor.display_name > user.name > user.email
    final actor = user?['actor'] as Map<String, dynamic>?;
    final name =
        actor?['display_name'] as String? ??
        user?['name'] as String? ??
        user?['display_name'] as String? ??
        json['name'] as String? ??
        user?['email'] as String? ??
        json['email'] as String? ??
        '';

    final email = user?['email'] as String? ?? json['email'] as String? ?? '';

    final roleName =
        role?['name'] as String? ??
        json['role_name'] as String? ??
        json['org_role_name'] as String? ??
        'Member';

    final roleSlug =
        role?['slug'] as String? ??
        json['role_slug'] as String?;

    final orgName =
        org?['name'] as String? ??
        json['org_name'] as String? ??
        json['branch_name'] as String?;

    final orgId =
        json['org_id']?.toString() ??
        org?['id']?.toString();

    return OrgMemberModel(
      userId: json['user_id']?.toString() ?? user?['id']?.toString() ?? '',
      name: name,
      email: email,
      phone: user?['phone'] as String? ?? json['phone'] as String?,
      roleName: roleName,
      roleSlug: roleSlug,
      roleId: json['org_role_id']?.toString() ?? role?['id']?.toString(),
      orgId: orgId,
      orgName: orgName,
      authorityLevel: json['level'] as int? ?? json['authority_level'] as int? ?? 0,
      status: _parseStatus(json['status'] as String?),
      joinedAt: json['joined_at'] != null
          ? DateTime.parse(json['joined_at'].toString())
          : json['created_at'] != null
          ? DateTime.parse(json['created_at'].toString())
          : DateTime.now(),
    );
  }

  static MemberStatus _parseStatus(String? s) => switch (s) {
    'active'    => MemberStatus.active,
    'suspended' => MemberStatus.suspended,
    'invited'   => MemberStatus.invited,
    _           => MemberStatus.active,
  };
}