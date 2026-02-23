// account_session.dart
// ─────────────────────────────────────────────────────────────
// Represents ONE fully authenticated account stored on the device.
// Multiple AccountSessions can exist simultaneously.
// Only one is "active" at a time (tracked by activeAccountKey).
//
// Storage layout in flutter_secure_storage:
//   Key   → "account_{email}"
//   Value → JSON blob of this entity
//   Plus  → "active_account_email" = currently active email
// ─────────────────────────────────────────────────────────────

import 'user_entity.dart';

class AccountSession {
  final String     token;       // Sanctum Bearer token
  final UserEntity user;
  final List<PermissionEntity> permissions; // from GET /me/roles
  final DateTime   savedAt;     // when this session was stored

  const AccountSession({
    required this.token,
    required this.user,
    required this.permissions,
    required this.savedAt,
  });

  /// Convenience: is this account the one currently active?
  bool isActive(String activeEmail) => user.email == activeEmail;
}
