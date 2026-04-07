import 'package:equatable/equatable.dart';
import '../../../visit/domain/entities/visit_entity.dart';
import '../../../weekly_plan/domain/entities/weekly_plan_entity.dart';
import '../../../daily_report/domain/entities/daily_report_entity.dart';
import '../../../officer/domain/entities/officer_entity.dart';
import '../../../customer/domain/entities/customer_entity.dart';

class MarketingDashboardProjection extends Equatable {
  final int totalVisits;
  final Map<String, int> visitsByOfficer;
  final double planComplianceRate;
  final int approvedPlanCount;
  final int pendingPlanCount;
  final int rejectedPlanCount;
  final int dailyReportSubmissionRate;
  final int totalCustomers;
  final int customersVisitedThisMonth;
  final List<VisitEntity> recentVisits;
  final int activeOfficers;
  final List<OfficerEntity> allOfficers;
  final DateTime generatedAt;

  const MarketingDashboardProjection({
    required this.totalVisits,
    required this.visitsByOfficer,
    required this.planComplianceRate,
    required this.approvedPlanCount,
    required this.pendingPlanCount,
    required this.rejectedPlanCount,
    required this.dailyReportSubmissionRate,
    required this.totalCustomers,
    required this.customersVisitedThisMonth,
    required this.recentVisits,
    required this.activeOfficers,
    required this.allOfficers,
    required this.generatedAt,
  });

  @override
  List<Object?> get props => [
    totalVisits,
    visitsByOfficer,
    planComplianceRate,
    approvedPlanCount,
    pendingPlanCount,
    rejectedPlanCount,
    dailyReportSubmissionRate,
    totalCustomers,
    customersVisitedThisMonth,
    recentVisits,
    activeOfficers,
    allOfficers,
    generatedAt,
  ];
}
