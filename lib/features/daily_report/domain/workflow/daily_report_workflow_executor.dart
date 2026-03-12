import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/daily_report_entity.dart';
import '../events/daily_report_domain_events.dart';

class DailyReportWorkflowExecutor {
  final List<DailyReportDomainEvent> _emittedEvents = [];

  List<DailyReportDomainEvent> get emittedEvents => List.unmodifiable(_emittedEvents);

  void clearEvents() => _emittedEvents.clear();

  /// Executes the full workflow for the given entity.
  /// Steps run in order; on failure, completed steps are rolled back.
  Future<Either<Failure, DailyReportEntity>> execute(DailyReportEntity entity) async {
    _emittedEvents.clear();
    final completedSteps = <String>[];
    var current = entity;
    Either<Failure, DailyReportEntity> result;

    // Step: Notify Admin on Submission
    result = await _notifyAdminOnSubmit(current);
    if (result.isLeft()) {
      await _rollback(entity, completedSteps);
      return result;
    }
    current = result.getOrElse(() => current);
    completedSteps.add('notifyAdminOnSubmit');
    // Step: Notify Officer on Approval
    result = await _notifyOfficerApproved(current);
    if (result.isLeft()) {
      await _rollback(entity, completedSteps);
      return result;
    }
    current = result.getOrElse(() => current);
    completedSteps.add('notifyOfficerApproved');
    // Step: Notify Officer on Rejection
    result = await _notifyOfficerRejected(current);
    if (result.isLeft()) {
      await _rollback(entity, completedSteps);
      return result;
    }
    current = result.getOrElse(() => current);
    completedSteps.add('notifyOfficerRejected');

    return Right(current);
  }

  /// Step: Notify Admin on Submission
  Future<Either<Failure, DailyReportEntity>> _notifyAdminOnSubmit(DailyReportEntity entity) async {
    // -- HUMAN CUSTOMIZATION ZONE --
    // Implement: Notify Admin on Submission
    // Return Right(entity) on success, Left(Failure) on failure.
    // -- END CUSTOMIZATION ZONE --
    return Right(entity);
  }
  /// Step: Notify Officer on Approval
  Future<Either<Failure, DailyReportEntity>> _notifyOfficerApproved(DailyReportEntity entity) async {
    // -- HUMAN CUSTOMIZATION ZONE --
    // Implement: Notify Officer on Approval
    // Return Right(entity) on success, Left(Failure) on failure.
    // -- END CUSTOMIZATION ZONE --
    return Right(entity);
  }
  /// Step: Notify Officer on Rejection
  Future<Either<Failure, DailyReportEntity>> _notifyOfficerRejected(DailyReportEntity entity) async {
    // -- HUMAN CUSTOMIZATION ZONE --
    // Implement: Notify Officer on Rejection
    // Return Right(entity) on success, Left(Failure) on failure.
    // -- END CUSTOMIZATION ZONE --
    return Right(entity);
  }

  Future<void> _rollback(DailyReportEntity entity, List<String> completedSteps) async {
    for (final step in completedSteps.reversed) {
      switch (step) {
      case 'notifyAdminOnSubmit': break; // TODO: rollback Notify Admin on Submission
      case 'notifyOfficerApproved': break; // TODO: rollback Notify Officer on Approval
      case 'notifyOfficerRejected': break; // TODO: rollback Notify Officer on Rejection
      }
    }
  }

  void _emit(DailyReportDomainEvent event) => _emittedEvents.add(event);
}
