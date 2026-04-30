// lib/features/organization/domain/entities/org_invitation_entity.dart
import 'package:equatable/equatable.dart';

enum InvitationStatus { pending, accepted, expired, cancelled }

class OrgInvitationEntity extends Equatable {
  final String id;
  final String orgId;
  final String orgName;
  final String email;
  final String token;
  final String roleName;
  final String? roleSlug;
  final int level;
  final InvitationStatus status;
  final DateTime expiresAt;
  final DateTime createdAt;

  const OrgInvitationEntity({
    required this.id,
    required this.orgId,
    required this.orgName,
    required this.email,
    required this.token,
    required this.roleName,
    this.roleSlug,
    required this.level,
    required this.status,
    required this.expiresAt,
    required this.createdAt,
  });

  bool get isPending => status == InvitationStatus.pending;
  bool get isExpired =>
      status == InvitationStatus.expired || expiresAt.isBefore(DateTime.now());
  bool get isAccepted => status == InvitationStatus.accepted;
  bool get isCancelled => status == InvitationStatus.cancelled;

  @override
  List<Object?> get props => [id, email, status, expiresAt];
}
