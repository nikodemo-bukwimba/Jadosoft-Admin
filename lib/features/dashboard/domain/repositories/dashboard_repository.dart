// dashboard_repository.dart
// ─────────────────────────────────────────────────────────────
// Abstract interface — domain layer depends only on this.
// The data layer (DashboardRepositoryImpl) provides the
// concrete implementation wired via injection_container.dart.
// ─────────────────────────────────────────────────────────────

import 'package:dartz/dartz.dart';
import 'package:admin_panel/core/error/failures.dart';

import '../entities/dashboard_stats.dart';

abstract class DashboardRepository {
  /// Fetch aggregated admin dashboard statistics from the API.
  ///
  /// Returns [DashboardStats] on success.
  /// Returns a [Failure] subtype on any network, server, or auth error.
  Future<Either<Failure, DashboardStats>> getDashboardStats();
}
