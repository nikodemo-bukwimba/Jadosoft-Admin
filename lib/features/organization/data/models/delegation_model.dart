import '../../domain/entities/delegation_entity.dart';

class DelegationModel extends DelegationEntity {
  const DelegationModel({
    required super.id,
    required super.parentOrgId,
    required super.childOrgId,
    required super.childOrgName,
    required super.roleName,
    super.permissionSlugs,
    required super.createdAt,
  });

  factory DelegationModel.fromJson(Map<String, dynamic> json) {
    final perms = (json['permissions'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];
    return DelegationModel(
      id: json['id']?.toString() ?? '',
      parentOrgId: json['parent_org_id']?.toString() ?? '',
      childOrgId: json['child_org_id']?.toString() ?? '',
      childOrgName: json['child_org']?['name'] as String? ?? json['child_org_name'] as String? ?? '',
      roleName: json['role']?['name'] as String? ?? json['role_name'] as String? ?? '',
      permissionSlugs: perms,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'].toString()) : DateTime.now(),
    );
  }
}
