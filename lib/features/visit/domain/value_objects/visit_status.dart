// lib/features/visit/domain/value_objects/visit_status.dart
//
// CHANGE: expanded _transitions to allow re-decisions:
//   pending  → reviewed          (unchanged)
//   pending  → flagged           (NEW: flag directly from pending)
//   reviewed → flagged           (unchanged)
//   reviewed → reviewed          (NEW: re-review / edit comment)
//   flagged  → reviewed          (unchanged — unflag)
//   flagged  → flagged           (NEW: edit flag reason)
//
// Everything else (displayName, color, fromString) is identical to original.

import 'package:flutter/material.dart';

enum VisitStatus {
  pending,
  reviewed,
  flagged,
}

extension VisitStatusX on VisitStatus {
  static const Map<VisitStatus, Set<VisitStatus>> _transitions = {
    VisitStatus.pending:  {VisitStatus.reviewed, VisitStatus.flagged},
    VisitStatus.reviewed: {VisitStatus.flagged,  VisitStatus.reviewed},
    VisitStatus.flagged:  {VisitStatus.reviewed, VisitStatus.flagged},
  };

  static const VisitStatus initial = VisitStatus.pending;

  bool canTransitionTo(VisitStatus target) =>
      _transitions[this]?.contains(target) ?? false;

  String get displayName => switch (this) {
    VisitStatus.pending  => 'Pending',
    VisitStatus.reviewed => 'Reviewed',
    VisitStatus.flagged  => 'Flagged',
  };

  Color get color => switch (this) {
    VisitStatus.pending  => Colors.orange,
    VisitStatus.reviewed => Colors.green,
    VisitStatus.flagged  => Colors.red,
  };

  static VisitStatus fromString(String? value) =>
      VisitStatus.values.firstWhere(
        (e) => e.name == value,
        orElse: () => VisitStatus.pending,
      );
}