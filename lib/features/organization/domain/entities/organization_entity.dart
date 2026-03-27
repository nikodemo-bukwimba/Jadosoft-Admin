import 'package:equatable/equatable.dart';

enum OrgStatus { pending, active, suspended, rejected }

class OrganizationEntity extends Equatable {
  final String id;
  final String name;
  final String? description;
  final String type; // company, ngo, government, individual
  final String? parentId;
  final OrgStatus status;
  final String? website;
  final String? phone;
  final String? address;
  final String? logoUrl;
  final String? approvedBy;
  final DateTime? approvedAt;
  final String? rejectionReason;
  final DateTime createdAt;

  const OrganizationEntity({
    required this.id,
    required this.name,
    this.description,
    required this.type,
    this.parentId,
    required this.status,
    this.website,
    this.phone,
    this.address,
    this.logoUrl,
    this.approvedBy,
    this.approvedAt,
    this.rejectionReason,
    required this.createdAt,
  });

  bool get isPending => status == OrgStatus.pending;
  bool get isActive => status == OrgStatus.active;
  bool get isSuspended => status == OrgStatus.suspended;
  bool get isRejected => status == OrgStatus.rejected;
  bool get isRoot => parentId == null;

  @override
  List<Object?> get props => [id, name, status, parentId, createdAt];
}
