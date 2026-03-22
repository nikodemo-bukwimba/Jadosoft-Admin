import 'package:equatable/equatable.dart';

class OfficerEntity extends Equatable {
  final String userId;
  final String actorId;
  final String username;
  final String email;
  final String? phone;
  final String? userStatus;
  final String branchId;
  final String? branchName;
  final String? orgRoleId;
  final String? orgRoleName;
  final int level;
  final String membershipStatus;
  final DateTime? createdAt;

  const OfficerEntity({
    required this.userId, required this.actorId, required this.username,
    required this.email, this.phone, this.userStatus, required this.branchId,
    this.branchName, this.orgRoleId, this.orgRoleName, this.level = 0,
    required this.membershipStatus, this.createdAt,
  });

  String get displayName => username.isNotEmpty ? username : email;

  String get effectiveStatus {
    if (userStatus == 'suspended' || membershipStatus == 'suspended') return 'suspended';
    if (userStatus == 'deactivated') return 'deactivated';
    return membershipStatus;
  }

  bool get isActive => effectiveStatus == 'active';

  OfficerEntity copyWith({
    String? userId, String? actorId, String? username, String? email,
    String? phone, String? userStatus, String? branchId, String? branchName,
    String? orgRoleId, String? orgRoleName, int? level,
    String? membershipStatus, DateTime? createdAt,
  }) => OfficerEntity(
    userId: userId ?? this.userId, actorId: actorId ?? this.actorId,
    username: username ?? this.username, email: email ?? this.email,
    phone: phone ?? this.phone, userStatus: userStatus ?? this.userStatus,
    branchId: branchId ?? this.branchId, branchName: branchName ?? this.branchName,
    orgRoleId: orgRoleId ?? this.orgRoleId, orgRoleName: orgRoleName ?? this.orgRoleName,
    level: level ?? this.level, membershipStatus: membershipStatus ?? this.membershipStatus,
    createdAt: createdAt ?? this.createdAt,
  );

  @override
  List<Object?> get props => [userId, actorId, username, email, phone, userStatus,
    branchId, branchName, orgRoleId, orgRoleName, level, membershipStatus, createdAt];
}
