// get_dashboard_stats_usecase.dart
// ─────────────────────────────────────────────────────────────
// Fetches aggregated dashboard statistics for the admin panel.
// No business logic beyond delegation — the repository owns
// the data-fetching concern.
// ─────────────────────────────────────────────────────────────

import 'package:dartz/dartz.dart';
import 'package:admin_panel/core/error/failures.dart';
import 'package:admin_panel/core/usecase/usecase.dart';

import '../entities/dashboard_stats.dart';
import '../repositories/dashboard_repository.dart';

class GetDashboardStatsUseCase implements UseCase<DashboardStats, NoParams> {
  final DashboardRepository _repository;

  GetDashboardStatsUseCase(this._repository);

  @override
  Future<Either<Failure, DashboardStats>> call(NoParams _) =>
      _repository.getDashboardStats();
}
