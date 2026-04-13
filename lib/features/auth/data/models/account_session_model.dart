// account_session_model.dart
// ─────────────────────────────────────────────────────────────
// Serializable form of AccountSession stored in flutter_secure_storage.
// Each instance maps to one key: "account_{email}"
// ─────────────────────────────────────────────────────────────

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

    return AccountSessionModel(
      token: json['token'] as String,
      user: UserModel.fromJson(json['user'] as Map<String, dynamic>),
      permissions: permissions,
      savedAt: DateTime.parse(json['saved_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'token': token,
    'user': UserModel(
      id: user.id,
      actorId: user.actorId, // ADD — was missing
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
    ).toJson(),
    'permissions': permissions
        .map(
          (p) => PermissionModel(id: p.id, name: p.name, slug: p.slug).toJson(),
        )
        .toList(),
    'saved_at': savedAt.toIso8601String(),
  };

  /// Encode to JSON string for secure storage.
  String toJsonString() => jsonEncode(toJson());

  /// Decode from JSON string read from secure storage.
  factory AccountSessionModel.fromJsonString(String raw) =>
      AccountSessionModel.fromJson(jsonDecode(raw) as Map<String, dynamic>);

  /// Create from a fresh login response + fetched roles.
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
