import 'package:equatable/equatable.dart';

enum MemberStatus { active, suspended, invited }

class OrgMemberEntity extends Equatable {
  final String userId;
  final String name;
  final String email;
  final String? phone;
  final String roleName;
  final String? roleId;
  final int authorityLevel; // 0-100
  final MemberStatus status;
  final DateTime joinedAt;

  const OrgMemberEntity({
    required this.userId,
    required this.name,
    required this.email,
    this.phone,
    required this.roleName,
    this.roleId,
    this.authorityLevel = 0,
    required this.status,
    required this.joinedAt,
  });

  bool get isActive => status == MemberStatus.active;
  bool get isSuspended => status == MemberStatus.suspended;
  bool get isInvited => status == MemberStatus.invited;

  @override
  List<Object?> get props => [userId, email, roleName, status, joinedAt];
}
