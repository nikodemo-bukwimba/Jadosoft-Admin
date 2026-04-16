// org_member_entity.dart
import 'package:equatable/equatable.dart';

enum MemberStatus { active, suspended, invited }

class OrgMemberEntity extends Equatable {
  final String userId;
  final String name;
  final String email;
  final String? phone;
  final String roleName;
  final String? roleSlug;
  final String? roleId;
  final String? orgId; // which org/branch this membership belongs to
  final String? orgName; // branch name for display
  final int authorityLevel; // 0-100
  final MemberStatus status;
  final DateTime joinedAt;

  const OrgMemberEntity({
    required this.userId,
    required this.name,
    required this.email,
    this.phone,
    required this.roleName,
    this.roleSlug,
    this.roleId,
    this.orgId,
    this.orgName,
    this.authorityLevel = 0,
    required this.status,
    required this.joinedAt,
  });

  bool get isActive => status == MemberStatus.active;
  bool get isSuspended => status == MemberStatus.suspended;
  bool get isInvited => status == MemberStatus.invited;

  /// True when this member is acting as a branch admin/manager role
  bool get isBranchAdmin =>
      roleSlug?.contains('manager') == true ||
      roleSlug?.contains('admin') == true ||
      roleName.toLowerCase().contains('manager') ||
      roleName.toLowerCase().contains('admin');

  /// True when this member is a field officer role
  bool get isOfficer =>
      roleSlug?.contains('officer') == true ||
      roleName.toLowerCase().contains('officer');

  /// Icon category for role display
  String get roleCategory {
    if (roleName.toLowerCase().contains('owner')) return 'owner';
    if (isBranchAdmin) return 'manager';
    if (isOfficer) return 'officer';
    return 'member';
  }

  @override
  List<Object?> get props => [userId, email, roleName, orgId, status, joinedAt];
}
