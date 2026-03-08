// dashboard_state.dart
// ─────────────────────────────────────────────────────────────
// States emitted by DashboardBloc.
// ─────────────────────────────────────────────────────────────

import '../../domain/entities/dashboard_stats.dart';

abstract class DashboardState {}

/// Before any load has been requested.
class DashboardInitial extends DashboardState {}

/// Full-screen loading — first load only (no prior data to show).
class DashboardLoading extends DashboardState {}

/// Data is loaded and ready to render.
class DashboardLoaded extends DashboardState {
  final DashboardStats stats;

  /// True while a background pull-to-refresh is in progress.
  /// The page keeps the current [stats] visible and overlays a spinner.
  final bool isRefreshing;

  DashboardLoaded({required this.stats, this.isRefreshing = false});

  DashboardLoaded copyWith({DashboardStats? stats, bool? isRefreshing}) =>
      DashboardLoaded(
        stats: stats ?? this.stats,
        isRefreshing: isRefreshing ?? this.isRefreshing,
      );
}

/// A load or refresh attempt failed.
class DashboardError extends DashboardState {
  final String message;

  /// The last successfully loaded stats, if any.
  /// Present when a refresh fails — lets the UI keep showing
  /// stale data with an error banner instead of a blank screen.
  final DashboardStats? previousStats;

  DashboardError(this.message, {this.previousStats});
}
