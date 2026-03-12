import 'package:flutter/material.dart';

enum VisitStatus {
  pending,
  reviewed,
  flagged,
}

extension VisitStatusX on VisitStatus {
  static const Map<VisitStatus, Set<VisitStatus>> _transitions = {
    VisitStatus.pending:  {VisitStatus.reviewed},
    VisitStatus.reviewed: {VisitStatus.flagged},
    VisitStatus.flagged:  {VisitStatus.reviewed},
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