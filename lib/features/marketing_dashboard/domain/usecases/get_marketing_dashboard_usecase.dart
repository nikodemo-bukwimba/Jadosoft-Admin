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

    // Visits
    final totalVisits = visitList.length;
    final visitsByOfficer = <String, int>{};
    for (final e in visitList) {
      final key = e.officerId.toString();
      visitsByOfficer[key] = (visitsByOfficer[key] ?? 0) + 1;
    }

    // Weekly plan status counts — derived from real status values
    final approvedCount = weeklyPlanList
        .where((e) => e.status == 'approved')
        .length;
    final rejectedCount = weeklyPlanList
        .where((e) => e.status == 'rejected')
        .length;
    // Anything that is not approved or rejected is treated as pending
    final pendingCount = weeklyPlanList.length - approvedCount - rejectedCount;
    final planComplianceRate = weeklyPlanList.isEmpty
        ? 0.0
        : approvedCount / weeklyPlanList.length;

    // Daily reports
    final dailyReportSubmissionRate = dailyReportList.length;

    // Customers
    final totalCustomers = customerList.length;
    // Distinct customers visited (not raw visit count)
    final distinctVisitedCustomerIds = visitList
        .map((v) => v.customerId)
        .toSet();
    final customersVisitedThisMonth = distinctVisitedCustomerIds.length;

    // Recent visits
    final sortedRecentVisits = List.of(visitList)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final recentVisits = sortedRecentVisits.take(10).toList();

    final activeOfficers = officerList.length;

    return Right(
      MarketingDashboardProjection(
        totalVisits: totalVisits,
        visitsByOfficer: visitsByOfficer,
        planComplianceRate: planComplianceRate,
        approvedPlanCount: approvedCount,
        pendingPlanCount: pendingCount,
        rejectedPlanCount: rejectedCount,
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
