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
  final int dailyReportSubmissionRate;
  final int totalCustomers;
  final int customersVisitedThisMonth;
  final List<VisitEntity> recentVisits;
  final int activeOfficers;
  final DateTime generatedAt;

  const MarketingDashboardProjection({
    required this.totalVisits,
    required this.visitsByOfficer,
    required this.planComplianceRate,
    required this.dailyReportSubmissionRate,
    required this.totalCustomers,
    required this.customersVisitedThisMonth,
    required this.recentVisits,
    required this.activeOfficers,
    required this.generatedAt,
  });

  @override
  List<Object?> get props => [totalVisits, visitsByOfficer, planComplianceRate, dailyReportSubmissionRate, totalCustomers, customersVisitedThisMonth, recentVisits, activeOfficers, generatedAt];
}
