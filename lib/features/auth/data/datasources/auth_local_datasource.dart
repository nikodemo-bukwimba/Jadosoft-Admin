// auth_local_datasource.dart  [R2 — Secure Device Storage]
// ─────────────────────────────────────────────────────────────
// Manages multiple AccountSessions in flutter_secure_storage.
//
// Storage layout:
//   "active_account_email"  → currently active email (or absent)
//   "account_{email}"       → AccountSessionModel JSON per account
//
// Rules:
//   - All reads/writes go through SecureStorageService
//   - SharedPreferences is never used here
//   - On logout: token is revoked remotely FIRST, then cleared here
// ─────────────────────────────────────────────────────────────

import '../../../../core/constants/app_constants.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../models/account_session_model.dart';

abstract class AuthLocalDataSource {
  Future<void> saveSession(AccountSessionModel session);
  Future<AccountSessionModel?> getActiveSession();
  Future<List<AccountSessionModel>> getAllSessions();
  Future<void> setActiveAccount(String email);
  Future<String?> getActiveEmail();
  Future<void> removeSession(String email);
  Future<void> clearAll();
}

class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  final SecureStorageService _storage;

  AuthLocalDataSourceImpl(this._storage);

  // ── Save / overwrite a session ────────────────────────────
  @override
  Future<void> saveSession(AccountSessionModel session) async {
    try {
      final key = _accountKey(session.user.email);
      await _storage.write(key, session.toJsonString());
    } catch (e) {
      throw CacheException('Failed to save session: $e');
    }
  }

  // ── Get currently active session ──────────────────────────
  @override
  Future<AccountSessionModel?> getActiveSession() async {
    try {
      final email = await getActiveEmail();
      if (email == null) return null;
      return _readSession(email);
    } catch (e) {
      throw CacheException('Failed to read active session: $e');
    }
  }

  // ── Get all stored sessions ───────────────────────────────
  @override
  Future<List<AccountSessionModel>> getAllSessions() async {
    try {
      final all = await _storage.readAll();
      final sessions = <AccountSessionModel>[];

      for (final entry in all.entries) {
        if (entry.key.startsWith(AppConstants.accountPrefix)) {
          try {
            sessions.add(AccountSessionModel.fromJsonString(entry.value));
          } catch (_) {
            // Corrupt entry — skip silently, don't crash the list
          }
        }
      }

      // Sort: most recently saved first
      sessions.sort((a, b) => b.savedAt.compareTo(a.savedAt));
      return sessions;
    } catch (e) {
      throw CacheException('Failed to read sessions: $e');
    }
  }

  // ── Set active account ────────────────────────────────────
  @override
  Future<void> setActiveAccount(String email) async {
    try {
      // Verify the session exists before making it active
      final session = await _readSession(email);
      if (session == null) {
        throw CacheException('No stored session for $email');
      }
      await _storage.write(AppConstants.activeAccountKey, email);
    } catch (e) {
      if (e is CacheException) rethrow;
      throw CacheException('Failed to set active account: $e');
    }
  }

  // ── Get active email ──────────────────────────────────────
  @override
  Future<String?> getActiveEmail() async {
    return _storage.read(AppConstants.activeAccountKey);
  }

  // ── Remove a specific account session ─────────────────────
  @override
  Future<void> removeSession(String email) async {
    try {
      await _storage.delete(_accountKey(email));

      // If this was the active account, clear the active pointer
      final activeEmail = await getActiveEmail();
      if (activeEmail == email) {
        await _storage.delete(AppConstants.activeAccountKey);

        // Auto-switch to another account if one exists
        final remaining = await getAllSessions();
        if (remaining.isNotEmpty) {
          await _storage.write(
            AppConstants.activeAccountKey,
            remaining.first.user.email,
          );
        }
      }
    } catch (e) {
      throw CacheException('Failed to remove session: $e');
    }
  }

  // ── Clear all sessions (full device wipe) ─────────────────
  @override
  Future<void> clearAll() async {
    try {
      await _storage.deleteAll();
    } catch (e) {
      throw CacheException('Failed to clear all sessions: $e');
    }
  }

  // ── Private helpers ───────────────────────────────────────

  String _accountKey(String email) => '${AppConstants.accountPrefix}$email';

  Future<AccountSessionModel?> _readSession(String email) async {
    final raw = await _storage.read(_accountKey(email));
    if (raw == null) return null;
    return AccountSessionModel.fromJsonString(raw);
  }
}
