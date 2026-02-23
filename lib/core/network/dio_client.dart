// dio_client.dart  [R3 — Secure Network Communication]
// ─────────────────────────────────────────────────────────────
// Single shared Dio instance for the entire app.
// Base URL sourced from AppConstants — never hardcoded here.
// Rules enforced:
//   - Timeouts: connect 15s, receive 30s
//   - Auth token attached via AuthInterceptor
//   - Debug logging guarded by kDebugMode (R9)
//   - Never instantiate Dio anywhere else in the app
// ─────────────────────────────────────────────────────────────

import 'package:dio/dio.dart';
import 'package:fca/core/constants/app_constants.dart';
 
import 'auth_interceptor.dart';
import 'logging_interceptor.dart';

Dio buildSecureDioClient({
  required AuthInterceptor authInterceptor,
}) {
  final dio = Dio(
    BaseOptions(
      baseUrl:        AppConstants.baseUrl,
      connectTimeout: const Duration(seconds: AppConstants.connectTimeoutSeconds),
      receiveTimeout: const Duration(seconds: AppConstants.receiveTimeoutSeconds),
      headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
    ),
  );

  dio.interceptors.addAll([
    authInterceptor,    // attaches Bearer token on every request (R4)
    LoggingInterceptor(), // debug only — never logs tokens or PII (R9)
  ]);

  return dio;
}
