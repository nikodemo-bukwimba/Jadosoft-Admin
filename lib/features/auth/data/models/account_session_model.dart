// FILE: lib/features/auth/data/models/account_session_model.dart
// CHANGE: toJson() was silently dropping orgId, orgStatus, orgName,
//         and (new) branchId, branchName when serialising to secure storage.
//         This caused the "re-login shows old branch" bug because the
//         stale cached session overwrote the fresh /auth/me data on restore.
//
//         Fix: pass all fields through when constructing the inner UserModel.

import 'dart:convert';
import '../../domain/entities/account_session.dart';
import '../../domain/entities/user_entity.dart';
import 'user_model.dart';

class AccountSessionModel extends AccountSession {
  const AccountSessionModel({
    required super.token,
    required super.user,
    required super.permissions,
    required super.savedAt,
  });

  factory AccountSessionModel.fromJson(Map<String, dynamic> json) {
    final rawPerms = json['permissions'] as List<dynamic>? ?? [];
    final permissions = rawPerms
        .map((p) => PermissionModel.fromJson(p as Map<String, dynamic>))
        .toList();

    final token = json['token'] as String?;
    final userJson = json['user'] as Map<String, dynamic>?;
    final savedAtStr = json['saved_at'] as String?;

    if (token == null || userJson == null || savedAtStr == null) {
      throw Exception('Invalid session data in storage');
    }

    return AccountSessionModel(
      token: token,
      user: UserModel.fromJson(userJson),
      permissions: permissions,
      savedAt: DateTime.parse(savedAtStr),
    );
  }

  Map<String, dynamic> toJson() => {
    'token': token,
    // ── THE BUG WAS HERE ──────────────────────────────────────────────
    // Previously the UserModel was constructed manually with only a subset
    // of fields, silently dropping orgId / orgStatus / orgName and the new
    // branch fields.  Now every field on `user` is forwarded explicitly.
    'user': UserModel(
      id: user.id,
      actorId: user.actorId,
      name: user.name,
      email: user.email,
      phone: user.phone,
      isActive: user.isActive,
      emailVerifiedAt: user.emailVerifiedAt,
      primaryRole: user.primaryRole,
      roles: user.roles,
      hasActiveSubscription: user.hasActiveSubscription,
      subscriptionStatus: user.subscriptionStatus,
      createdAt: user.createdAt,
      orgId: user.orgId, // was missing
      orgStatus: user.orgStatus, // was missing
      orgName: user.orgName, // was missing
      branchId: user.branchId, // new
      branchName: user.branchName, // new
    ).toJson(),
    // ─────────────────────────────────────────────────────────────────
    'permissions': permissions
        .map(
          (p) => PermissionModel(id: p.id, name: p.name, slug: p.slug).toJson(),
        )
        .toList(),
    'saved_at': savedAt.toIso8601String(),
  };

  String toJsonString() => jsonEncode(toJson());

  factory AccountSessionModel.fromJsonString(String raw) =>
      AccountSessionModel.fromJson(jsonDecode(raw) as Map<String, dynamic>);

  factory AccountSessionModel.fromLoginResponse({
    required String token,
    required UserModel user,
    required List<PermissionEntity> permissions,
  }) => AccountSessionModel(
    token: token,
    user: user,
    permissions: permissions,
    savedAt: DateTime.now(),
  );
}
