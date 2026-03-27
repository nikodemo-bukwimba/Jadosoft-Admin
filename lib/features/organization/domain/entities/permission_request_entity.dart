import 'package:equatable/equatable.dart';

enum PermissionRequestStatus { pending, approved, denied }

class PermissionRequestEntity extends Equatable {
  final String id;
  final String orgId;
  final String orgName;
  final String requestedBy;
  final List<String> permissionSlugs;
  final String reason;
  final PermissionRequestStatus status;
  final String? reviewedBy;
  final String? reviewNotes;
  final DateTime? reviewedAt;
  final DateTime createdAt;

  const PermissionRequestEntity({
    required this.id,
    required this.orgId,
    required this.orgName,
    required this.requestedBy,
    this.permissionSlugs = const [],
    required this.reason,
    required this.status,
    this.reviewedBy,
    this.reviewNotes,
    this.reviewedAt,
    required this.createdAt,
  });

  bool get isPending => status == PermissionRequestStatus.pending;

  @override
  List<Object?> get props => [id, orgId, status, createdAt];
}
