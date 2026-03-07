// auth_interceptor.dart  [R4 — Token Management]
// ─────────────────────────────────────────────────────────────
// Responsibilities:
//   1. Attach Bearer token to every outgoing request.
//   2. On 401 — two behaviours depending on TokenRefreshConfig:
//
//      a) Refresh DISABLED (default):
//         Clear the active account's token from storage.
//         Pass the 401 error downstream → AuthBloc emits Unauthenticated.
//
//      b) Refresh ENABLED:
//         Attempt ONE token refresh for the entire app (mutex-guarded).
//         All concurrent 401 requests queue up via Completers.
//         On refresh SUCCESS → persist new token, retry all queued requests.
//         On refresh FAILURE → clear token, reject all queued requests.
//         A '_skipRefresh' extra key prevents the retry from looping.
//
// Circular dependency resolution:
//   AuthInterceptor is constructed BEFORE Dio (DI order).
//   Call [setDio] immediately after Dio is built in [buildSecureDioClient].
//   This is the standard Dio retry pattern — safe because [setDio] is called
//   synchronously before any request can be made.
//
// Security rules (unchanged from original):
//   - Never logs tokens (LoggingInterceptor only logs method + path + status).
//   - Clears only the ACTIVE account's token on 401 — other saved accounts
//     are unaffected.
//   - The refresh request itself is tagged _skipRefresh = true so a 401 on
//     the refresh endpoint does not recurse.
// ─────────────────────────────────────────────────────────────

import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../constants/app_constants.dart';
import '../storage/secure_storage_service.dart';
import 'token_refresh_config.dart';

// ── Internal sentinel key ──────────────────────────────────────
// Added to RequestOptions.extra on retried requests so the interceptor
// never tries to refresh a refresh call.
const _kSkipRefresh = '_skipRefresh';

class AuthInterceptor extends Interceptor {
  // ── Dependencies ──────────────────────────────────────────
  final SecureStorageService _storage;
  final TokenRefreshConfig _refreshConfig;

  /// Set by [buildSecureDioClient] immediately after Dio is created.
  /// Used to replay queued requests after a successful token refresh.
  Dio? _dio;

  // ── Refresh mutex state ───────────────────────────────────
  bool _isRefreshing = false;

  /// Completers for requests that arrived while a refresh was in progress.
  /// Each completer resolves with the new token (success) or null (failure).
  final List<Completer<String?>> _queue = [];

  // ── Constructor ───────────────────────────────────────────
  AuthInterceptor(
    this._storage, {
    TokenRefreshConfig refreshConfig = const TokenRefreshConfig.disabled(),
  }) : _refreshConfig = refreshConfig;

  /// Called by [buildSecureDioClient] to give the interceptor a reference
  /// to the shared Dio instance for retrying queued requests.
  void setDio(Dio dio) => _dio = dio;

  // ─────────────────────────────────────────────────────────
  // onRequest — attach Bearer token
  // ─────────────────────────────────────────────────────────
  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _getActiveToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  // ─────────────────────────────────────────────────────────
  // onError — handle 401
  // ─────────────────────────────────────────────────────────
  @override
  Future<void> onError(
    DioException error,
    ErrorInterceptorHandler handler,
  ) async {
    // Only intercept 401 Unauthorized responses.
    if (error.response?.statusCode != 401) {
      handler.next(error);
      return;
    }

    // ── a) Refresh disabled — clear token, pass error ──────
    if (!_refreshConfig.enabled) {
      await _clearActiveAccountToken();
      handler.next(error);
      return;
    }

    // ── b) Refresh enabled ─────────────────────────────────

    // Guard: the refresh request itself returned 401 → full logout.
    final isRefreshRequest = error.requestOptions.extra[_kSkipRefresh] == true;
    if (isRefreshRequest) {
      await _clearActiveAccountToken();
      _resolveQueue(null); // reject all waiting requests
      handler.next(error);
      return;
    }

    // Guard: retried request still gets 401 → clear + forward.
    final retryCount = (error.requestOptions.extra['_retryCount'] as int?) ?? 0;
    if (retryCount >= _refreshConfig.maxRetries) {
      await _clearActiveAccountToken();
      handler.next(error);
      return;
    }

    // ── Queue this request ─────────────────────────────────
    // If a refresh is already in flight, park this request until it
    // resolves, then retry with whatever token comes back.
    if (_isRefreshing) {
      final completer = Completer<String?>();
      _queue.add(completer);

      try {
        final newToken = await completer.future;
        if (newToken == null) {
          handler.next(error);
          return;
        }
        final response = await _retryRequest(
          error.requestOptions,
          newToken,
          retryCount + 1,
        );
        handler.resolve(response);
      } catch (e) {
        handler.next(error);
      }
      return;
    }

    // ── This request is the first 401 — own the refresh ────
    _isRefreshing = true;

    try {
      final newToken = await _doRefresh();

      if (newToken == null) {
        // Refresh failed — clear token, reject everyone
        await _clearActiveAccountToken();
        _resolveQueue(null);
        handler.next(error);
        return;
      }

      // Persist new token to storage
      await _persistNewToken(newToken);

      // Unblock all queued requests with the new token
      _resolveQueue(newToken);

      // Retry the original request
      final response = await _retryRequest(
        error.requestOptions,
        newToken,
        retryCount + 1,
      );
      handler.resolve(response);
    } catch (e) {
      await _clearActiveAccountToken();
      _resolveQueue(null);
      handler.next(error);
    } finally {
      _isRefreshing = false;
    }
  }

  // ─────────────────────────────────────────────────────────
  // Refresh logic
  // ─────────────────────────────────────────────────────────

  /// Calls the refresh endpoint with the current token.
  /// Returns the new access token string, or null on any failure.
  Future<String?> _doRefresh() async {
    assert(
      _refreshConfig.refreshEndpoint != null,
      'TokenRefreshConfig.refreshEndpoint must not be null when enabled.',
    );

    final currentToken = await _getActiveToken();
    if (currentToken == null) return null;

    if (_dio == null) {
      debugPrint('[AuthInterceptor] Dio not set — cannot refresh token.');
      return null;
    }

    try {
      final response = await _dio!.post(
        _refreshConfig.refreshEndpoint!,
        options: Options(
          headers: {'Authorization': 'Bearer $currentToken'},
          extra: {_kSkipRefresh: true}, // prevent recursive 401 handling
        ),
      );

      final body = response.data;
      if (body is! Map<String, dynamic>) return null;

      return _refreshConfig.extractToken(body);
    } on DioException catch (e) {
      debugPrint(
        '[AuthInterceptor] Token refresh failed: ${e.response?.statusCode}',
      );
      return null;
    } catch (e) {
      debugPrint('[AuthInterceptor] Token refresh error: $e');
      return null;
    }
  }

  /// Retries [original] with [newToken] in the Authorization header.
  Future<Response<dynamic>> _retryRequest(
    RequestOptions original,
    String newToken,
    int retryCount,
  ) {
    assert(_dio != null, 'Dio must be set before retrying requests.');

    final options = original.copyWith(
      headers: {...original.headers, 'Authorization': 'Bearer $newToken'},
      extra: {...original.extra, '_retryCount': retryCount},
    );

    return _dio!.fetch(options);
  }

  /// Resolves all queued completers with [token].
  /// Passing null signals all waiters that refresh failed.
  void _resolveQueue(String? token) {
    for (final c in _queue) {
      if (!c.isCompleted) c.complete(token);
    }
    _queue.clear();
  }

  // ─────────────────────────────────────────────────────────
  // Storage helpers (unchanged from original)
  // ─────────────────────────────────────────────────────────

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

  /// Replaces only the 'token' field in the stored session JSON.
  /// All other session fields (user, permissions, savedAt) are preserved.
  Future<void> _persistNewToken(String newToken) async {
    final activeEmail = await _storage.read(AppConstants.activeAccountKey);
    if (activeEmail == null) return;

    final key = '${AppConstants.accountPrefix}$activeEmail';
    final sessionJson = await _storage.read(key);
    if (sessionJson == null) return;

    try {
      final session = jsonDecode(sessionJson) as Map<String, dynamic>;
      session['token'] = newToken;
      await _storage.write(key, jsonEncode(session));
    } catch (_) {}
  }

  /// Removes the 'token' field from the active session.
  /// Triggers AuthBloc → Unauthenticated on the next request.
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
