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

  Future<Either<Failure, DailyReportEntity>> transition({
    required String id,
    required DailyReportStatus targetStatus,
    String? feedback,
  }) async {
    switch (targetStatus) {
      case DailyReportStatus.approved:
        if (feedback == null || feedback.trim().isEmpty) {
          return const Left(ValidationFailure('Feedback is required'));
        }
        return repository.approve(id, feedback: feedback);

      case DailyReportStatus.rejected:
        if (feedback == null || feedback.trim().isEmpty) {
          return const Left(ValidationFailure('Feedback is required'));
        }
        return repository.reject(id, feedback: feedback);

      case DailyReportStatus.submitted:
        final loadResult = await repository.getById(id);
        return loadResult.fold(
          Left.new,
          (entity) => repository.update(entity.copyWith(status: 'submitted')),
        );

      default:
        return const Left(ValidationFailure('Transition not supported'));
    }
  }
}