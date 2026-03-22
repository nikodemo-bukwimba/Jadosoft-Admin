// officer_entity.dart
// ─────────────────────────────────────────────────────────────
// Domain entity for a marketing officer in the admin app.
//
// An "officer" is NOT a standalone resource in the HMSCP API.
// It is a COMPOSITE of:
//   - User (platform-level account: email, phone, username)
//   - Actor (business identity: display_name, actor_types)
//   - OrgMembership (links user to org/branch with a role)
//
// The admin app presents this composite as a single "Officer".
//
// Data source:
//   GET /orgs/{orgId}/members → returns memberships with user,
//   actor, and role loaded inline.
// ─────────────────────────────────────────────────────────────

import 'package:equatable/equatable.dart';

class OfficerEntity extends Equatable {
  // ── Identity ─────────────────────────────────────────────
  /// Platform user ID (ULID). Used for member management.
  final String userId;

  /// Actor ID (ULID). Used in Pharma API (visits, plans, reports).
  final String actorId;

  // ── User profile ─────────────────────────────────────────
  final String username;
  final String email;
  final String? phone;
  final String? userStatus; // active | suspended (platform-level)

  // ── Organisation membership ──────────────────────────────
  /// The branch this officer is assigned to (orgId).
  final String branchId;

  /// Branch display name (e.g., "Mbeya Branch").
  final String? branchName;

  /// Role within the org (e.g., "Field Officer", "Head Officer").
  final String? orgRoleId;
  final String? orgRoleName;

  /// Hierarchy level within the org (0 = lowest, 100 = owner).
  final int level;

  /// Membership status (active | suspended at org level).
  final String membershipStatus;

  // ── Timestamps ───────────────────────────────────────────
  final DateTime? createdAt;

  const OfficerEntity({
    required this.userId,
    required this.actorId,
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

  /// Display name: prefer username, fall back to email.
  String get displayName => username.isNotEmpty ? username : email;

  /// Effective status: the WORSE of user status and membership status.
  /// If either is suspended, officer is effectively suspended.
  String get effectiveStatus {
    if (userStatus == 'suspended' || membershipStatus == 'suspended') {
      return 'suspended';
    }
    if (userStatus == 'deactivated') return 'deactivated';
    return membershipStatus;
  }

  /// Whether the officer is currently active.
  bool get isActive => effectiveStatus == 'active';

  OfficerEntity copyWith({
    String? userId,
    String? actorId,
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
  }) {
    return OfficerEntity(
      userId: userId ?? this.userId,
      actorId: actorId ?? this.actorId,
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
  }

  @override
  List<Object?> get props => [
        userId,
        actorId,
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