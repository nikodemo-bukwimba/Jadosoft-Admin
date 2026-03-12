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

  factory WeeklyPlanModel.fromJson(Map<String, dynamic> json) {
    return WeeklyPlanModel(
      id: json['id'] as String,
      officerId: json['officer_id'] as String,
      weekStart: DateTime.parse(json['week_start'] as String),
      weekEnd: DateTime.parse(json['week_end'] as String),
      plannedCustomerIds: json['planned_customer_ids'] != null
          ? List<String>.from(json['planned_customer_ids'] as List)
          : null,
      plannedActivities: json['planned_activities'] as String?,
      notes: json['notes'] as String?,
      status: json['status'] as String,
      submittedAt: json['submitted_at'] != null
          ? DateTime.parse(json['submitted_at'] as String)
          : null,
      reviewedAt: json['reviewed_at'] != null
          ? DateTime.parse(json['reviewed_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

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

  factory WeeklyPlanModel.fromEntity(WeeklyPlanEntity entity) {
    return WeeklyPlanModel(
      id: entity.id,
      officerId: entity.officerId,
      weekStart: entity.weekStart,
      weekEnd: entity.weekEnd,
      plannedCustomerIds: entity.plannedCustomerIds,
      plannedActivities: entity.plannedActivities,
      notes: entity.notes,
      status: entity.status,
      submittedAt: entity.submittedAt,
      reviewedAt: entity.reviewedAt,
      createdAt: entity.createdAt,
    );
  }
}