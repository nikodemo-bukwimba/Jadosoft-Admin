import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/daily_report_entity.dart';
import '../guards/daily_report_transition_guard.dart';
import '../repositories/daily_report_repository.dart';
import '../value_objects/daily_report_status.dart';

class DailyReportDomainService {
  final DailyReportRepository repository;
  final DailyReportTransitionGuard guard;

  DailyReportDomainService({required this.repository, required this.guard});

  /// Performs a status transition: load, guard, apply, persist.
  Future<Either<Failure, DailyReportEntity>> transition({
    required String id,
    required DailyReportStatus targetStatus,
  }) async {
    // 1. Load
    final loadResult = await repository.getById(id);
    if (loadResult.isLeft()) return loadResult;
    final entity = loadResult.getOrElse(() => throw StateError('unreachable'));

    // 2. Guard
    final guardResult = guard.validate(
      current: DailyReportStatusX.fromString(
        entity.status,
      ), // was: entity.status
      target: targetStatus,
    );
    if (guardResult.isLeft()) {
      return guardResult.fold(
        (f) => Left(f),
        (_) => throw StateError('unreachable'),
      );
    }
    final validTarget = guardResult.getOrElse(
      () => throw StateError('unreachable'),
    );

    // 3. Apply + Persist
    final updated = entity.copyWith(status: validTarget.name);
    return repository.update(updated);
  }
}
