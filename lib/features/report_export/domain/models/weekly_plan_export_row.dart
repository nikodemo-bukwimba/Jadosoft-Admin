// lib/features/report_export/domain/models/weekly_plan_export_row.dart
//
// Immutable DTOs built from WeeklyPlanEntity + PlanItemEntity.
// Both PDF and Excel generators consume these exclusively.
// ─────────────────────────────────────────────────────────────────

class PlanItemExportRow {
  final String? customerId;
  final String? customerName;
  final String? title;
  final String? objective;
  final String? plannedDate;
  final String? startTime;
  final String? endTime;
  final String? notes;
  final String status;

  const PlanItemExportRow({
    this.customerId,
    this.customerName,
    this.title,
    this.objective,
    this.plannedDate,
    this.startTime,
    this.endTime,
    this.notes,
    required this.status,
  });
}

class WeeklyPlanExportRow {
  final int no;
  final String id;
  final String officerId;
  final String officerName;   // resolved display name
  final String weekRange;     // "09 Mar – 15 Mar 2026"
  final String weekStart;
  final String weekEnd;
  final String status;
  final String? plannedActivities;
  final String? notes;
  final List<String> plannedCustomerIds;
  final List<PlanItemExportRow> items;
  final String? submittedAt;
  final String? reviewedAt;
  final String? reviewNotes;
  final String createdAt;

  const WeeklyPlanExportRow({
    required this.no,
    required this.id,
    required this.officerId,
    required this.officerName,
    required this.weekRange,
    required this.weekStart,
    required this.weekEnd,
    required this.status,
    this.plannedActivities,
    this.notes,
    required this.plannedCustomerIds,
    required this.items,
    this.submittedAt,
    this.reviewedAt,
    this.reviewNotes,
    required this.createdAt,
  });
}