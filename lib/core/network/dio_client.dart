// dio_client.dart  [R3 — Secure Network Communication]
// ─────────────────────────────────────────────────────────────
// Single shared Dio instance for the entire app.
// Base URL sourced from AppConstants — never hardcoded here.
// Rules enforced:
//   - Timeouts: connect 15s, receive 30s
//   - Auth token attached via AuthInterceptor
//   - Debug logging guarded by kDebugMode (R9)
//   - Never instantiate Dio anywhere else in the app
//
// CHANGE: Calls authInterceptor.setDio(dio) after Dio is created.
// This resolves the circular dependency (AuthInterceptor needs Dio
// to retry requests, but Dio needs AuthInterceptor to attach tokens).
// The call is synchronous and happens before any request is possible.
// ─────────────────────────────────────────────────────────────

import 'package:dio/dio.dart';

import '../constants/app_constants.dart';
import 'auth_interceptor.dart';
import 'logging_interceptor.dart';

Dio buildSecureDioClient({required AuthInterceptor authInterceptor}) {
  final dio = Dio(
    BaseOptions(
      baseUrl: AppConstants.baseUrl,
      connectTimeout: const Duration(
        seconds: AppConstants.connectTimeoutSeconds,
      ),
      receiveTimeout: const Duration(
        seconds: AppConstants.receiveTimeoutSeconds,
      ),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  );

  dio.interceptors.addAll([
    authInterceptor, // attaches Bearer token + handles 401 refresh (R4)
    LoggingInterceptor(), // debug only — never logs tokens or PII (R9)
  ]);

  // ── Resolve circular dependency ────────────────────────────
  // AuthInterceptor needs this Dio reference to replay queued requests
  // after a token refresh. Safe to set here because no request has
  // been made yet and setDio() is a simple field assignment.
  authInterceptor.setDio(dio);

  return dio;
}
