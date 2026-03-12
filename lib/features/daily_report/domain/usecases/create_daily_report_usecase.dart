import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/daily_report_entity.dart';
import '../repositories/daily_report_repository.dart';

class CreateDailyReportParams {
  final String officerId;
  final DateTime reportDate;
  final String? keyOutcomes;
  final String? challengesFaced;
  final String? nextDayPlan;
  final String? customBody;

  const CreateDailyReportParams({
    required this.officerId,
    required this.reportDate,
    this.keyOutcomes,
    this.challengesFaced,
    this.nextDayPlan,
    this.customBody,
  });
}

class CreateDailyReportUseCase implements UseCase<DailyReportEntity, CreateDailyReportParams> {
  final DailyReportRepository repository;
  CreateDailyReportUseCase(this.repository);

  @override
  Future<Either<Failure, DailyReportEntity>> call(CreateDailyReportParams p) async {
    // -- Validation gate --
    if (p.officerId.trim().isEmpty) {
      return const Left(ValidationFailure('Officer is required'));
    }

    return repository.create(
      DailyReportEntity(
        id: '',
        officerId: p.officerId.trim(),
        officerName: null,
        officerEmail: null,
        officerPhone: null,
        officerRole: null,
        officerStatus: null,
        reportNumber: '',
        reportDate: p.reportDate,
        submittedAt: null,
        reviewedAt: null,
        visitedCustomers: null,
        keyOutcomes: p.keyOutcomes?.trim(),
        challengesFaced: p.challengesFaced?.trim(),
        nextDayPlan: p.nextDayPlan?.trim(),
        customBody: p.customBody?.trim(),
        isCustomized: false,
        reviewedByName: null,
        reviewedByRole: null,
        adminFeedback: null,
        reviewDecision: null,
        status: '',
        createdAt: DateTime.now(),
      ),
    );
  }
}
