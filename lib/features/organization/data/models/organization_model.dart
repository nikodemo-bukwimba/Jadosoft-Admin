import '../../domain/entities/organization_entity.dart';

class OrganizationModel extends OrganizationEntity {
  const OrganizationModel({
    required super.id,
    required super.name,
    super.description,
    required super.type,
    super.parentId,
    required super.status,
    super.website,
    super.phone,
    super.address,
    super.logoUrl,
    super.approvedBy,
    super.approvedAt,
    super.rejectionReason,
    required super.createdAt,
  });

  factory OrganizationModel.fromJson(Map<String, dynamic> json) {
    return OrganizationModel(
      id: json['id']?.toString() ?? json['actor_id']?.toString() ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      type: json['type'] as String? ?? 'company',
      parentId: json['parent_id']?.toString(),
      status: _parseStatus(json['status'] as String?),
      website: json['website'] as String?,
      phone: json['phone'] as String?,
      address: json['address'] as String?,
      logoUrl: json['logo_url'] as String?,
      approvedBy: json['approved_by']?.toString(),
      approvedAt: json['approved_at'] != null ? DateTime.tryParse(json['approved_at'].toString()) : null,
      rejectionReason: json['rejection_reason'] as String?,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'].toString()) : DateTime.now(),
    );
  }

  static OrgStatus _parseStatus(String? s) => switch (s) {
    'active' => OrgStatus.active,
    'suspended' => OrgStatus.suspended,
    'rejected' => OrgStatus.rejected,
    _ => OrgStatus.pending,
  };
}
