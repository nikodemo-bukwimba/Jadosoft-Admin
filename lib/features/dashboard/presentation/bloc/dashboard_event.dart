// dashboard_event.dart
// ─────────────────────────────────────────────────────────────
// Events that DashboardBloc handles.
// ─────────────────────────────────────────────────────────────

abstract class DashboardEvent {}

/// Triggered once when the DashboardPage first mounts.
/// Fetches all dashboard stats via GetDashboardStatsUseCase.
class DashboardLoadRequested extends DashboardEvent {}

/// Triggered by pull-to-refresh on the DashboardPage.
/// Same behaviour as [DashboardLoadRequested] but always refetches
/// even if data is already loaded (bypasses any cache).
class DashboardRefreshRequested extends DashboardEvent {}