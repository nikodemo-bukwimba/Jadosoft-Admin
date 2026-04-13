// dashboard_bloc.dart
// ─────────────────────────────────────────────────────────────
// Manages dashboard data lifecycle.
//
// Events handled:
//   DashboardLoadRequested    → full-screen loading spinner, then data/error
//   DashboardRefreshRequested → keeps current data visible, refreshes quietly
//
// State transitions:
//   Initial ──load──▶ Loading ──success──▶ Loaded
//                             ──failure──▶ Error
//
//   Loaded ──refresh──▶ Loaded(isRefreshing: true) ──success──▶ Loaded
//                                                   ──failure──▶ Error(previousStats)
//
// The [previousStats] field on DashboardError lets the page keep
// showing stale data with an error banner when a refresh fails,
// rather than replacing the whole page with an error view.
// ─────────────────────────────────────────────────────────────

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jadosoft_admin/core/usecase/usecase.dart';

import '../../domain/entities/dashboard_stats.dart';
import '../../domain/usecases/get_dashboard_stats_usecase.dart';
import 'dashboard_event.dart';
import 'dashboard_state.dart';

class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  final GetDashboardStatsUseCase _getDashboardStats;

  DashboardBloc({
    required GetDashboardStatsUseCase getDashboardStats,
  })  : _getDashboardStats = getDashboardStats,
        super(DashboardInitial()) {
    on<DashboardLoadRequested>(_onLoadRequested);
    on<DashboardRefreshRequested>(_onRefreshRequested);
  }

  // ── Initial load ──────────────────────────────────────────
  // Shows full-screen loading indicator (no prior data exists).
  Future<void> _onLoadRequested(
    DashboardLoadRequested event,
    Emitter<DashboardState> emit,
  ) async {
    emit(DashboardLoading());
    await _fetch(emit, previousStats: null);
  }

  // ── Pull-to-refresh ───────────────────────────────────────
  // Keeps current data visible while refetching in background.
  Future<void> _onRefreshRequested(
    DashboardRefreshRequested event,
    Emitter<DashboardState> emit,
  ) async {
    // Extract current stats before emitting the refreshing state
    final current = state is DashboardLoaded
        ? (state as DashboardLoaded).stats
        : null;

    if (current != null) {
      emit(DashboardLoaded(stats: current, isRefreshing: true));
    }

    await _fetch(emit, previousStats: current);
  }

  // ── Shared fetch logic ────────────────────────────────────
  Future<void> _fetch(
    Emitter<DashboardState> emit, {
    required DashboardStats? previousStats,
  }) async {
    final result = await _getDashboardStats(NoParams());

    result.fold(
      (failure) => emit(
        DashboardError(failure.message, previousStats: previousStats),
      ),
      (stats) => emit(DashboardLoaded(stats: stats)),
    );
  }
}