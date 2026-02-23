// auth_interceptor.dart  [R4 — Token Management]
// ─────────────────────────────────────────────────────────────
// Reads the active account's token from SecureStorageService
// and attaches it as a Bearer header on every request.
// On 401 → forces logout of the active account only.
// Token refresh is intentionally omitted: Sanctum personal
// tokens do not expire by default. If you add expiry on the
// Laravel side, implement refresh logic here.
// ─────────────────────────────────────────────────────────────

import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:fca/core/constants/app_constants.dart';
 
import '../storage/secure_storage_service.dart';

class AuthInterceptor extends Interceptor {
  final SecureStorageService _storage;

  AuthInterceptor(this._storage);

  // ── Attach Bearer token ───────────────────────────────────
  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _getActiveToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  // ── Handle 401 ────────────────────────────────────────────
  @override
  void onError(
    DioException error,
    ErrorInterceptorHandler handler,
  ) async {
    if (error.response?.statusCode == 401) {
      // Active token is invalid — clear this account's session.
      await _clearActiveAccountToken();
    }
    handler.next(error);
  }

  // ── Helpers ───────────────────────────────────────────────

  Future<String?> _getActiveToken() async {
    final activeEmail = await _storage.read(AppConstants.activeAccountKey);
    if (activeEmail == null) return null;

    final sessionJson = await _storage.read(
      '${AppConstants.accountPrefix}$activeEmail',
    );
    if (sessionJson == null) return null;

    try {
      final session = jsonDecode(sessionJson) as Map<String, dynamic>;
      return session['token'] as String?;
    } catch (_) {
      return null;
    }
  }

  Future<void> _clearActiveAccountToken() async {
    final activeEmail = await _storage.read(AppConstants.activeAccountKey);
    if (activeEmail == null) return;

    final key = '${AppConstants.accountPrefix}$activeEmail';
    final sessionJson = await _storage.read(key);
    if (sessionJson == null) return;

    try {
      final session = jsonDecode(sessionJson) as Map<String, dynamic>;
      session.remove('token');
      await _storage.write(key, jsonEncode(session));
    } catch (_) {}
  }
}
