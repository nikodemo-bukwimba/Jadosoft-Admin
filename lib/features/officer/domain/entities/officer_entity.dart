import 'package:equatable/equatable.dart';

class OfficerEntity extends Equatable {
  final String userId;
  final String actorId;

  /// Real full name from actor.display_name — e.g. "John Mwangi".
  /// Problem #1 fix: this field now carries the real identity name.
  final String fullName;

  /// Technical login handle — auto-generated, e.g. "john_mwangi_4j2k".
  /// Never shown in the UI; kept for internal reference only.
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
    required this.userId,
    required this.actorId,
    required this.fullName,
    required this.username,
    required this.email,
    this.phone,
    this.userStatus,
    required this.branchId,
    this.branchName,
    this.orgRoleId,
    this.orgRoleName,
    this.level = 0,
    required this.membershipStatus,
    this.createdAt,
  });

  /// Problem #1 fix: always show fullName in the UI.
  /// Falls back to username (technical) only when fullName is blank
  /// (e.g. old records created before the name fix was deployed).
  String get displayName {
    if (fullName.trim().isNotEmpty) return fullName.trim();
    if (username.trim().isNotEmpty) return username.trim();
    return email;
  }

  String get effectiveStatus {
    if (userStatus == 'suspended' || membershipStatus == 'suspended') {
      return 'suspended';
    }
    if (userStatus == 'deactivated') return 'deactivated';
    return membershipStatus;
  }

  bool get isActive => effectiveStatus == 'active';

  OfficerEntity copyWith({
    String? userId,
    String? actorId,
    String? fullName,
    String? username,
    String? email,
    String? phone,
    String? userStatus,
    String? branchId,
    String? branchName,
    String? orgRoleId,
    String? orgRoleName,
    int? level,
    String? membershipStatus,
    DateTime? createdAt,
  }) => OfficerEntity(
    userId: userId ?? this.userId,
    actorId: actorId ?? this.actorId,
    fullName: fullName ?? this.fullName,
    username: username ?? this.username,
    email: email ?? this.email,
    phone: phone ?? this.phone,
    userStatus: userStatus ?? this.userStatus,
    branchId: branchId ?? this.branchId,
    branchName: branchName ?? this.branchName,
    orgRoleId: orgRoleId ?? this.orgRoleId,
    orgRoleName: orgRoleName ?? this.orgRoleName,
    level: level ?? this.level,
    membershipStatus: membershipStatus ?? this.membershipStatus,
    createdAt: createdAt ?? this.createdAt,
  );

  @override
  List<Object?> get props => [
    userId,
    actorId,
    fullName,
    username,
    email,
    phone,
    userStatus,
    branchId,
    branchName,
    orgRoleId,
    orgRoleName,
    level,
    membershipStatus,
    createdAt,
  ];
}
