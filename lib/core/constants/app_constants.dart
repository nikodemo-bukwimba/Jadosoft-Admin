// app_constants.dart
// ─────────────────────────────────────────────────────────────
// Single source of truth for global app constants.
// Change baseUrl here — nowhere else in the codebase.
// ─────────────────────────────────────────────────────────────

class AppConstants {
  AppConstants._();

  // ── API ────────────────────────────────────────────────────
  // Change this to your production URL before release.
  // Android emulator  → http://10.0.2.2:8000/api
  // iOS simulator     → http://localhost:8000/api
  // Physical device   → http://<your-machine-ip>:8000/api
  static const String baseUrl = 'http://localhost:8000/api';

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
}
