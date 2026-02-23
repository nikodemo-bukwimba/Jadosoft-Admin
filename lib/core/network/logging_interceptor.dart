// logging_interceptor.dart  [R9 — Logging & Debug Output]
// ─────────────────────────────────────────────────────────────
// Only active in debug builds (kDebugMode guard).
// NEVER logs: tokens, passwords, response bodies, PII.
// Logs only: HTTP method, path, status code.
// ─────────────────────────────────────────────────────────────

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (kDebugMode) {
      debugPrint('[HTTP →] ${options.method} ${options.path}');
    }
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (kDebugMode) {
      debugPrint('[HTTP ←] ${response.statusCode} ${response.realUri.path}');
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (kDebugMode) {
      debugPrint('[HTTP ✗] ${err.response?.statusCode} ${err.message}');
    }
    handler.next(err);
  }
}
