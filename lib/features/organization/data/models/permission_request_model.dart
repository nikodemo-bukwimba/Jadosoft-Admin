import '../../domain/entities/permission_request_entity.dart';

class PermissionRequestModel extends PermissionRequestEntity {
  const PermissionRequestModel({
    required super.id,
    required super.orgId,
    required super.orgName,
    required super.requestedBy,
    super.permissionSlugs,
    required super.reason,
    required super.status,
    super.reviewedBy,
    super.reviewNotes,
    super.reviewedAt,
    required super.createdAt,
  });

  factory PermissionRequestModel.fromJson(Map<String, dynamic> json) {
    final perms = (json['requested_permissions'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];
    return PermissionRequestModel(
      id: json['id']?.toString() ?? '',
      orgId: json['org_id']?.toString() ?? '',
      orgName: json['org']?['name'] as String? ?? '',
      requestedBy: json['requested_by']?.toString() ?? '',
      permissionSlugs: perms,
      reason: json['reason'] as String? ?? '',
      status: _parse(json['status'] as String?),
      reviewedBy: json['reviewed_by']?.toString(),
      reviewNotes: json['review_notes'] as String?,
      reviewedAt: json['reviewed_at'] != null ? DateTime.tryParse(json['reviewed_at'].toString()) : null,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'].toString()) : DateTime.now(),
    );
  }

  static PermissionRequestStatus _parse(String? s) => switch (s) {
    'approved' => PermissionRequestStatus.approved,
    'denied' => PermissionRequestStatus.denied,
    _ => PermissionRequestStatus.pending,
  };
}
