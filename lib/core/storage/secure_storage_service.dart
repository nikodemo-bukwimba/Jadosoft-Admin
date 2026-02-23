// secure_storage_service.dart  [R2 — Secure Device Storage]
// ─────────────────────────────────────────────────────────────
// Central wrapper around flutter_secure_storage.
// ALL tokens, session data, and credentials go through here.
// SharedPreferences is NEVER used for sensitive data.
// ─────────────────────────────────────────────────────────────

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  final FlutterSecureStorage _storage;

  SecureStorageService(this._storage);

  Future<String?> read(String key) =>
      _storage.read(key: key);

  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);

  Future<void> delete(String key) =>
      _storage.delete(key: key);

  Future<void> deleteAll() =>
      _storage.deleteAll();

  /// Returns all key-value pairs in secure storage.
  /// Used by the multi-account manager to list stored accounts.
  Future<Map<String, String>> readAll() =>
      _storage.readAll();

  Future<bool> containsKey(String key) =>
      _storage.containsKey(key: key);
}
