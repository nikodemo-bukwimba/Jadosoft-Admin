import 'package:flutter/material.dart';

enum WeeklyPlanStatus {
  draft,
  submitted,
  approved,
  rejected,
}

extension WeeklyPlanStatusX on WeeklyPlanStatus {
  static const Map<WeeklyPlanStatus, Set<WeeklyPlanStatus>> _transitions = {
    WeeklyPlanStatus.draft:     {WeeklyPlanStatus.submitted},
    WeeklyPlanStatus.submitted: {WeeklyPlanStatus.approved, WeeklyPlanStatus.rejected},
    WeeklyPlanStatus.rejected:  {WeeklyPlanStatus.submitted},
    WeeklyPlanStatus.approved:  {},
  };

  static const WeeklyPlanStatus initial = WeeklyPlanStatus.draft;

  bool canTransitionTo(WeeklyPlanStatus target) =>
      _transitions[this]?.contains(target) ?? false;

  String get displayName => switch (this) {
    WeeklyPlanStatus.draft     => 'Draft',
    WeeklyPlanStatus.submitted => 'Submitted',
    WeeklyPlanStatus.approved  => 'Approved',
    WeeklyPlanStatus.rejected  => 'Rejected',
  };

  Color get color => switch (this) {
    WeeklyPlanStatus.draft     => Colors.grey,
    WeeklyPlanStatus.submitted => Colors.blue,
    WeeklyPlanStatus.approved  => Colors.green,
    WeeklyPlanStatus.rejected  => Colors.red,
  };

  static WeeklyPlanStatus fromString(String? value) =>
      WeeklyPlanStatus.values.firstWhere(
        (e) => e.name == value,
        orElse: () => WeeklyPlanStatus.draft,
      );
}