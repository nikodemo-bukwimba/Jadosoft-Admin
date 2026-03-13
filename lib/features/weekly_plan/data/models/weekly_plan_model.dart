import '../../domain/entities/weekly_plan_entity.dart';

class WeeklyPlanModel extends WeeklyPlanEntity {
  const WeeklyPlanModel({
    required super.id,
    required super.officerId,
    required super.weekStart,
    required super.weekEnd,
    super.plannedCustomerIds,
    super.plannedActivities,
    super.notes,
    required super.status,
    super.submittedAt,
    super.reviewedAt,
    required super.createdAt,
  });

  factory WeeklyPlanModel.fromJson(Map<String, dynamic> json) =>
      WeeklyPlanModel(
        id: json['id']?.toString() ?? '',
        officerId: json['officer_id']?.toString() ?? '',
        weekStart: json['week_start'] != null
            ? DateTime.parse(json['week_start'].toString())
            : DateTime.now(),
        weekEnd: json['week_end'] != null
            ? DateTime.parse(json['week_end'].toString())
            : DateTime.now(),
        plannedCustomerIds: json['planned_customer_ids'] != null
            ? List<String>.from(json['planned_customer_ids'] as List)
            : null,
        plannedActivities: json['planned_activities'] as String?,
        notes: json['notes'] as String?,
        status: json['status'] as String? ?? 'draft',
        submittedAt: json['submitted_at'] != null
            ? DateTime.parse(json['submitted_at'].toString())
            : null,
        reviewedAt: json['reviewed_at'] != null
            ? DateTime.parse(json['reviewed_at'].toString())
            : null,
        createdAt: json['created_at'] != null
            ? DateTime.parse(json['created_at'].toString())
            : DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'officer_id': officerId,
    'week_start': weekStart.toIso8601String(),
    'week_end': weekEnd.toIso8601String(),
    'planned_customer_ids': plannedCustomerIds,
    'planned_activities': plannedActivities,
    'notes': notes,
    'status': status,
    'submitted_at': submittedAt?.toIso8601String(),
    'reviewed_at': reviewedAt?.toIso8601String(),
    'created_at': createdAt.toIso8601String(),
  };

  factory WeeklyPlanModel.fromEntity(WeeklyPlanEntity e) => WeeklyPlanModel(
    id: e.id,
    officerId: e.officerId,
    weekStart: e.weekStart,
    weekEnd: e.weekEnd,
    plannedCustomerIds: e.plannedCustomerIds,
    plannedActivities: e.plannedActivities,
    notes: e.notes,
    status: e.status,
    submittedAt: e.submittedAt,
    reviewedAt: e.reviewedAt,
    createdAt: e.createdAt,
  );
}
