import '../../domain/entities/branch_entity.dart';

class BranchModel extends BranchEntity {
  const BranchModel({
    required super.id,
    required super.name,
    super.description,
    required super.parentOrgId,
    super.address,
    super.phone,
    super.memberCount,
    required super.createdAt,
  });

  factory BranchModel.fromJson(Map<String, dynamic> json) {
    return BranchModel(
      id: json['id']?.toString() ?? json['actor_id']?.toString() ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      parentOrgId: json['parent_id']?.toString() ?? '',
      address: json['address'] as String?,
      phone: json['phone'] as String?,
      memberCount: json['member_count'] as int? ?? json['memberships_count'] as int? ?? 0,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'].toString()) : DateTime.now(),
    );
  }
}
