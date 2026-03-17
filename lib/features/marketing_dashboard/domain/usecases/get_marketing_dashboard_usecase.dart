import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../projections/marketing_dashboard_projection.dart';
import '../providers/visit_data_provider.dart';
import '../providers/weekly_plan_data_provider.dart';
import '../providers/daily_report_data_provider.dart';
import '../providers/officer_data_provider.dart';
import '../providers/customer_data_provider.dart';

class GetMarketingDashboardUseCase {
  final VisitDataProvider _visitProvider;
  final WeeklyPlanDataProvider _weeklyPlanProvider;
  final DailyReportDataProvider _dailyReportProvider;
  final OfficerDataProvider _officerProvider;
  final CustomerDataProvider _customerProvider;

  GetMarketingDashboardUseCase({
    required VisitDataProvider visitProvider,
    required WeeklyPlanDataProvider weeklyPlanProvider,
    required DailyReportDataProvider dailyReportProvider,
    required OfficerDataProvider officerProvider,
    required CustomerDataProvider customerProvider,
  }) : _visitProvider = visitProvider,
       _weeklyPlanProvider = weeklyPlanProvider,
       _dailyReportProvider = dailyReportProvider,
       _officerProvider = officerProvider,
       _customerProvider = customerProvider;

  Future<Either<Failure, MarketingDashboardProjection>> call() async {
    final visitResult = await _visitProvider.getAll();
    if (visitResult.isLeft()) {
      return visitResult.fold(
        (f) => Left(f),
        (_) => throw StateError('unreachable'),
      );
    }
    final visitList = visitResult.getOrElse(
      () => throw StateError('unreachable'),
    );
    final weeklyPlanResult = await _weeklyPlanProvider.getAll();
    if (weeklyPlanResult.isLeft()) {
      return weeklyPlanResult.fold(
        (f) => Left(f),
        (_) => throw StateError('unreachable'),
      );
    }
    final weeklyPlanList = weeklyPlanResult.getOrElse(
      () => throw StateError('unreachable'),
    );
    final dailyReportResult = await _dailyReportProvider.getAll();
    if (dailyReportResult.isLeft()) {
      return dailyReportResult.fold(
        (f) => Left(f),
        (_) => throw StateError('unreachable'),
      );
    }
    final dailyReportList = dailyReportResult.getOrElse(
      () => throw StateError('unreachable'),
    );
    final customerResult = await _customerProvider.getAll();
    if (customerResult.isLeft()) {
      return customerResult.fold(
        (f) => Left(f),
        (_) => throw StateError('unreachable'),
      );
    }
    final customerList = customerResult.getOrElse(
      () => throw StateError('unreachable'),
    );
    final officerResult = await _officerProvider.getAll();
    if (officerResult.isLeft()) {
      return officerResult.fold(
        (f) => Left(f),
        (_) => throw StateError('unreachable'),
      );
    }
    final officerList = officerResult.getOrElse(
      () => throw StateError('unreachable'),
    );

    final totalVisits = visitList.length;
    final visitsByOfficer = <String, int>{};
    for (final e in visitList) {
      final key = e.officerId.toString();
      visitsByOfficer[key] = (visitsByOfficer[key] ?? 0) + 1;
    }
    final planComplianceRate = weeklyPlanList.isEmpty
        ? 0.0
        : weeklyPlanList.where((e) => e.status == 'approved').length /
              weeklyPlanList.length;

    final dailyReportSubmissionRate = dailyReportList.length;
    final totalCustomers = customerList.length;
    final customersVisitedThisMonth = visitList.length;
    final sortedrecentVisits = List.of(visitList)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final recentVisits = sortedrecentVisits.take(10).toList();
    final activeOfficers = officerList.length;

    return Right(
      MarketingDashboardProjection(
        totalVisits: totalVisits,
        visitsByOfficer: visitsByOfficer,
        planComplianceRate: planComplianceRate,
        dailyReportSubmissionRate: dailyReportSubmissionRate,
        totalCustomers: totalCustomers,
        customersVisitedThisMonth: customersVisitedThisMonth,
        recentVisits: recentVisits,
        activeOfficers: activeOfficers,
        allOfficers: List.from(officerList),
        generatedAt: DateTime.now(),
      ),
    );
  }
}
