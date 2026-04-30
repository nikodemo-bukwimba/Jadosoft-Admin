// lib/features/organization/data/models/org_invitation_model.dart
import '../../domain/entities/org_invitation_entity.dart';

class OrgInvitationModel extends OrgInvitationEntity {
  const OrgInvitationModel({
    required super.id,
    required super.orgId,
    required super.orgName,
    required super.email,
    required super.token,
    required super.roleName,
    super.roleSlug,
    required super.level,
    required super.status,
    required super.expiresAt,
    required super.createdAt,
  });

  factory OrgInvitationModel.fromJson(Map<String, dynamic> json) {
    final role = json['role'] as Map<String, dynamic>?;
    final org = json['organization'] as Map<String, dynamic>?;

    return OrgInvitationModel(
      id: json['id']?.toString() ?? '',
      orgId: json['org_id']?.toString() ?? org?['id']?.toString() ?? '',
      orgName: org?['name'] as String? ?? json['org_name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      token: json['token'] as String? ?? '',
      roleName:
          role?['name'] as String? ?? json['role_name'] as String? ?? 'Member',
      roleSlug: role?['slug'] as String? ?? json['role_slug'] as String?,
      level: json['level'] as int? ?? 0,
      status: _parseStatus(json['status'] as String?),
      expiresAt: json['expires_at'] != null
          ? DateTime.parse(json['expires_at'].toString())
          : DateTime.now().add(const Duration(days: 7)),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'].toString())
          : DateTime.now(),
    );
  }

  static InvitationStatus _parseStatus(String? s) => switch (s) {
    'accepted' => InvitationStatus.accepted,
    'expired' => InvitationStatus.expired,
    'cancelled' => InvitationStatus.cancelled,
    _ => InvitationStatus.pending,
  };
}
