import 'package:flutter/material.dart';

enum DailyReportStatus { draft, submitted, approved, rejected }

extension DailyReportStatusX on DailyReportStatus {
  static const Map<DailyReportStatus, Set<DailyReportStatus>> _transitions = {
    DailyReportStatus.draft: {DailyReportStatus.submitted},
    DailyReportStatus.submitted: {
      DailyReportStatus.approved,
      DailyReportStatus.rejected,
    },
    DailyReportStatus.rejected: {DailyReportStatus.submitted},
    DailyReportStatus.approved: {},
  };

  static const DailyReportStatus initial = DailyReportStatus.draft;

  bool canTransitionTo(DailyReportStatus target) =>
      _transitions[this]?.contains(target) ?? false;

  String get displayName => switch (this) {
    DailyReportStatus.draft => 'Draft',
    DailyReportStatus.submitted => 'Submitted',
    DailyReportStatus.approved => 'Approved',
    DailyReportStatus.rejected => 'Rejected',
  };

  Color get color => switch (this) {
    DailyReportStatus.draft => Colors.grey,
    DailyReportStatus.submitted => Colors.blue,
    DailyReportStatus.approved => Colors.green,
    DailyReportStatus.rejected => Colors.red,
  };

  /// Parse from a raw JSON string, defaulting to draft.
  static DailyReportStatus fromString(String? value) =>
      DailyReportStatus.values.firstWhere(
        (e) => e.name == value,
        orElse: () => DailyReportStatus.draft,
      );
}
