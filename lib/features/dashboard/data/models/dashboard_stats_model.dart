// dashboard_stats_model.dart
// ─────────────────────────────────────────────────────────────
// Data-layer model: extends DashboardStats and adds JSON parsing.
//
// Expected API response shape (GET /admin/dashboard):
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
// All fields are parsed defensively — missing or null keys in the
// JSON simply map to null in the entity rather than throwing.
// ─────────────────────────────────────────────────────────────

import '../../domain/entities/dashboard_stats.dart';

class DashboardStatsModel extends DashboardStats {
  const DashboardStatsModel({
    super.totalUsers,
    super.newUsersThisMonth,
    super.activeSubscriptions,
    super.revenueThisMonth,
    super.pendingPayments,
    super.totalRevenue,
    required super.fetchedAt,
  });

  factory DashboardStatsModel.fromJson(Map<String, dynamic> json) {
    // The API may wrap data in a 'data' key or return it flat.
    final data = json['data'] is Map<String, dynamic>
        ? json['data'] as Map<String, dynamic>
        : json;

    return DashboardStatsModel(
      totalUsers: _parseInt(data['total_users']),
      newUsersThisMonth: _parseInt(data['new_users_this_month']),
      activeSubscriptions: _parseInt(data['active_subscriptions']),
      revenueThisMonth: _parseDouble(data['revenue_this_month']),
      pendingPayments: _parseInt(data['pending_payments']),
      totalRevenue: _parseDouble(data['total_revenue']),
      fetchedAt: DateTime.now(),
    );
  }

  // ── Safe parsers ──────────────────────────────────────────
  // The API may return numbers as int, double, or String.
  // All are handled without throwing.

  static int? _parseInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is double) return v.toInt();
    if (v is String) return int.tryParse(v);
    return null;
  }

  static double? _parseDouble(dynamic v) {
    if (v == null) return null;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    if (v is String) return double.tryParse(v);
    return null;
  }
}
