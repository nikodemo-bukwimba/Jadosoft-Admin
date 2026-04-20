import '../../domain/entities/weekly_plan_entity.dart';

class PlanItemModel extends PlanItemEntity {
  const PlanItemModel({
    super.id,
    super.customerId,
    super.customerName,
    super.title,
    super.objective,
    super.plannedDate,
    super.plannedStartTime,
    super.plannedEndTime,
    super.notes,
    super.status,
  });

  factory PlanItemModel.fromJson(Map<String, dynamic> json) => PlanItemModel(
    id: json['id']?.toString(),
    customerId: json['customer_id']?.toString(),
    customerName: json['customer_name'] as String?,
    title: json['title'] as String?,
    objective: json['objective'] as String?,
    plannedDate: json['planned_date'] != null
        ? DateTime.tryParse(json['planned_date'].toString())
        : null,
    plannedStartTime: json['planned_start_time'] as String?,
    plannedEndTime: json['planned_end_time'] as String?,
    notes: json['notes'] as String?,
    status: json['status'] as String? ?? 'planned',
  );
}

class WeeklyPlanModel extends WeeklyPlanEntity {
  const WeeklyPlanModel({
    required super.id,
    required super.officerId,
    super.officerName,
    required super.weekStart,
    required super.weekEnd,
    super.plannedCustomerIds,
    super.items,
    super.plannedActivities,
    super.notes,
    required super.status,
    super.submittedAt,
    super.reviewedAt,
    super.reviewNotes,
    required super.createdAt,
  });

  factory WeeklyPlanModel.fromJson(Map<String, dynamic> json) {
    final rawItems =
        (json['items'] as List?)
            ?.whereType<Map<String, dynamic>>()
            .map(PlanItemModel.fromJson)
            .toList() ??
        [];
    return WeeklyPlanModel(
      id: json['id']?.toString() ?? '',
      officerId:
          json['officer_id']?.toString() ??
          json['officer_actor_id']?.toString() ??
          '',
      officerName: _parseOfficerName(json),
      weekStart: _parseDate(json['week_start_date'] ?? json['week_start']),
      weekEnd: _parseDate(json['week_end_date'] ?? json['week_end']),
      items: rawItems,
      plannedCustomerIds: _parseCustomerIds(json, rawItems),
      plannedActivities:
          json['planned_activities'] as String? ??
          json['objectives'] as String?,
      notes: json['notes'] as String?,
      status: json['status'] as String? ?? 'draft',
      submittedAt: json['submitted_at'] != null
          ? DateTime.parse(json['submitted_at'].toString())
          : null,
      reviewedAt: json['reviewed_at'] != null
          ? DateTime.parse(json['reviewed_at'].toString())
          : null,
      reviewNotes: json['review_notes'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'].toString())
          : DateTime.now(),
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
    'review_notes': reviewNotes,
    'created_at': createdAt.toIso8601String(),
  };

  factory WeeklyPlanModel.fromEntity(WeeklyPlanEntity e) => WeeklyPlanModel(
    id: e.id,
    officerId: e.officerId,
    weekStart: e.weekStart,
    weekEnd: e.weekEnd,
    plannedCustomerIds: e.plannedCustomerIds,
    items: e.items,
    plannedActivities: e.plannedActivities,
    notes: e.notes,
    status: e.status,
    submittedAt: e.submittedAt,
    reviewedAt: e.reviewedAt,
    reviewNotes: e.reviewNotes,
    createdAt: e.createdAt,
  );

  static DateTime _parseDate(dynamic v) =>
      v != null ? DateTime.parse(v.toString()) : DateTime.now();

  static List<String>? _parseCustomerIds(
    Map<String, dynamic> json,
    List<PlanItemEntity> items,
  ) {
    if (items.isNotEmpty) {
      final ids = items.map((e) => e.customerId).whereType<String>().toList();
      if (ids.isNotEmpty) return ids;
    }
    final raw = json['planned_customer_ids'];
    if (raw != null) return List<String>.from(raw as List);
    return null;
  }

  static String? _parseOfficerName(Map<String, dynamic> json) {
    // Try flat field first
    if (json['officer_name'] is String) return json['officer_name'] as String;
    // Try nested officer object
    final officer = json['officer'];
    if (officer is Map) {
      return (officer['display_name'] ?? officer['name'] ?? officer['username'])
          ?.toString();
    }
    // Try nested actor object
    final actor = json['actor'];
    if (actor is Map) {
      return (actor['display_name'] ?? actor['name'])?.toString();
    }
    return null;
  }
}
