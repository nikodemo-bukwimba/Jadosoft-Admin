// token_refresh_config.dart
// ─────────────────────────────────────────────────────────────
// Controls whether AuthInterceptor attempts token refresh on 401.
//
// Design principle: opt-in, never opt-out-by-accident.
//   - Default is TokenRefreshConfig.disabled().
//   - Backends that do not expire tokens (e.g. Laravel Sanctum with
//     default settings) work exactly as before — no code change needed.
//   - Backends that DO expire tokens enable refresh by swapping in
//     TokenRefreshConfig.enabled(...) in injection_container.dart.
//
// Backend contract expected by TokenRefreshConfig.enabled():
//   POST  {refreshEndpoint}
//   Headers: Authorization: Bearer <current_token>
//   Response 200: JSON body containing the new access token
//   Response 401: refresh itself is invalid → full logout
//
// Common endpoint values by backend:
//   Laravel Sanctum (with expiry) : '/sanctum/token/refresh'  (custom)
//   Laravel Passport               : '/oauth/token/refresh'
//   JWT / custom                   : '/auth/refresh'
//
// tokenExtractor examples:
//   Sanctum / custom  : (res) => res['token']
//   Passport          : (res) => res['access_token']
//   JWT               : (res) => res['data']['access_token']
// ─────────────────────────────────────────────────────────────

/// Opt-in configuration for token refresh behaviour in [AuthInterceptor].
class TokenRefreshConfig {
  /// Whether the interceptor should attempt a token refresh on 401.
  final bool enabled;

  /// API path for the refresh endpoint relative to [AppConstants.baseUrl].
  /// Required when [enabled] is true.
  final String? refreshEndpoint;

  /// Extracts the new access token from the refresh response body.
  /// Defaults to reading `response['token']`.
  final String? Function(Map<String, dynamic> responseBody)? tokenExtractor;

  /// How many times a single original request is retried after a
  /// successful refresh. Should almost always be 1.
  final int maxRetries;

  // ── Named constructors ────────────────────────────────────

  /// Token refresh is OFF.
  /// 401 behaviour: clear the active account token and pass the error
  /// downstream so AuthBloc can emit [AuthUnauthenticated].
  const TokenRefreshConfig.disabled()
    : enabled = false,
      refreshEndpoint = null,
      tokenExtractor = null,
      maxRetries = 0;

  /// Token refresh is ON.
  ///
  /// [refreshEndpoint] — path relative to base URL, e.g. '/auth/refresh'.
  /// [tokenExtractor]  — how to pull the new token from the JSON body.
  ///                     Defaults to `body['token']`.
  /// [maxRetries]      — retry attempts per request after refresh. Default: 1.
  const TokenRefreshConfig.enabled({
    required String refreshEndpoint,
    String? Function(Map<String, dynamic>)? tokenExtractor,
    int maxRetries = 1,
  }) : enabled = true,
       refreshEndpoint = refreshEndpoint,
       tokenExtractor = tokenExtractor,
       maxRetries = maxRetries;

  // ── Token extractor helper ────────────────────────────────

  /// Runs [tokenExtractor] against [body], falling back to the common
  /// `token` and `access_token` keys if no extractor is provided.
  String? extractToken(Map<String, dynamic> body) {
    if (tokenExtractor != null) return tokenExtractor!(body);
    // Fallback: try the two most common key names
    return (body['token'] as String?) ?? (body['access_token'] as String?);
  }
}
