import '../../domain/entities/daily_report_entity.dart';
import '../../domain/value_objects/daily_report_status.dart';

class DailyReportModel extends DailyReportEntity {
  const DailyReportModel({
    required super.id,
    required super.officerId,
    super.officerName,
    super.officerEmail,
    super.officerPhone,
    super.officerRole,
    super.officerStatus,
    super.reportNumber,
    required super.reportDate,
    super.submittedAt,
    super.reviewedAt,
    super.visitedCustomers,
    super.keyOutcomes,
    super.challengesFaced,
    super.nextDayPlan,
    super.customBody,
    required super.isCustomized,
    super.reviewedByName,
    super.reviewedByRole,
    super.adminFeedback,
    super.reviewDecision,
    required super.status,
    required super.createdAt,
  });

  factory DailyReportModel.fromJson(Map<String, dynamic> json) {
    return DailyReportModel(
      id: json['id'] as String,
      officerId: json['officer_id'] as String,
      officerName: json['officer_name'] as String?,
      officerEmail: json['officer_email'] as String?,
      officerPhone: json['officer_phone'] as String?,
      officerRole: json['officer_role'] as String?,
      officerStatus: json['officer_status'] as String?,
      reportNumber: json['report_number'] as String?,
      reportDate: DateTime.parse(json['report_date'] as String),
      submittedAt: json['submitted_at'] != null
          ? DateTime.parse(json['submitted_at'] as String)
          : null,
      reviewedAt: json['reviewed_at'] != null
          ? DateTime.parse(json['reviewed_at'] as String)
          : null,
      visitedCustomers: json['visited_customers'] != null
          ? List<Map<String, dynamic>>.from(json['visited_customers'])
          : null,
      keyOutcomes: json['key_outcomes'] as String?,
      challengesFaced: json['challenges_faced'] as String?,
      nextDayPlan: json['next_day_plan'] as String?,
      customBody: json['custom_body'] as String?,
      isCustomized: json['is_customized'] as bool? ?? false,
      reviewedByName: json['reviewed_by_name'] as String?,
      reviewedByRole: json['reviewed_by_role'] as String?,
      adminFeedback: json['admin_feedback'] as String?,
      reviewDecision: json['review_decision'] as String?,
      status: json['status'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'officer_id': officerId,
    'officer_name': officerName,
    'officer_email': officerEmail,
    'officer_phone': officerPhone,
    'officer_role': officerRole,
    'officer_status': officerStatus,
    'report_number': reportNumber,
    'report_date': reportDate.toIso8601String(),
    'submitted_at': submittedAt?.toIso8601String(),
    'reviewed_at': reviewedAt?.toIso8601String(),
    'visited_customers': visitedCustomers,
    'key_outcomes': keyOutcomes,
    'challenges_faced': challengesFaced,
    'next_day_plan': nextDayPlan,
    'custom_body': customBody,
    'is_customized': isCustomized,
    'reviewed_by_name': reviewedByName,
    'reviewed_by_role': reviewedByRole,
    'admin_feedback': adminFeedback,
    'review_decision': reviewDecision,
    'status': status,
    'created_at': createdAt.toIso8601String(),
  };

  factory DailyReportModel.fromEntity(DailyReportEntity entity) {
    return DailyReportModel(
      id: entity.id,
      officerId: entity.officerId,
      officerName: entity.officerName,
      officerEmail: entity.officerEmail,
      officerPhone: entity.officerPhone,
      officerRole: entity.officerRole,
      officerStatus: entity.officerStatus,
      reportNumber: entity.reportNumber,
      reportDate: entity.reportDate,
      submittedAt: entity.submittedAt,
      reviewedAt: entity.reviewedAt,
      visitedCustomers: entity.visitedCustomers,
      keyOutcomes: entity.keyOutcomes,
      challengesFaced: entity.challengesFaced,
      nextDayPlan: entity.nextDayPlan,
      customBody: entity.customBody,
      isCustomized: entity.isCustomized,
      reviewedByName: entity.reviewedByName,
      reviewedByRole: entity.reviewedByRole,
      adminFeedback: entity.adminFeedback,
      reviewDecision: entity.reviewDecision,
      status: entity.status,
      createdAt: entity.createdAt,
    );
  }
}