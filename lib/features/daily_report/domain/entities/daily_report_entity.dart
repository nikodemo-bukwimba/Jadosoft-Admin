import 'package:equatable/equatable.dart';
import '../value_objects/daily_report_status.dart';

class DailyReportEntity extends Equatable {
  final String id;
  final String officerId;
  final String? officerName;
  final String? officerEmail;
  final String? officerPhone;
  final String? officerRole;
  final String? officerStatus;
  final String? reportNumber;
  final DateTime reportDate;
  final DateTime? submittedAt;
  final DateTime? reviewedAt;
  final List<Map<String, dynamic>>? visitedCustomers;
  final String? keyOutcomes;
  final String? challengesFaced;
  final String? nextDayPlan;
  final String? customBody;
  final bool isCustomized;
  final String? reviewedByName;
  final String? reviewedByRole;
  final String? adminFeedback;
  final String? reviewDecision;
  final String status;
  final DateTime createdAt;

  const DailyReportEntity({
    required this.id,
    required this.officerId,
    this.officerName,
    this.officerEmail,
    this.officerPhone,
    this.officerRole,
    this.officerStatus,
    this.reportNumber,
    required this.reportDate,
    this.submittedAt,
    this.reviewedAt,
    this.visitedCustomers,
    this.keyOutcomes,
    this.challengesFaced,
    this.nextDayPlan,
    this.customBody,
    required this.isCustomized,
    this.reviewedByName,
    this.reviewedByRole,
    this.adminFeedback,
    this.reviewDecision,
    required this.status,
    required this.createdAt,
  });

  DailyReportEntity copyWith({
    String? id,
    String? officerId,
    String? officerName,
    String? officerEmail,
    String? officerPhone,
    String? officerRole,
    String? officerStatus,
    String? reportNumber,
    DateTime? reportDate,
    DateTime? submittedAt,
    DateTime? reviewedAt,
    List<Map<String, dynamic>>? visitedCustomers,
    String? keyOutcomes,
    String? challengesFaced,
    String? nextDayPlan,
    String? customBody,
    bool? isCustomized,
    String? reviewedByName,
    String? reviewedByRole,
    String? adminFeedback,
    String? reviewDecision,
    String? status,
    DateTime? createdAt,
  }) {
    return DailyReportEntity(
      id: id ?? this.id,
      officerId: officerId ?? this.officerId,
      officerName: officerName ?? this.officerName,
      officerEmail: officerEmail ?? this.officerEmail,
      officerPhone: officerPhone ?? this.officerPhone,
      officerRole: officerRole ?? this.officerRole,
      officerStatus: officerStatus ?? this.officerStatus,
      reportNumber: reportNumber ?? this.reportNumber,
      reportDate: reportDate ?? this.reportDate,
      submittedAt: submittedAt ?? this.submittedAt,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      visitedCustomers: visitedCustomers ?? this.visitedCustomers,
      keyOutcomes: keyOutcomes ?? this.keyOutcomes,
      challengesFaced: challengesFaced ?? this.challengesFaced,
      nextDayPlan: nextDayPlan ?? this.nextDayPlan,
      customBody: customBody ?? this.customBody,
      isCustomized: isCustomized ?? this.isCustomized,
      reviewedByName: reviewedByName ?? this.reviewedByName,
      reviewedByRole: reviewedByRole ?? this.reviewedByRole,
      adminFeedback: adminFeedback ?? this.adminFeedback,
      reviewDecision: reviewDecision ?? this.reviewDecision,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [id, officerId, officerName, officerEmail, officerPhone, officerRole, officerStatus, reportNumber, reportDate, submittedAt, reviewedAt, visitedCustomers, keyOutcomes, challengesFaced, nextDayPlan, customBody, isCustomized, reviewedByName, reviewedByRole, adminFeedback, reviewDecision, status, createdAt];
}
