import 'package:equatable/equatable.dart';
import '../value_objects/weekly_plan_status.dart';

class WeeklyPlanEntity extends Equatable {
  final String id;
  final String officerId;
  final DateTime weekStart;
  final DateTime weekEnd;
  final List<String>? plannedCustomerIds;
  final String? plannedActivities;
  final String? notes;
  final String status;
  final DateTime? submittedAt;
  final DateTime? reviewedAt;
  final DateTime createdAt;

  const WeeklyPlanEntity({
    required this.id,
    required this.officerId,
    required this.weekStart,
    required this.weekEnd,
    this.plannedCustomerIds,
    this.plannedActivities,
    this.notes,
    required this.status,
    this.submittedAt,
    this.reviewedAt,
    required this.createdAt,
  });

  WeeklyPlanEntity copyWith({
    String? id,
    String? officerId,
    DateTime? weekStart,
    DateTime? weekEnd,
    List<String>? plannedCustomerIds,
    String? plannedActivities,
    String? notes,
    String? status,
    DateTime? submittedAt,
    DateTime? reviewedAt,
    DateTime? createdAt,
  }) {
    return WeeklyPlanEntity(
      id: id ?? this.id,
      officerId: officerId ?? this.officerId,
      weekStart: weekStart ?? this.weekStart,
      weekEnd: weekEnd ?? this.weekEnd,
      plannedCustomerIds: plannedCustomerIds ?? this.plannedCustomerIds,
      plannedActivities: plannedActivities ?? this.plannedActivities,
      notes: notes ?? this.notes,
      status: status ?? this.status,
      submittedAt: submittedAt ?? this.submittedAt,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [id, officerId, weekStart, weekEnd, plannedCustomerIds, plannedActivities, notes, status, submittedAt, reviewedAt, createdAt];
}
