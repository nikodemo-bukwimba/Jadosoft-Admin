// TODO Implement this library.
// dashboard_stats.dart
// ─────────────────────────────────────────────────────────────
// Pure Dart domain entity — no Flutter, no Drift, no Dio imports.
//
// Represents the aggregated summary data shown on the admin
// dashboard. All numeric fields are nullable so a partial
// response from the API degrades gracefully (shows '—' in the UI)
// rather than throwing.
//
// Backend contract expected (GET /admin/dashboard):
// {
//   "data": {
//     "total_users":            150,
//     "new_users_this_month":   12,
//     "active_subscriptions":   45,
//     "revenue_this_month":     12500.00,
//     "pending_payments":       3,
//     "total_revenue":          98000.00
//   }
// }
//
// Fields your backend does not return simply remain null — the
// stat card renders '—' and no exception is thrown.
//
// Extending for your project:
//   Add fields here → add parsing in DashboardStatsModel.fromJson()
//   → add a stat card in DashboardPage._StatCardGrid.
// ─────────────────────────────────────────────────────────────

class DashboardStats {
  /// Total registered users in the system.
  final int? totalUsers;

  /// New user registrations in the current calendar month.
  final int? newUsersThisMonth;

  /// Currently active (non-expired) subscriptions.
  final int? activeSubscriptions;

  /// Revenue collected in the current calendar month.
  final double? revenueThisMonth;

  /// Payments awaiting processing or confirmation.
  final int? pendingPayments;

  /// Cumulative total revenue across all time.
  final double? totalRevenue;

  /// When this snapshot was fetched from the server.
  final DateTime fetchedAt;

  const DashboardStats({
    this.totalUsers,
    this.newUsersThisMonth,
    this.activeSubscriptions,
    this.revenueThisMonth,
    this.pendingPayments,
    this.totalRevenue,
    required this.fetchedAt,
  });

  /// True when every numeric field is null — suggests the backend
  /// returned an empty data object rather than actual values.
  bool get isEmpty =>
      totalUsers == null &&
      newUsersThisMonth == null &&
      activeSubscriptions == null &&
      revenueThisMonth == null &&
      pendingPayments == null &&
      totalRevenue == null;
}
