// app_constants.dart
// ─────────────────────────────────────────────────────────────
// Single source of truth for global app constants.
// Change baseUrl here — nowhere else in the codebase.
// ─────────────────────────────────────────────────────────────

class AppConstants {
  AppConstants._();

  // ── API ────────────────────────────────────────────────────
  // local        → http://localhost:8000/api
  // production   → https://dev.halasoftware.com/api
  //static const String baseUrl = 'http://localhost:8000/api/v1';
  static const String baseUrl = 'http://192.168.100.34:8000/api/v1';

  // ── Network timeouts ───────────────────────────────────────
  static const int connectTimeoutSeconds = 15;
  static const int receiveTimeoutSeconds = 30;

  // ── Secure storage keys ────────────────────────────────────
  // Tracks which account is currently active (stores email).
  static const String activeAccountKey = 'active_account_email';

  // Per-account session prefix — full key: account_{email}
  static const String accountPrefix = 'account_';

  // ── Session policy ─────────────────────────────────────────
  // Minutes before background session requires re-auth (R4).
  static const int sessionTimeoutMinutes = 10;

  // ── Local cache TTL (Drift database) ──────────────────────
  // How many minutes a cached response is considered fresh.
  // After this, the repository fetches from the API and updates
  // the cache. Stale cache is still returned on network failure.

  /// Profile snapshot TTL — 5 minutes.
  /// Covers normal in-app navigation without unnecessary API calls.
  static const int profileCacheTtlMinutes = 5;

  /// Dashboard stats TTL — 2 minutes.
  /// Short because admin data (user counts, revenue) changes frequently.
  static const int dashboardCacheTtlMinutes = 2;

  //-----------
  static const int actorCacheTtlMinutes = 10;
}
