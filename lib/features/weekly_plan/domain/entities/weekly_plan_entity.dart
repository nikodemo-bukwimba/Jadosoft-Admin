import 'package:equatable/equatable.dart';

class PlanItemEntity extends Equatable {
  final String? id;
  final String? customerId;
  final String? customerName;
  final String? title;
  final String? objective;
  final DateTime? plannedDate;
  final String? plannedStartTime;
  final String? plannedEndTime;
  final String? notes;
  final String status;

  const PlanItemEntity({
    this.id,
    this.customerId,
    this.customerName,
    this.title,
    this.objective,
    this.plannedDate,
    this.plannedStartTime,
    this.plannedEndTime,
    this.notes,
    this.status = 'planned',
  });

  @override
  List<Object?> get props => [id, customerId, plannedDate];
}

class WeeklyPlanEntity extends Equatable {
  final String id;
  final String officerId;
  final String? officerName;
  final DateTime weekStart;
  final DateTime weekEnd;
  final List<String>? plannedCustomerIds;
  final List<PlanItemEntity> items; // ← ADD
  final String? plannedActivities;
  final String? notes;
  final String status;
  final DateTime? submittedAt;
  final DateTime? reviewedAt;
  final String? reviewNotes;
  final DateTime createdAt;

  const WeeklyPlanEntity({
    required this.id,
    required this.officerId,
    this.officerName,
    required this.weekStart,
    required this.weekEnd,
    this.plannedCustomerIds,
    this.items = const [], // ← ADD
    this.plannedActivities,
    this.notes,
    required this.status,
    this.submittedAt,
    this.reviewedAt,
    this.reviewNotes,
    required this.createdAt,
  });

  WeeklyPlanEntity copyWith({
    String? id,
    String? officerId,
    DateTime? weekStart,
    DateTime? weekEnd,
    List<String>? plannedCustomerIds,
    List<PlanItemEntity>? items,
    String? plannedActivities,
    String? notes,
    String? status,
    DateTime? submittedAt,
    DateTime? reviewedAt,
    String? reviewNotes,
    DateTime? createdAt,
  }) => WeeklyPlanEntity(
    id: id ?? this.id,
    officerId: officerId ?? this.officerId,
    weekStart: weekStart ?? this.weekStart,
    weekEnd: weekEnd ?? this.weekEnd,
    plannedCustomerIds: plannedCustomerIds ?? this.plannedCustomerIds,
    items: items ?? this.items, // ← ADD
    plannedActivities: plannedActivities ?? this.plannedActivities,
    notes: notes ?? this.notes,
    status: status ?? this.status,
    submittedAt: submittedAt ?? this.submittedAt,
    reviewedAt: reviewedAt ?? this.reviewedAt,
    reviewNotes: reviewNotes ?? this.reviewNotes,
    createdAt: createdAt ?? this.createdAt,
  );

  @override
  List<Object?> get props => [
    id,
    officerId,
    weekStart,
    weekEnd,
    status,
    createdAt,
  ];
}
