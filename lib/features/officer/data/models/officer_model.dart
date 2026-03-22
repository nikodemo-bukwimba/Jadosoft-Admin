import '../../domain/entities/officer_entity.dart';

class OfficerModel extends OfficerEntity {
  const OfficerModel({
    required super.userId, required super.actorId, required super.username,
    required super.email, super.phone, super.userStatus, required super.branchId,
    super.branchName, super.orgRoleId, super.orgRoleName, super.level,
    required super.membershipStatus, super.createdAt,
  });

  factory OfficerModel.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>? ?? {};
    final role = json['role'] as Map<String, dynamic>? ?? {};
    final actor = json['actor'] as Map<String, dynamic>? ?? {};
    final actorId = (json['actor_id'] ?? user['actor_id'] ?? actor['id'] ?? '').toString();
    final userId = (json['user_id'] ?? user['id'] ?? '').toString();

    return OfficerModel(
      userId: userId, actorId: actorId,
      username: user['username'] as String? ?? user['name'] as String? ?? json['username'] as String? ?? '',
      email: user['email'] as String? ?? json['email'] as String? ?? '',
      phone: user['phone'] as String? ?? json['phone'] as String?,
      userStatus: user['status'] as String? ?? json['user_status'] as String?,
      branchId: (json['org_id'] ?? '').toString(),
      branchName: json['org_name'] as String? ?? (json['org'] is Map ? (json['org'] as Map)['name'] as String? : null),
      orgRoleId: (json['org_role_id'] ?? role['id'] ?? '').toString(),
      orgRoleName: role['name'] as String? ?? json['role_name'] as String?,
      level: (json['level'] as num?)?.toInt() ?? 0,
      membershipStatus: json['status'] as String? ?? 'active',
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'user_id': userId, 'actor_id': actorId, 'username': username, 'email': email,
    'phone': phone, 'user_status': userStatus, 'org_id': branchId,
    'branch_name': branchName, 'org_role_id': orgRoleId, 'org_role_name': orgRoleName,
    'level': level, 'status': membershipStatus, 'created_at': createdAt?.toIso8601String(),
  };

  factory OfficerModel.fromEntity(OfficerEntity e) => OfficerModel(
    userId: e.userId, actorId: e.actorId, username: e.username, email: e.email,
    phone: e.phone, userStatus: e.userStatus, branchId: e.branchId,
    branchName: e.branchName, orgRoleId: e.orgRoleId, orgRoleName: e.orgRoleName,
    level: e.level, membershipStatus: e.membershipStatus, createdAt: e.createdAt,
  );
}
