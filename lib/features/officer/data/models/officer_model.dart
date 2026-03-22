// officer_model.dart
// ─────────────────────────────────────────────────────────────
// Data model for officers parsed from org membership API.
//
// Source: GET /orgs/{orgId}/members
// Expected JSON shape per member:
// {
//   "user_id": "01KK...",
//   "org_id": "01KK...",
//   "org_role_id": "01KK...",
//   "level": 50,
//   "status": "active",
//   "created_at": "2026-03-18T...",
//   "user": {
//     "id": "01KK...",
//     "username": "jdoe",
//     "email": "jdoe@example.com",
//     "phone": "+255...",
//     "status": "active",
//     "actor_id": "01KK..."
//   },
//   "role": {
//     "id": "01KK...",
//     "name": "Field Officer"
//   }
// }
//
// NOTE: Exact shape depends on API implementation. The fromJson
// below handles multiple possible structures defensively.
// ─────────────────────────────────────────────────────────────

import '../../domain/entities/officer_entity.dart';

class OfficerModel extends OfficerEntity {
  const OfficerModel({
    required super.userId,
    required super.actorId,
    required super.username,
    required super.email,
    super.phone,
    super.userStatus,
    required super.branchId,
    super.branchName,
    super.orgRoleId,
    super.orgRoleName,
    super.level,
    required super.membershipStatus,
    super.createdAt,
  });

  /// Parse from org membership API response.
  factory OfficerModel.fromJson(Map<String, dynamic> json) {
    // ── Extract nested user object ─────────────────────────
    final user = json['user'] as Map<String, dynamic>? ?? {};

    // ── Extract nested role object ─────────────────────────
    final role = json['role'] as Map<String, dynamic>? ?? {};

    // ── Extract nested actor (may be inside user or top-level)
    final actor = json['actor'] as Map<String, dynamic>? ?? {};

    // ── Resolve actorId from multiple possible locations ───
    final actorId = (json['actor_id'] ??
            user['actor_id'] ??
            actor['id'] ??
            '')
        .toString();

    // ── Resolve userId ────────────────────────────────────
    final userId = (json['user_id'] ?? user['id'] ?? '').toString();

    return OfficerModel(
      userId: userId,
      actorId: actorId,

      // User profile — API uses 'username', not 'name'
      username: user['username'] as String? ??
          user['name'] as String? ??
          json['username'] as String? ??
          '',
      email: user['email'] as String? ?? json['email'] as String? ?? '',
      phone: user['phone'] as String? ?? json['phone'] as String?,
      userStatus: user['status'] as String? ?? json['user_status'] as String?,

      // Org membership
      branchId: (json['org_id'] ?? '').toString(),
      branchName: json['org_name'] as String? ??
          (json['org'] is Map ? (json['org'] as Map)['name'] as String? : null),
      orgRoleId: (json['org_role_id'] ?? role['id'] ?? '').toString(),
      orgRoleName: role['name'] as String? ?? json['role_name'] as String?,
      level: (json['level'] as num?)?.toInt() ?? 0,
      membershipStatus: json['status'] as String? ?? 'active',

      // Timestamps
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }

  /// Serialise for local cache or debug.
  Map<String, dynamic> toJson() => {
        'user_id': userId,
        'actor_id': actorId,
        'username': username,
        'email': email,
        'phone': phone,
        'user_status': userStatus,
        'org_id': branchId,
        'branch_name': branchName,
        'org_role_id': orgRoleId,
        'org_role_name': orgRoleName,
        'level': level,
        'status': membershipStatus,
        'created_at': createdAt?.toIso8601String(),
      };

  /// Create from domain entity.
  factory OfficerModel.fromEntity(OfficerEntity e) => OfficerModel(
        userId: e.userId,
        actorId: e.actorId,
        username: e.username,
        email: e.email,
        phone: e.phone,
        userStatus: e.userStatus,
        branchId: e.branchId,
        branchName: e.branchName,
        orgRoleId: e.orgRoleId,
        orgRoleName: e.orgRoleName,
        level: e.level,
        membershipStatus: e.membershipStatus,
        createdAt: e.createdAt,
      );
}